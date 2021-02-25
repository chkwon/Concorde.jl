  struct TSP
    name::AbstractString
    dimension::Integer
    weight_type::AbstractString
    weights::Matrix
    nodes::Matrix
    Dnodes::Bool
    ffx::Function
    pfx::Function
    optimal::Float64
  end

  const tsp_keys = ["NAME",
                    "TYPE",
                    "COMMENT",
                    "DIMENSION",
                    "EDGE_WEIGHT_TYPE",
                    "EDGE_WEIGHT_FORMAT",
                    "EDGE_DATA_FORMAT",
                    "NODE_COORD_TYPE",
                    "DISPLAY_DATA_TYPE",
                    "NODE_COORD_SECTION",
                    "DEPOT_SECTION",
                    "DEMAND_SECTION",
                    "EDGE_DATA_SECTION",
                    "FIXED_EDGES_SECTION",
                    "DISPLAY_DATA_SECTION",
                    "TOUR_SECTION",
                    "EDGE_WEIGHT_SECTION",
                    "EOF"]

  function readTSP(path::AbstractString)
    raw = read(path, String)
    checkEOF(raw)
    return _generateTSP(raw)
  end
  
  readTSPLIB(instance::Symbol) = readTSP(joinpath(TSPLIB95_path,string(instance)*".tsp"))
  
  function _generateTSP(raw::AbstractString)
    _dict = keyextract(raw, tsp_keys)
    name = _dict["NAME"]
    dimension = parse(Int,_dict["DIMENSION"])
    weight_type = _dict["EDGE_WEIGHT_TYPE"]
    dxp = false
  
    if weight_type == "EXPLICIT" && haskey(_dict,"EDGE_WEIGHT_SECTION")
      explicits = parse.(Float64, split(_dict["EDGE_WEIGHT_SECTION"]))
      weights = explicit_weights(_dict["EDGE_WEIGHT_FORMAT"],explicits)
      #Push display data to nodes if possible
      if haskey(_dict,"DISPLAY_DATA_SECTION")
        coords = parse.(Float64, split(_dict["DISPLAY_DATA_SECTION"]))
        n_r = convert(Integer,length(coords)/dimension)
        nodes = reshape(coords,(n_r,dimension))'[:,2:end]
        dxp = true
      else
        nodes = zeros(dimension,2)
      end
    elseif haskey(_dict,"NODE_COORD_SECTION")
      coords = parse.(Float64, split(_dict["NODE_COORD_SECTION"]))
      n_r = convert(Integer,length(coords)/dimension)
      nodes = reshape(coords,(n_r,dimension))'[:,2:end]
      weights = calc_weights(_dict["EDGE_WEIGHT_TYPE"],nodes)
    end
  
    fFX = fullFit(weights)
    pFX = partFit(weights)
    optimal = Optimals[Symbol(name)]
  
    TSP(name,dimension,weight_type,weights,nodes,dxp,fFX,pFX,optimal)
  end
  
  function keyextract(raw::T,ks::Array{T}) where T<:AbstractString
    pq = PriorityQueue{T,Tuple{Integer,Integer}}()
    vals = Dict{T,T}()
    for k in ks
      idx = findfirst(k,raw)
      idx != nothing && enqueue!(pq,k,extrema(idx))
    end
    while length(pq) > 1
      s_key, s_pts = peek(pq)
      dequeue!(pq)
      f_key, f_pts = peek(pq)
      rng = (s_pts[2]+1):(f_pts[1]-1)
      vals[s_key] = strip(replace(raw[rng],":"=>""))
    end
    return vals
  end
  
  
  function explicit_weights(key::AbstractString,data::Vector{Float64})
    w = @match key begin
      "UPPER_DIAG_ROW" => vec2UDTbyRow(data)
      "LOWER_DIAG_ROW" => vec2LDTbyRow(data)
      "UPPER_DIAG_COL" => vec2UDTbyCol(data)
      "LOWER_DIAG_COL" => vec2LDTbyCol(data)
      "UPPER_ROW" => vec2UTbyRow(data)
      "FULL_MATRIX" => vec2FMbyRow(data)
    end
    if !in(key,["FULL_MATRIX"])
      w.+=w'
    end
    return w
  end
  
  function calc_weights(key::AbstractString,data::Matrix)
    w = @match key begin
      "EUC_2D" => euclidian(data[:,1], data[:,2])
      "GEO" => geo(data[:,1], data[:,2])
      "ATT" => att_euclidian(data[:,1], data[:,2])
      "CEIL_2D" => ceil_euclidian(data[:,1], data[:,2])
    end
  
    return w
  end
  
  function checkEOF(raw::AbstractString)
    n = findlast("EOF",raw)
    if n == nothing
      throw("EOF not found")
    end
    return
  end


  function vec2LDTbyRow(v::AbstractVector{T}, z::T=zero(T)) where T
    n = length(v)
    s = round(Integer,(sqrt(8n+1)-1)/2)
    s*(s+1)/2 == n || error("vec2LTbyRow: length of vector is not triangular")
    k=0
    [i<=j ? (k+=1; v[k]) : z for i=1:s, j=1:s]'
end

function vec2UDTbyRow(v::AbstractVector{T}, z::T=zero(T)) where T
    n = length(v)
    s = round(Integer,(sqrt(8n+1)-1)/2)
    s*(s+1)/2 == n || error("vec2UTbyRow: length of vector is not triangular")
    k=0
    [i>=j ? (k+=1; v[k]) : z for i=1:s, j=1:s]'
end

function vec2LDTbyCol(v::AbstractVector{T}, z::T=zero(T)) where T
    n = length(v)
    s = round(Integer,(sqrt(8n+1)-1)/2)
    s*(s+1)/2 == n || error("vec2LTbyCol: length of vector is not triangular")
    k=0
    [i>=j ? (k+=1; v[k]) : z for i=1:s, j=1:s]
end

function vec2UDTbyCol(v::AbstractVector{T}, z::T=zero(T)) where T
    n = length(v)
    s = round(Integer,(sqrt(8n+1)-1)/2)
    s*(s+1)/2 == n || error("vec2UTbyCol: length of vector is not triangular")
    k=0
    [i<=j ? (k+=1; v[k]) : z for i=1:s, j=1:s]
end

function vec2UTbyRow(v::AbstractVector{T}, z::T=zero(T)) where T
    n = length(v)
    s = round(Integer,((sqrt(8n+1)-1)/2)+1)
    (s*(s+1)/2)-s == n || error("vec2UTbyRow: length of vector is not triangular")
    k=0
    [i>j ? (k+=1; v[k]) : z for i=1:s, j=1:s]'
end

function vec2FMbyRow(v::AbstractVector{T}, z::T=zero(T)) where T
    n = length(v)
    s = round(Int,sqrt(n))
    s^2 == n || error("vec2FMbyRow: length of vector is not square")
    k=0
    [(k+=1; v[k]) for i=1:s, j=1:s]
end

function findTSP(path::AbstractString)
  if isdir(path)
    syms = [Symbol(split(file,".")[1]) for file in readdir(path) if (split(file,".")[end] == "tsp")]
  else
    error("Not a valid directory")
  end
  return syms
end


#=Generator function for TSP that takes the weight Matrix
and returns a function that evaluates the fitness of a single path=#

    function fullFit(costs::AbstractMatrix{Float64})
        N = size(costs,1)
        function fFit(tour::Vector{T}) where T<:Integer
          @assert length(tour) == N "Tour must be of length $N"
          @assert isperm(tour) "Not a valid tour, not a permutation"
          #distance = weights[from,to] (from,to) in tour
          distance = costs[tour[N],tour[1]]
          for i in 1:N-1
            @inbounds distance += costs[tour[i],tour[i+1]]
          end
          return distance
        end
        return fFit
      end
      
      function partFit(costs::AbstractMatrix{Float64})
        N = size(costs,1)
        function pFit(tour::Vector{T}) where T<:Integer
          n = length(tour)
          #distance = weights[from,to] (from,to) in tour
          distance = n == N ? costs[tour[N],tour[1]] : zero(Float64)
          for i in 1:n-1
            @inbounds distance += costs[tour[i],tour[i+1]]
          end
          return distance
        end
        return pFit
      end

      const Optimals = Dict{Symbol,Float64}(
        [:a280 => 2579,
         :ali535 => 202339,
         :att48 => 10628,
         :att532 => 27686,
         :bayg29 => 1610,
         :bays29 => 2020,
         :berlin52 => 7542,
         :bier127 => 118282,
         :brazil58 => 25395,
         :brd14051 => 469385,
         :brg180 => 1950,
         :burma14 => 3323,
         :ch130 => 6110,
         :ch150 => 6528,
         :d198 => 15780,
         :d493 => 35002,
         :d657 => 48912,
         :d1291 => 50801,
         :d1655 => 62128,
         :d2103 => 80450,
         :d15112 => 1573084,
         :d18512 => 645238,
         :dantzig42 => 699,
         :dsj1000 => 18659688,
         :eil51 => 426,
         :eil76 => 538,
         :eil101 => 629,
         :fl417 => 11861,
         :fl1400 => 20127,
         :fl1577 => 22249,
         :fl3795 => 28772,
         :fnl4461 => 182566,
         :fri26 => 937,
         :gil262 => 2378,
         :gr17 => 2085,
         :gr21 => 2707,
         :gr24 => 1272,
         :gr48 => 5046,
         :gr96 => 55209,
         :gr120 => 6942,
         :gr137 => 69853,
         :gr202 => 40160,
         :gr229 => 134602,
         :gr431 => 171414,
         :gr666 => 294358,
         :hk48 => 11461,
         :kroA100 => 21282,
         :kroB100 => 22141,
         :kroC100 => 20749,
         :kroD100 => 21294,
         :kroE100 => 22068,
         :kroA150 => 26524,
         :kroB150 => 26130,
         :kroA200 => 29368,
         :kroB200 => 29437,
         :lin105 => 14379,
         :lin318 => 42029,
         :linhp318 => 41345,
         :nrw1379 => 56638,
         :p654 => 34643,
         :pa561 => 2763,
         :pcb442 => 50778,
         :pcb1173 => 56892,
         :pcb3038 => 137694,
         :pla7397 => 23260728,
         :pla33810 => 66048945,
         :pla85900 => 142382641,
         :pr76 => 108159,
         :pr107 => 44303,
         :pr124 => 59030,
         :pr136 => 96772,
         :pr144 => 58537,
         :pr152 => 73682,
         :pr226 => 80369,
         :pr264 => 49135,
         :pr299 => 48191,
         :pr439 => 107217,
         :pr1002 => 259045,
         :pr2392 => 378032,
         :rat99 => 1211,
         :rat195 => 2323,
         :rat575 => 6773,
         :rat783 => 8806,
         :rd100 => 7910,
         :rd400 => 15281,
         :rl1304 => 252948,
         :rl1323 => 270199,
         :rl1889 => 316536,
         :rl5915 => 565530,
         :rl5934 => 556045,
         :rl11849 => 923288,
         :si175 => 21407,
         :si535 => 48450,
         :si1032 => 92650,
         :st70 => 675,
         :swiss42 => 1273,
         :ts225 => 126643,
         :tsp225 => 3916,
         :u159 => 42080,
         :u574 => 36905,
         :u724 => 41910,
         :u1060 => 224094,
         :u1432 => 152970,
         :u1817 => 57201,
         :u2152 => 64253,
         :u2319 => 234256,
         :ulysses16 => 6859,
         :ulysses22 => 7013,
         :usa13509 => 19982859,
         :vm1084 => 239297,
         :vm1748 => 336556])