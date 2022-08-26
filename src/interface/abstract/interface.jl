@doc raw"""
""" abstract type AbstractSampler{T} <: MOI.AbstractOptimizer end

@doc raw"""
""" function sample end

function sample(::AbstractSampler) end

@doc raw"""
""" function sample! end

function sample!(::AbstractSampler) end