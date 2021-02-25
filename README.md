# Concorde.jl


[![Build Status](https://github.com/chkwon/Concorde.jl/workflows/CI/badge.svg?branch=master)](https://github.com/chkwon/Concorde.jl/actions?query=workflow%3ACI)
[![codecov](https://codecov.io/gh/chkwon/Concorde.jl/branch/master/graph/badge.svg)](https://codecov.io/gh/chkwon/Concorde.jl)


A Julia wrapper for the [Concorde](http://www.math.uwaterloo.ca/tsp/concorde.html) TSP Solver.

# License

This Concorde.jl package is in MIT License. However, the underlying Concorde solver is available for free only for academic research as desribed in the [Concorde](http://www.math.uwaterloo.ca/tsp/concorde.html) website.

# Installation

```julia
] add https://github.com/chkwon/Concorde.jl
```

Currently, this package works in 64-bit operations systmes of Windows 10, macOS, and Ubuntu. 

# Usage

Currently, only support symmetric problems. 

```julia
M = [
     0  16   7  14
    16   0   3   5
     7   3   0  16
    14   5  16   0 
]
opt_tour, opt_len = solve_tsp(M)
```

The distance matrix `M` must be integer-valued.
