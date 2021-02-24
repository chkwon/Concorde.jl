module Concorde

using Random 

include("../deps/deps.jl")
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

function solve_tsp(dist_mtx::Matrix{Int})
    n_nodes = size(dist_mtx, 1)
    name = randstring(10)
    filepath = joinpath(pwd(), name * ".tsp")
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

    run(`$(Concorde.CONCORDE_EXECUTABLE) $(filepath)`)

    sol_filepath = joinpath(pwd(), name * ".sol")
    opt_tour = read_solution(sol_filepath)
    opt_len = tour_length(opt_tour, dist_mtx)
    
    exts = ["mas", "pul", "sav", "sol", "tsp"]
    for ext in exts
        file = joinpath(pwd(), "$(name).$(ext)")
        rm(file, force=true)
        file = joinpath(pwd(), "O$(name).$(ext)")
        rm(file, force=true)
    end
    return opt_tour, opt_len
end




export solve_tsp

end
