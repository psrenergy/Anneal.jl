# -*- Interface Tests -*- #
include("interface/moi.jl")
include("interface/anneal.jl")

# -*- Example Tests -*- #
include("examples/basic.jl")

@doc raw"""
""" function test end

@doc raw"""
""" function test_config! end

function Anneal.test(optimizer::Type{<:AbstractSampler}; examples::Bool=false)
    Test.@testset "-*- Interface" verbose = true begin
        __test_moi_interface(optimizer)
        __test_anneal_interface(optimizer)
    end

    if examples
        Test.@testset "-*- Examples" verbose = true begin
            __test_basic_examples(optimizer)
        end
    end
end