abstract type AutomaticSampler{T} <: AbstractSampler{T} end

@doc raw"""
    model_sense(sampler)::Union{Symbol,Nothing}
""" function model_sense end

function Anneal.model_sense(sampler::AutomaticSampler)
    return MOI.get(sampler, MOI.ObjectiveSense())
end

@doc raw"""
    model_domain(sampler)::Union{Symbol,Nothing}
""" function model_domain end

function Anneal.model_domain(sampler::AutomaticSampler)
    return QUBOTools.domain(sampler)
end

@doc raw"""
    solver_sense(sampler)::Union{Symbol,Nothing}
""" function solver_sense end

Anneal.solver_sense(::AutomaticSampler) = nothing

@doc raw"""
    solver_domain(sampler)::Union{Symbol,Nothing}
""" function solver_domain end

Anneal.solver_domain(::AutomaticSampler) = nothing