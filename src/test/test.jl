# -*- Interface Tests -*- #
include("interface/moi.jl")
include("interface/anneal.jl")

# -*- Example Tests -*- #
include("examples/basic.jl")

@doc raw"""
    test(optimizer::Type{S}; examples::Bool=false) where {S<:AbstractSampler}
    test(config!::Function, optimizer::Type{S}; examples::Bool=false) where {S<:AbstractSampler}
""" function test end

function Anneal.test(::Type{S}; examples::Bool=false) where {S<:AbstractSampler}
    Anneal.test(identity, S; examples = examples)

    return nothing
end

function Anneal.test(config!::Function, ::Type{S}; examples::Bool=false) where {S<:AbstractSampler}
    solver_name = MOI.get(S(), MOI.SolverName())

    Test.@testset "☢ Anneal Tests for $(solver_name) ☢" verbose = true begin
        Test.@testset "→ Interface" verbose = true begin
            __test_moi_interface(config!, S)
            __test_anneal_interface(config!, S)
        end

        if examples
            Test.@testset "→ Examples" verbose = true begin
                __test_basic_examples(config!, S)
            end
        end
    end

    return nothing
end