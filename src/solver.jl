#=
# Roy Jonker, Ton Volgenant. Transforming asymmetric into symmetric traveling salesman problems
# (https://doi.org/10.1016/0167-6377(83)90048-2)
=#
function convert_atsp_to_tsp(dist_mtx::Matrix{Int})

    n_nodes = size(dist_mtx, 1)

    # infinity constant
    U::Int = sum(filter(x::Int -> x > 0, dist_mtx)) + 1

    # negative constant
    M::Int = U

    # symmetric matrix
    sym_dist_mtx::Matrix{Int} = fill(U, (2 * n_nodes, 2 * n_nodes))

    # fill
    for i::Int in 1:n_nodes
        for j::Int in 1:n_nodes
            value::Int = i == j ? - M : dist_mtx[i, j]

            sym_dist_mtx[j, n_nodes + i] = value
            sym_dist_mtx[n_nodes + i, j] = value
        end
    end

    return sym_dist_mtx, M
end

function solve_tsp(dist_mtx::Matrix{Int})
    
    is_sym_mtx = issymmetric(dist_mtx)

    # asymmetric case
    if ! is_sym_mtx
#        error("Asymmetric TSP is not supported.")
        dist_mtx, M::Int = convert_atsp_to_tsp(dist_mtx)
    end

    n_nodes = size(dist_mtx, 1)

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

    name = randstring(10) :: String
    filename = name * ".tsp"
    open(filename, "w") do io
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

    opt_tour, opt_len = __solve_tsp__(filename)

    # asymmetric case
    if ! is_sym_mtx
        opt_tour = opt_tour[isodd.(eachindex(opt_tour))]
        opt_len = Int(opt_len + M * n_nodes / 2)
    end

    return opt_tour, opt_len
end


function solve_tsp(x::Vector{Float64}, y::Vector{Float64}; dist="EUC_2D")
    n_nodes = length(x)
    @assert length(x) == length(y)

    name = randstring(10) :: String
    filename = name * ".tsp"

    open(filename, "w") do io
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

    return __solve_tsp__(filename)
end

function solve_tsp(org_tsp_file::String)
    if !isfile(org_tsp_file)
        error("$(org_tsp_file) is not a file.")
    end

    name = randstring(10)
    filename = name * ".tsp"
    cp(org_tsp_file, filename)

    return __solve_tsp__(filename)
end


function __solve_tsp__(tsp_file::String)
    exe = CONCORDE_EXECUTABLE :: String
    status = run(`$(exe) $(tsp_file)`, wait=false)
    while !success(status)
        # 
    end    

    name = splitext(basename(tsp_file))[1] :: String
    sol_filepath =  name * ".sol"
    opt_tour = read_solution(sol_filepath) :: Vector{Int}
    
    tsp = readTSP(tsp_file) :: TSPLIB.TSP
    M = Int.(tsp.weights) :: Matrix{Int}
    opt_len = tour_length(opt_tour, M) :: Int

    cleanup(name)

    return opt_tour, opt_len    
end
