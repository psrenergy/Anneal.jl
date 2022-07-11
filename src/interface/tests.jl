@doc raw"""
""" function test end

function test(Optimizer::Type{<:AbstractSampler})
    Test.@testset "MOI Interface" begin
        Test.@test hasmethod(MOI.get, (Optimizer, MOI.SolverName))
        Test.@test hasmethod(MOI.get, (Optimizer, MOI.SolverVersion)) 
        Test.@test hasmethod(MOI.get, (Optimizer, MOI.RawSolver))
    end

    Test.@testset "Anneal Interface" begin
        Test.@test hasmethod(Anneal.sample, (Optimizer,))
    end
end

macro test(expr)
    expr = macroexpand(__module__, expr)

    quote
        test($(esc(expr)))
    end
end