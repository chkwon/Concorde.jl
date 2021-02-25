
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
    exts = ["mas", "pul", "sav", "sol", "tsp", "res"]
    for ext in exts
        file =  "$(name).$(ext)"
        rm(file, force=true)
        file =  "O$(name).$(ext)"
        rm(file, force=true)
    end
end