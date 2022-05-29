abstract type AbstractSampler{T} <: MOI.AbstractOptimizer end

const SamplerResults = Vector{Tuple{Vector{<:Integer},Integer,Float64}}

function sample(::AbstractSampler) end

function sample!(sampler::AbstractSampler{T}) where {T}
    result, δt = sample(sampler)::Tuple{SamplerResults,Float64}

    sample_set = SampleSet{Int,T}([Sample{Int,T}(sample...) for sample in result])

    merge!(sampler.sample_set, sample_set)

    if sampler.moi.solve_time_sec === NaN
        sampler.moi.solve_time_sec = δt
    else
        sampler.moi.solve_time_sec += δt
    end

    nothing
end

function energy(sampler::AbstractSampler, s::Vector{Int})
    return sum(s[i] * s[j] * Qᵢⱼ for ((i, j), Qᵢⱼ) in sampler.Q; init=sampler.c)
end

# -*- :: Attributes :: -*-
abstract type AbstractSamplerAttribute <: MOI.AbstractOptimizerAttribute end

mutable struct SamplerAttributes
    opt_attr::Dict{Any,Any}
    opt_type::Dict{Any,Type}
    raw_attr::Dict{String,Any}
    raw_type::Dict{String,Type}
    fallback::Dict{Any,String}
    defaults::Vector{Dict{Symbol,Any}}

    function SamplerAttributes(defaults::Vector{Dict{Symbol,Any}})
        empty!(
            new(
                Dict{Any,Any}(),
                Dict{Any,Type}(),
                Dict{String,Any}(),
                Dict{String,Type}(),
                Dict{Any,String}(),
                defaults,
            )
        )
    end
end

function Base.empty!(attrs::SamplerAttributes)
    empty!(attrs.opt_attr)
    empty!(attrs.raw_attr)
    empty!(attrs.fallback)

    for attr in attrs.defaults
        if !isnothing(attr[:attr]) && !isnothing(attr[:raw]) # Complete interface
            # Set fallback
            attrs.fallback[attr[:attr]()] = attr[:raw]

            # Add raw attribute
            attrs.raw_attr[attr[:raw]] = attr[:init]

            # Add raw type
            attrs.raw_type[attr[:raw]] = attr[:type]
        elseif !isnothing(attr[:raw]) # Purely raw attribute
            # Add raw attribute
            attrs.raw_attr[attr[:raw]] = attr[:init]

            # Add raw type
            attrs.raw_type[attr[:raw]] = attr[:type]
        elseif !isnothing(attr[:attr]) # Optimizer attribute
            # Add optimizer attribute
            attrs.opt_attr[attr[:attr]()] = attr[:init]

            # Add optimizer type
            attrs.opt_type[attr[:attr]()] = attr[:type]
        else
            error("Invalid sampler attribute settings")
        end
    end

    attrs # important!
end

function Base.getindex(attrs::SamplerAttributes, raw_attr::String)
    if haskey(attrs.raw_attr, raw_attr)
        attrs.raw_attr[raw_attr]
    else
        error("No attribute $attr")
    end
end

function Base.getindex(attrs::SamplerAttributes, attr::AbstractSamplerAttribute)
    if haskey(attrs.fallback, attr)
        attrs[attrs.fallback[attr]]
    elseif haskey(attrs.opt_attr, attr)
        attrs.opt_attr[attr]
    else
        error("No attribute $attr")
    end
end

function Base.setindex!(attrs::SamplerAttributes, value::Any, raw_attr::String)
    if haskey(attrs.raw_attr, raw_attr)
        attrs.raw_attr[raw_attr] = convert(attrs.raw_type[raw_attr], value)
    else
        error("No attribute $attr")
    end
end

function Base.setindex!(attrs::SamplerAttributes, value::Any, attr::AbstractSamplerAttribute)
    if haskey(attrs.fallback, attr)
        attrs[attrs.fallback[attr]] = value
    elseif haskey(attrs.opt_attr, attr)
        attrs.opt_attr[attr] = convert(attrs.opt_type[attr], value)
    else
        error("No attribute $attr")
    end
end

Base.@kwdef mutable struct SamplerMOI{T}
    name::String = ""
    silent::Bool = false
    time_limit_sec::Maybe{Float64} = nothing
    number_of_threads::Int = Threads.nthreads()

    solve_time_sec::Float64 = NaN
    termination_status::MOI.TerminationStatusCode = MOI.OPTIMIZE_NOT_CALLED
    primal_status::MOI.ResultStatusCode = MOI.NO_SOLUTION
    dual_status::MOI.ResultStatusCode = MOI.NO_SOLUTION
    raw_status_string::String = ""

    variable_primal_start::Dict{MOI.VariableIndex,T} = Dict{MOI.VariableIndex,T}()

    objective_sense::MOI.OptimizationSense = MOI.MIN_SENSE
end

function Base.empty!(moi::SamplerMOI{T}) where {T}
    moi.name               = ""
    moi.silent             = false
    moi.time_limit_sec     = nothing
    moi.number_of_threads  = Threads.nthreads()

    moi.solve_time_sec     = NaN
    moi.termination_status = MOI.OPTIMIZE_NOT_CALLED
    moi.primal_status      = MOI.NO_SOLUTION
    moi.dual_status        = MOI.NO_SOLUTION
    moi.raw_status_string  = ""

    empty!(moi.variable_primal_start)

    moi.objective_sense = MOI.MIN_SENSE
end