abstract type AbstractSampler{T} <: MOI.AbstractOptimizer end

@doc raw"""
""" function sample end

@doc raw"""
""" function sample! end

abstract type Sampler{T} <: AbstractSampler{T} end

abstract type SamplerAttribute <: MOI.AbstractOptimizerAttribute end