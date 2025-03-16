import Libdl


const QSOPT_LOCATION = Dict(
    "Darwin" => [
        "https://www.math.uwaterloo.ca/~bico/qsopt/beta/codes/mac64/qsopt.a",
        "https://www.math.uwaterloo.ca/~bico/qsopt/beta/codes/mac64/qsopt.h"
    ],
    "DarwinM1" => [
        "https://www.math.uwaterloo.ca/~bico/qsopt/downloads/codes/m1/qsopt.a",
        "https://www.math.uwaterloo.ca/~bico/qsopt/downloads/codes/m1/qsopt.h"
    ],
    "Linux" => [
        "http://www.math.uwaterloo.ca/~bico/qsopt/beta/codes/PIC/qsopt.PIC.a",
        "http://www.math.uwaterloo.ca/~bico/qsopt/beta/codes/PIC/qsopt.h"
    ]
)

const CONCORDE_SRC = "http://www.math.uwaterloo.ca/tsp/concorde/downloads/codes/src/co031219.tgz" 


const CONCORDE_WIN_EXE_URL = "http://www.math.uwaterloo.ca/tsp/concorde/downloads/codes/cygwin/concorde.exe.gz"


if Sys.iswindows()
    if isdefined(Base, :LIBEXECDIR)
        const exe7z = joinpath(Sys.BINDIR, Base.LIBEXECDIR, "7z.exe")
    else
        const exe7z = joinpath(Sys.BINDIR, "7z.exe")
    end

    function unpack_cmd(file, directory, extension, secondary_extension)
        if ((extension == ".Z" || extension == ".gz" || extension == ".xz" || extension == ".bz2") &&
                secondary_extension == ".tar") || extension == ".tgz" || extension == ".tbz"
            return pipeline(`$exe7z x $file -y -so`, `$exe7z x -si -y -ttar -o$directory`)
        elseif (extension == ".zip" || extension == ".7z" || extension == ".tar" ||
                (extension == ".exe" && secondary_extension == ".7z"))
            return (`$exe7z x $file -y -o$directory`)
        end
        error("I don't know how to unpack $file")
    end
end


function _download_concorde_win()
    win_dir = joinpath(@__DIR__, "win_dir")

    if isdir(win_dir)
        rm(win_dir, recursive=true, force=true)
    end
    mkdir(win_dir)

    concorde_tarball = joinpath(win_dir, "concorde.exe.gz")
    download(CONCORDE_WIN_EXE_URL, concorde_tarball)
    run(`$exe7z x $(concorde_tarball) -y -o$(win_dir)`)
    concorde_exe = joinpath(win_dir, "concorde.exe")

    cygwin_tarball = joinpath(@__DIR__, "cygwin32-2.10.0-1.tar.xz")
    try
        run(unpack_cmd(cygwin_tarball, win_dir, ".xz", ".tar"))
    catch e
        # This will throw a LoadError, but ignore it. We just need cygwin1.dll file.
    end

    cygwin1_dll_downloaded = joinpath(win_dir, "usr", "i686-pc-cygwin", "sys-root", "usr", "bin", "cygwin1.dll")
    @show isfile(cygwin1_dll_downloaded)
    cygwin1_dll = joinpath(win_dir, "cygwin1.dll")
    cp(cygwin1_dll_downloaded, cygwin1_dll, force=true)

    return concorde_exe
end

function _build_concorde()
    # Download qsopt
    qsopt_dir = joinpath(@__DIR__, "qsopt")
    if !isdir(qsopt_dir)
        mkdir(qsopt_dir)
    end
    
    sys_type = "Linux"
    if Sys.isapple() 
        if Sys.ARCH == :x86_64
            sys_type = "Darwin"
        elseif Sys.ARCH == :aarch64
            sys_type = "DarwinM1"
        else
            error("Unsupported Processor: ", Sys.ARCH)
        end
    else
        sys_type = "Linux"
    end

    download(QSOPT_LOCATION[sys_type][1], joinpath(qsopt_dir, "qsopt.a"))
    download(QSOPT_LOCATION[sys_type][2], joinpath(qsopt_dir, "qsopt.h"))

    # Download concorde
    concorde_tarball = download(CONCORDE_SRC)
    run(`tar zxvf $(concorde_tarball)`)

    # Build 
    concorde_src_dir = joinpath(@__DIR__, "concorde")
    cd(concorde_src_dir)
    
    macflag = Sys.isapple() ? "--host=darwin" : ""
    cflags = "-std=gnu89 -fPIC -O2 -g"
    run(`bash -c "CFLAGS='$(cflags)' ./configure --with-qsopt=$(qsopt_dir) $(macflag)"`)
    run(`make clean`)
    run(`make`)
    lib_dir = joinpath(@__DIR__, "lib")
    if !isdir(lib_dir)
        mkdir(lib_dir)
    end
    executable = joinpath(concorde_src_dir, "TSP", "concorde")
    
    return executable

end

function build_concorde()
    if Sys.islinux() && Sys.ARCH == :x86_64
        return _build_concorde()
    elseif Sys.isapple()
        return _build_concorde()
    elseif Sys.iswindows()
        return _download_concorde_win()
    end
    error(
        "Unsupported operating system. Only 64-bit linux and macOS " *
        "are supported."
    )
    return nothing
end

function install_concorde()
    executable = get(ENV, "CONCORDE_EXECUTABLE", nothing)
    if !haskey(ENV, "CONCORDE_EXECUTABLE")
        executable = build_concorde()
        ENV["CONCORDE_EXECUTABLE"] = executable
    end

    if executable === nothing
        error("Environment variable `CONCORDE_EXECUTABLE` not found.")
    end

    open(joinpath(@__DIR__, "deps.jl"), "w") do io
        write(io, "const CONCORDE_EXECUTABLE = \"$(escape_string(executable))\"\n")
    end
end

install_concorde()