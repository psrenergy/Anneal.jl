@testset "Annealing Tools" begin
    x = Dict{MOI.VariableIndex, Union{Int, Nothing}}(MOI.VariableIndex(i) => i for i = 1:3)
    Q = Dict{Tuple{Int, Int}, Float64}(
        (1, 1) => 1.0, (1, 2) =>  2.0, (1, 3) => -3.0,
                       (2, 2) => -2.0, (2, 3) =>  2.0,
                                       (3, 3) =>  3.0,
    )
    c = 5.0

    s̄ = Dict{MOI.VariableIndex, Union{Int, Nothing}}(MOI.VariableIndex(i) => i for i = 1:3)
    h̄ = Dict{Int, Float64}(2 => 0.0, 3 => 1.25, 1 => 0.25)
    J̄ = Dict{Tuple{Int, Int}, Float64}(
        (1, 2) => 0.50, (1, 3) => -0.75,
                        (2, 3) =>  0.50,
    )
    c̄ = 6.25

    s, h, J, c = Anneal.ising_normal_form(x, Q, c)

    @test s == s̄
    @test h == h̄
    @test J == J̄
    @test c == c̄
end