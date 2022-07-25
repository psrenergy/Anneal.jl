include("interface/moi.jl")
include("interface/anneal.jl")

@doc raw"""
""" function test end

function test(S::Type{<:AbstractSampler})
    test_moi_interface(S)
end