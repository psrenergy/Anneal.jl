include("interface/moi.jl")
include("interface/anneal.jl")

@doc raw"""
""" function test end

function Anneal.test(optimizer::Type{<:AbstractSampler})
    __test_moi_interface(optimizer)
    __test_anneal_interface(optimizer)
end