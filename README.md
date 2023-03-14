# Concorde.jl


[![Build Status](https://github.com/chkwon/Concorde.jl/workflows/CI/badge.svg?branch=master)](https://github.com/chkwon/Concorde.jl/actions?query=workflow%3ACI)
[![codecov](https://codecov.io/gh/chkwon/Concorde.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/chkwon/Concorde.jl)


A Julia wrapper for the [Concorde](http://www.math.uwaterloo.ca/tsp/concorde.html) TSP Solver.

# License

This Concorde.jl package is in MIT License. However, the underlying Concorde solver is available for free only for academic research as described in the [Concorde](http://www.math.uwaterloo.ca/tsp/concorde.html) website.

# Installation

```julia
] add Concorde
```

Currently, this package works in 64-bit operations systems of Windows 10, macOS, and Ubuntu. 

# Usage

Only symmetric problems are supported. 


## Using a distance matrix

```julia
using Concorde
M = [
     0  16   7  14
    16   0   3   5
     7   3   0  16
    14   5  16   0 
]
opt_tour, opt_len = solve_tsp(M)
```
The distance matrix `M` must be integer-valued.

## Using coordinates

```julia
using Concorde
n_nodes = 10
x = rand(n_nodes) .* 10000
y = rand(n_nodes) .* 10000
opt_tour, opt_len = solve_tsp(x, y; dist="EUC_2D")
```
where `dist` is a choice of the distance function. 

Available `dist` functions are listed in [`TSPLIB_DOC.pdf`](http://webhotel4.ruc.dk/~keld/research/LKH/LKH-2.0/DOC/TSPLIB_DOC.pdf). (Some may have not been implemented in this package.)

## Using an input file 

Using the [TSPLIB format](http://webhotel4.ruc.dk/~keld/research/LKH/LKH-2.0/DOC/TSPLIB_DOC.pdf):
```julia
opt_tour, opt_len = solve_tsp("gr17.tsp")
```

# Related Projects

- [Concorde.jl](https://github.com/chkwon/Concorde.jl): Julia wrapper of the [Concorde TSP Solver](http://www.math.uwaterloo.ca/tsp/concorde/index.html).
- [LKH.jl](https://github.com/chkwon/LKH.jl): Julia wrapper of the [LKH heuristic solver](http://webhotel4.ruc.dk/~keld/research/LKH/).
- [TSPLIB.jl](https://github.com/matago/TSPLIB.jl): Reads [TSPLIB-format](http://webhotel4.ruc.dk/~keld/research/LKH/LKH-2.0/DOC/TSPLIB_DOC.pdf) files (`*.tsp`)
- [TravelingSalesmanExact.jl](https://github.com/ericphanson/TravelingSalesmanExact.jl): Julia implementation of [Dantzig, Fulkerson, and Johnson's Cutting-Plane Method](https://doi.org/10.1287/opre.2.4.393).



