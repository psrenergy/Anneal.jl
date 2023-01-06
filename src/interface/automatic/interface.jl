abstract type AutomaticSampler{T} <: AbstractSampler{T} end

@doc raw"""
    model_sense(sampler)::Union{Symbol,Nothing}
""" function model_sense end

Anneal.model_sense(sampler::AutomaticSampler) = QUBOTools.sense(sampler.source)::QUBOTools.Sense

@doc raw"""
    model_domain(sampler)::Union{Symbol,Nothing}
""" function model_domain end

Anneal.model_domain(sampler::AutomaticSampler) = QUBOTools.domain(sampler.source)::QUBOTools.Domain

@doc raw"""
    solver_sense(sampler)::Union{Symbol,Nothing}
""" function solver_sense end

Anneal.solver_sense(::S) where {S<:AutomaticSampler} = error("'solver_sense' not defined for '$S'")

@doc raw"""
    solver_domain(sampler)::Union{Symbol,Nothing}
""" function solver_domain end

Anneal.solver_domain(::S) where {S<:AutomaticSampler} = error("'solver_domain' not defined for '$S'")