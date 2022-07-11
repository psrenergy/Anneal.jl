abstract type AbstractSampler{T} <: MOI.AbstractOptimizer end

@doc raw"""
""" function sample end

@doc raw"""
""" function sample! end

function sample!(sampler::AbstractSampler{T}) where {T}
    sampleset = sample(sampler)::BQPIO.SampleSet{<:Integer, T}

    nothing
end