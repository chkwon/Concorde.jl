module Concorde

using Random, LinearAlgebra
using TSPLIB


include("../deps/deps.jl")
include("dist.jl")
include("util.jl")
include("solver.jl")


export solve_tsp

end
