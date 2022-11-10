# -*- Interface Tests -*- #
include("interface/moi.jl")
include("interface/anneal.jl")

# -*- Example Tests -*- #
include("examples/basic.jl")

@doc raw"""
    test(optimizer::Type{S}; examples::Bool=false) where {S<:AbstractSampler}
""" function test end

function Anneal.test(optimizer::Type{S}; examples::Bool=false) where {S<:AbstractSampler}
    solver_name = MOI.get(optimizer(), MOI.SolverName())

    Test.@testset "~*~ Anneal Tests for $(solver_name) ~*~" verbose = true begin
        Test.@testset "→ Interface" verbose = true begin
            __test_moi_interface(optimizer)
            __test_anneal_interface(optimizer)
        end

        if examples
            Test.@testset "→ Examples" verbose = true begin
                __test_basic_examples(optimizer)
            end
        end
    end
end