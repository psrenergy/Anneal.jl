@doc raw"""
""" abstract type Sampler{T} <: AbstractSampler{T} end

function sample(::Sampler) end

function sample!(sampler::Sampler)
    results = @timed Anneal.sample(sampler)

    data = results[:value]
end