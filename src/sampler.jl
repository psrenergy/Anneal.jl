# -*- Sample & SampleSet -*-
mutable struct Sample{S<:Any,T<:Any}
    states::Vector{S}
    reads::Int
    energy::T
end

mutable struct SampleSet{S<:Any,T<:Any}
    samples::Vector{Sample{S,T}}
    mapping::Dict{Vector{S},Int}

    function SampleSet{S,T}() where {S,T}
        return new{S,T}(
            Vector{Sample{S,T}}(),
            Dict{Vector{S},Int}()
        )
    end

    """
    Guarantees duplicate removal and that samples are ordered by energy (<), reads (>) & states (<).
    """
    function SampleSet{S,T}(data::Vector{Sample{S,T}}) where {S,T}
        samples = Vector{Sample{S,T}}()
        mapping = Dict{Vector{S},Int}()

        i = 1

        for sample in data
            if haskey(mapping, sample.states)
                samples[mapping[sample.states]].reads += sample.reads
            else
                push!(samples, sample)
                mapping[sample.states] = i
                i += 1
            end
        end

        I = sortperm(samples, by=(ξ) -> (ξ.energy, -ξ.reads, ξ.states))

        samples = samples[I]
        mapping = Dict{Vector{S},Int}(s => I[i] for (s, i) in mapping)

        return new{S,T}(samples, mapping)
    end
end

Base.isempty(s::SampleSet) = isempty(s.samples)
Base.length(s::SampleSet) = length(s.samples)

function Base.iterate(s::SampleSet)
    return iterate(s.samples)
end

function Base.iterate(s::SampleSet, i::Int)
    return iterate(s.samples, i)
end

function Base.getindex(s::SampleSet, i::Int)
    return getindex(s.samples, i)
end

function Base.merge(x::SampleSet{S,T}, y::SampleSet{S,T}) where {S,T}
    return SampleSet{S,T}(Vector{Sample{S,T}}([x.samples; y.samples]))
end

function Base.merge!(x::SampleSet{S,T}, y::SampleSet{S,T}) where {S,T}
    i = length(x.samples)

    for sample in y.samples
        if haskey(x.mapping, sample.states)
            x.samples[x.mapping[sample.states]].reads += sample.reads
        else
            push!(x.samples, sample)
            i = x.mapping[sample.states] = i + 1
        end
    end

    I = sortperm(x.samples, by=(ξ) -> (ξ.energy, -ξ.reads, ξ.states))

    x.samples = x.samples[I]
    x.mapping = Dict{Vector{S},Int}(s => I[i] for (s, i) in x.mapping)

    nothing
end

function Base.empty!(s::SampleSet)
    empty!(s.samples)
    empty!(s.mapping)
end

# -*- :: Samplers :: -*-
abstract type AbstractSampler{T<:Any} <: MOI.AbstractOptimizer end

const SamplerResults = Vector{Tuple{Vector{Int},Int,Float64}}

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

function energy(sampler::AbstractSampler{T}, s::Vector{Int}) where {T}
    return sum(s[i] * s[j] * Qᵢⱼ for ((i, j), Qᵢⱼ) ∈ sampler.Q; init=sampler.c)
end

Base.@kwdef mutable struct SamplerMOI{T}
    name::String = ""
    silent::Bool = false
    time_limit_sec::Maybe{Float64} = nothing
    raw_optimizer_attributes::Dict{Symbol,Any} = Dict{Symbol,Any}()
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
    moi.name = ""
    moi.silent = false
    moi.time_limit_sec = nothing
    empty!(moi.raw_optimizer_attributes)
    moi.number_of_threads = Threads.nthreads()

    moi.solve_time_sec = NaN
    moi.termination_status = MOI.OPTIMIZE_NOT_CALLED
    moi.primal_status = MOI.NO_SOLUTION
    moi.dual_status = MOI.NO_SOLUTION
    moi.raw_status_string = ""

    empty!(moi.variable_primal_start)

    moi.objective_sense = MOI.MIN_SENSE
end