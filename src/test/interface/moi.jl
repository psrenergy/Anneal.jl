function test_moi_interface(S::Type{<:AbstractSampler})
    Test.@testset "MOI Interface" begin
    # ~*~ Emptiness ~*~ #
    Test.@test hasmethod(MOI.empty!, (S,))
    Test.@test hasmethod(MOI.is_empty, (S,))
    # ~*~ Copy-To ~*~ #
    Test.@test hasmethod(MOI.copy_to, (S, MOI.ModelLike))
    # ~*~ Optimize! ~*~ #
    Test.@test hasmethod(MOI.optimize!, (S,)) || hasmethod(MOI.optimize!, (S, MOI.ModelLike))

    Test.@testset "Attributes" begin
        # ~*~ Basic Attributes ~*~ #
        Test.@test hasmethod(MOI.get, (S, MOI.SolverName))
        Test.@test hasmethod(MOI.get, (S, MOI.SolverVersion)) 
        Test.@test hasmethod(MOI.get, (S, MOI.RawSolver))
    end
    end
end