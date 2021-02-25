module Concorde

using Random, LinearAlgebra

include("../deps/deps.jl")
include("dist.jl")
# Write your package code here.

function read_solution(filepath)
    sol = readlines(filepath)
    n_nodes = sol[1]
    tour = parse.(Int, split(join(sol[2:end]))) .+ 1
    return tour
end

function tour_length(tour, M)
    n_nodes = length(tour)
    len = 0
    for i in 1:n_nodes
        j = i + 1
        if i == n_nodes
            j = 1
        end

        len += M[tour[i], tour[j]]
    end
    return len
end


function cleanup(name)
    exts = ["mas", "pul", "sav", "sol", "tsp"]
    for ext in exts
        file =  "$(name).$(ext)"
        rm(file, force=true)
        file =  "O$(name).$(ext)"
        rm(file, force=true)
    end
end

function solve_tsp(dist_mtx::Matrix{Int})
    if !issymmetric(dist_mtx)
        error("Asymmetric TSP is not supported.")
    end

    n_nodes = size(dist_mtx, 1)
    name = randstring(10)
    filepath = name * ".tsp"
    lower_diag_row = Int[]
    for i in 1:n_nodes
        for j in 1:i
            push!(lower_diag_row, dist_mtx[i, j])
        end
    end
    buf = 10
    n_rows = length(lower_diag_row) / buf |> ceil |> Int
    rows = String[]
    for i in 1:n_rows
        s = buf * (i-1) + 1
        t = min(buf * i, length(lower_diag_row))
        push!(rows, join(lower_diag_row[s:t], " "))
    end

    open(filepath, "w") do io
        write(io, "NAME: $(name)\n")
        write(io, "TYPE: TSP\n")
        write(io, "COMMENT: $(name)\n")
        write(io, "DIMENSION: $(n_nodes)\n")
        write(io, "EDGE_WEIGHT_TYPE: EXPLICIT\n")
        write(io, "EDGE_WEIGHT_FORMAT: LOWER_DIAG_ROW \n")
        write(io, "EDGE_WEIGHT_SECTION\n")
        for r in rows
            write(io, "$r\n")
        end
        write(io, "EOF\n")
    end

    status = run(`$(Concorde.CONCORDE_EXECUTABLE) $(filepath)`, wait=false)
    while !success(status)
        # 
    end

    sol_filepath =  name * ".sol"
    opt_tour = read_solution(sol_filepath)
    opt_len = tour_length(opt_tour, dist_mtx)
    
    cleanup(name)

    return opt_tour, opt_len
end


function solve_tsp(x::Vector{Float64}, y::Vector{Float64}; dist="EUC_2D")
    n_nodes = length(x)
    @assert length(x) == length(y)

    name = randstring(10)
    filepath = name * ".tsp"

    open(filepath, "w") do io
        write(io, "NAME: $(name)\n")
        write(io, "TYPE: TSP\n")
        write(io, "COMMENT: $(name)\n")
        write(io, "DIMENSION: $(n_nodes)\n")
        write(io, "EDGE_WEIGHT_TYPE: $(dist)\n")
        write(io, "EDGE_WEIGHT_FORMAT: FUNCTION \n")
        write(io, "NODE_COORD_TYPE: TWOD_COORDS \n")
        write(io, "NODE_COORD_SECTION\n")
        for i in 1:n_nodes
            write(io, "$i $(x[i]) $(y[i])\n")
        end
        write(io, "EOF\n")
    end

    status = run(`$(Concorde.CONCORDE_EXECUTABLE) $(filepath)`, wait=false)
    while !success(status)
        # 
    end

    sol_filepath =  name * ".sol"
    opt_tour = read_solution(sol_filepath)
    opt_len = tour_length(opt_tour, dist_matrix(x, y, dist=dist))
    
    cleanup(name)

    return opt_tour, opt_len
end

function solve_tsp(tsp_file::String)
    if !isfile(tsp_file)
        error("$(tsp_file) is not a file.")
    end

    name = randstring(10)
    filepath = name * ".tsp"
    cp(tsp_file, filepath)

    io = IOBuffer()
    status = run(pipeline(`$(Concorde.CONCORDE_EXECUTABLE) $(filepath)`, stdout = io), wait=false,)
    while !success(status)
        # 
    end
    out = String(take!(io))
    output = split(out, "\n")
    obj_val_msg = split(output[end-3])
    @assert obj_val_msg[1] == "Optimal"
    @assert obj_val_msg[2] == "Solution:"
    val = parse(Float64, obj_val_msg[3]) 
    opt_len = round(Int, val)

    sol_filepath =  name * ".sol"
    opt_tour = read_solution(sol_filepath)

    cleanup(name)

    return opt_tour, opt_len
end


export solve_tsp

end
