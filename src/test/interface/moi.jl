function __test_moi_interface(optimizer::Type{<:AbstractSampler})
    Test.@testset "MOI" verbose = true begin
        # ~*~ Emptiness ~*~ #
        Test.@test hasmethod(MOI.empty!, (optimizer,))
        Test.@test hasmethod(MOI.is_empty, (optimizer,))
        # ~*~ Copy-To ~*~ #
        Test.@test hasmethod(MOI.copy_to, (optimizer, MOI.ModelLike))
        # ~*~ Optimize! ~*~ #
        Test.@test hasmethod(MOI.optimize!, (optimizer,)) || hasmethod(MOI.optimize!, (optimizer, MOI.ModelLike))

        Test.@testset "Attributes" begin
            # ~*~ Basic Attributes ~*~ #
            Test.@test hasmethod(MOI.get, (optimizer, MOI.SolverName))
            Test.@test hasmethod(MOI.get, (optimizer, MOI.SolverVersion))
            Test.@test hasmethod(MOI.get, (optimizer, MOI.RawSolver))
        end
    end
end