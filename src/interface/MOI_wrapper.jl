MOI.supports_constraint(
    ::AbstractSampler,
    ::MOI.AbstractFunction,
    ::MOI.AbstractSet,
) = false

MOI.supports_constraint(
    ::AbstractSampler,
    ::VI,
    ::MOI.ZeroOne,
) = true

MOI.get(sampler::AbstractSampler, ::MOI.RawSolver) = sampler

mutable struct MOIAttributes{T}
    # ~*~ Regular ~*~
    name::String
    silent::Bool
    time_limit_sec::Union{Float64, Nothing}
    raw_attributes::Dict{String, Any}
    number_of_threads::Int
    # ~*~ Extra ~*~
    warm_start::Dict{VI, T}

    function MOIAttributes{T}(;
        name::String = "",
        silent::Bool = false,
        time_limit_sec::Union{Float64, Nothing} = nothing,
        raw_attributes::Dict{String, Any} = Dict{String, Any}(),
        number_of_threads::Integer = Threads.nthreads(),
        warm_start = Dict{VI, T}(),
        ) where T

        new{T}(
            name,
            silent,
            time_limit_sec,
            raw_attributes,
            number_of_threads,
            warm_start,
        )
    end

    function MOIAttributes(; kws...)
        MOIAttributes{Float64}(; kws...)
    end
end

function moi_attrs(::X) where {X <: Anneal.Sampler}
    error("'moi_attrs' is not defined for sampler of type '$X'")
end

function MOI.get(sampler::Anneal.Sampler, ::MOI.Name)
    attrs = Anneal.moi_attrs(sampler)::MOIAttributes

    return attrs.name
end

function MOI.set(sampler::Anneal.Sampler, ::MOI.Name, name::String)
    attrs = Anneal.moi_attrs(sampler)::MOIAttributes

    attrs.name = name

    nothing
end

function MOI.get(sampler::Anneal.Sampler, ::MOI.Silent)
    attrs = Anneal.moi_attrs(sampler)::MOIAttributes

    return attrs.silent
end

function MOI.set(sampler::Anneal.Sampler, ::MOI.Silent, silent::Bool)
    attrs = Anneal.moi_attrs(sampler)::MOIAttributes

    attrs.silent = silent

    nothing
end

function MOI.get(sampler::Anneal.Sampler, ::MOI.TimeLimitSec)
    attrs = Anneal.moi_attrs(sampler)::MOIAttributes

    return attrs.time_limit_sec
end

function MOI.set(sampler::Anneal.Sampler, ::MOI.TimeLimitSec, time_limit_sec::Union{Float64, Nothing})
    attrs = Anneal.moi_attrs(sampler)::MOIAttributes

    attrs.time_limit_sec = time_limit_sec

    nothing
end

function MOI.get(sampler::Anneal.Sampler, attr::MOI.RawOptimizerAttribute)
    attrs = Anneal.moi_attrs(sampler)::MOIAttributes

    return attrs.raw_attributes[attr.name]
end

function MOI.set(sampler::Anneal.Sampler, attr::MOI.RawOptimizerAttribute, value::Any)
    attrs = Anneal.moi_attrs(sampler)::MOIAttributes

    attrs.raw_attributes[attr.name] = value

    nothing
end

function MOI.get(sampler::Anneal.Sampler, ::MOI.NumberOfThreads)
    attrs = Anneal.moi_attrs(sampler)::MOIAttributes

    return attrs.number_of_threads
end

function MOI.set(sampler::Anneal.Sampler, ::MOI.NumberOfThreads, number_of_threads::Integer)
    attrs = Anneal.moi_attrs(sampler)::MOIAttributes

    attrs.number_of_reads = number_of_threads

    nothing
end