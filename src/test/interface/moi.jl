function __test_moi_interface(::Function, ::Type{S}) where {S<:AbstractSampler}
    Test.@testset "MOI" verbose = true begin
        Test.@testset "`optimize!` Interface" begin
            # ~*~ Emptiness ~*~ #
            Test.@test hasmethod(MOI.empty!, (S,))
            Test.@test hasmethod(MOI.is_empty, (S,))
            # ~*~ Copy-To ~*~ #
            Test.@test hasmethod(MOI.copy_to, (S, MOI.ModelLike))
            # ~*~ Optimize! ~*~ #
            Test.@test hasmethod(MOI.optimize!, (S,)) || hasmethod(MOI.optimize!, (S, MOI.ModelLike))
        end

        Test.@testset "Attributes" begin
            # ~*~ Basic Attributes ~*~ #
            Test.@test hasmethod(MOI.get, (S, MOI.SolverName))
            Test.@test hasmethod(MOI.get, (S, MOI.SolverVersion))
            Test.@test hasmethod(MOI.get, (S, MOI.RawSolver))
        end
    end
end