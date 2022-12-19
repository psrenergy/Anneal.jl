# -*- Interface Tests -*- #
include("interface/moi.jl")
include("interface/anneal.jl")

# -*- Example Tests -*- #
include("examples/basic.jl")

@doc raw"""
    test(optimizer::Type{S}; examples::Bool=false) where {S<:AbstractSampler}
""" function test end

@doc raw"""
    test_config!(::Type{S}, model::JuMP.Model) where {S<:AbstractSampler}
    test_config!(::Type{S}, model::MOI.ModelLike) where {S<:AbstractSampler}
""" function test_config! end

function Anneal.test_config!(::Type{<:AbstractSampler}, ::JuMP.Model) end
function Anneal.test_config!(::Type{<:AbstractSampler}, ::MOI.ModelLike) end

function Anneal.test(optimizer::Type{S}; examples::Bool=false) where {S<:AbstractSampler}
    solver_name = MOI.get(optimizer(), MOI.SolverName())

    Test.@testset "☢ Anneal Tests for $(solver_name) ☢" verbose = true begin
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