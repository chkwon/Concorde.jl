using Concorde
using Test

# @testset "Concorde.jl" begin
#     A = Cint.([4, 2, 5, 7, 2, 1, 3, 5])
#     ccall((:CCutil_int_array_quicksort, Concorde.LIB_CONCORDE), Cvoid, (Ref{Cint}, Cint), A, length(A))
#     @test A[1] == minimum(A)
#     @test A[end] == maximum(A)
# end


@testset "Concorde.jl" begin
    M = [
         0  16   7  14
        16   0   3   5
         7   3   0  16
        14   5  16   0 
    ]
    opt_tour, opt_len = solve_tsp(M)
    @test opt_len == 29
end
