@doc raw"""
    AbstractSampler{T} <: MOI.AbstractOptimizer
""" abstract type AbstractSampler{T} <: MOI.AbstractOptimizer end

@doc raw"""
    sample(::X) where {X<:AbstractSampler}
""" function sample end

function Anneal.sample(::X) where {X<:AbstractSampler}
    error("'Anneal.sample' is not implemented for '$(X)'")
end

@doc raw"""
    sample!(::X) where {X<:AbstractSampler}
""" function sample! end

function Anneal.sample!(::X) where {X<:AbstractSampler}
    error("'Anneal.sample!' is not implemented for '$(X)'")
end