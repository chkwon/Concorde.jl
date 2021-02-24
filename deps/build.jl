import Libdl

const QSOPT_LOCATION = Dict(
    "Darwin" => [
        "https://www.math.uwaterloo.ca/~bico/qsopt/beta/codes/mac64/qsopt.a",
        "https://www.math.uwaterloo.ca/~bico/qsopt/beta/codes/mac64/qsopt.h"
    ],
    "Linux" => [
        "http://www.math.uwaterloo.ca/~bico/qsopt/beta/codes/PIC/qsopt.PIC.a",
        "http://www.math.uwaterloo.ca/~bico/qsopt/beta/codes/PIC/qsopt.h"
    ]
)

const CONCORDE_SRC = "http://www.math.uwaterloo.ca/tsp/concorde/downloads/codes/src/co031219.tgz" 


function _prefix_suffix(str)
    if Sys.islinux() &&  Sys.ARCH == :x86_64
        return "lib$(str).so"
    elseif Sys.isapple()
        return "lib$(str).dylib"
    end 
    # elseif Sys.iswindows()
    #     return "$(str).dll"
    # end
    error(
        "Unsupported operating system. Only 64-bit linux and macOS " *
        "are supported."
    )
end

function build_concorde_linux()
    # Download qsopt
    qsopt_dir = joinpath(@__DIR__, "qsopt")
    if !isdir(qsopt_dir)
        mkdir(qsopt_dir)
    end
    download(QSOPT_LOCATION["Linux"][1], joinpath(qsopt_dir, "qsopt.a"))
    download(QSOPT_LOCATION["Linux"][2], joinpath(qsopt_dir, "qsopt.h"))

    # Download concorde
    concorde_tarball = download(CONCORDE_SRC)
    run(`tar zxvf $(concorde_tarball)`)

    # Build 
    concorde_src_dir = joinpath(@__DIR__, "concorde")
    cd(concorde_src_dir)
    run(`bash -c "CFLAGS='-fPIC -O2 -g' ./configure --with-qsopt=$(qsopt_dir)"`)
    run(`make clean`)
    run(`make`)
    lib_dir = joinpath(@__DIR__, "lib")
    if !isdir(lib_dir)
        mkdir(lib_dir)
    end

    # Build a shared library
    for ext in ["a", "h"]
        cp("concorde.$ext", joinpath(lib_dir, "concorde.$ext"), force=true)
    end
    cd(lib_dir)
    run(`ar -x concorde.a`)
    object_files = String[]
    for f in readdir()
        if f != "concorde.a" && f != "concorde.h"
            push!(object_files, f)
        end
    end
    of = join(object_files, " ")

    run(`bash -c "gcc -shared *.o -o libconcorde.so"`)
    run(`bash -c "rm -rf *.o"`)
    
    cd(@__DIR__)
    return joinpath(lib_dir, "libconcorde.so")
end

function build_concorde()
    if Sys.islinux() &&  Sys.ARCH == :x86_64
        return build_concorde_linux()
    elseif Sys.isapple()
        return nothing
        return build_concorde_linux()
    end 
    # elseif Sys.iswindows()
    #     return "$(str).dll"
    # end
    error(
        "Unsupported operating system. Only 64-bit linux and macOS " *
        "are supported."
    )
    return nothing
end

function install_concorde()
    concorde_lib_filename = get(ENV, "CONCORDE_JL_LOCATION", nothing)
    if !haskey(ENV, "CONCORDE_JL_LOCATION")
        concorde_lib_filename = build_concorde()
        ENV["CONCORDE_JL_LOCATION"] = concorde_lib_filename
    end

    if concorde_lib_filename === nothing
        error("Environment variable `CONCORDE_JL_LOCATION` not found.")
    elseif Libdl.dlopen(concorde_lib_filename) == C_NULL
        error("Unable to open the concorde library $(concorde_lib_filename).")
    end

    open(joinpath(@__DIR__, "deps.jl"), "w") do io
        write(io, "const LIB_CONCORDE = \"$(escape_string(concorde_lib_filename))\"\n")
    end
end

install_concorde()