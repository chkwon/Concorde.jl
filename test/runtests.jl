using Concorde
using Test

@testset "Concorde.jl" begin
    @testset "Symmetric TSP" begin
        M = [
             0  16   7  14
            16   0   3   5
             7   3   0  16
            14   5  16   0 
        ]
        opt_tour, opt_len = solve_tsp(M)
        @show opt_tour, opt_len
        @test opt_len == 29
    end

    @testset "Asymmetric TSP" begin
        M = [
             0   1   7  14
            16   0   1   5
             7   5   0   1
             1   3  16   0 
        ]
        @test_throws ErrorException solve_tsp(M)
    end

    @testset "Coordinates" begin
        n_nodes = 10
        x = rand(n_nodes) .* 10000
        y = rand(n_nodes) .* 10000
        opt_tour, opt_len = solve_tsp(x, y; dist="EUC_2D")
        opt_tour, opt_len = solve_tsp(x, y; dist="MAN_2D")
        opt_tour, opt_len = solve_tsp(x, y; dist="MAX_2D")
        opt_tour, opt_len = solve_tsp(x, y; dist="GEO")        
    end

    @testset "Input File" begin
        opt_tour, opt_len = solve_tsp("gr17.tsp")
        @test opt_len == 2085
    end    
end
