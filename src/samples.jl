# -*- Sample & SampleSet -*-
mutable struct Sample{S,T}
    state::Vector{S}
    reads::Int
    value::T

    function Sample{S, T}(state::Vector{S}, reads::Integer, value::T) where {S, T}
        new{S, T}(state, reads, value)
    end

    function Sample{S, T}(sample::Tuple{Vector{<:S}, Integer, T}) where {S, T}
        new{S, T}(sample...)
    end
end

function Base.:(==)(x::Sample, y::Sample)
    (x.state == y.state) && (x.reads == y.reads) && (x.value == y.value)
end

mutable struct SampleSet{S,T}
    samples::Vector{Sample{S,T}}
    mapping::Dict{Vector{S},Int}

    function SampleSet{S,T}() where {S,T}
        return new{S,T}(
            Vector{Sample{S,T}}(),
            Dict{Vector{S},Int}()
        )
    end

    """
    Guarantees duplicate removal and that samples are ordered by value (<), reads (>) & state (<).
    """
    function SampleSet{S,T}(data::Vector{Sample{S,T}}) where {S,T}
        samples = Vector{Sample{S,T}}()
        mapping = Dict{Vector{S},Int}()

        i = 1

        for sample in data
            if haskey(mapping, sample.state)
                samples[mapping[sample.state]].reads += sample.reads
            else
                push!(samples, sample)
                mapping[sample.state] = i
                i += 1
            end
        end

        I = sortperm(samples, by=(ξ) -> (ξ.value, -ξ.reads, ξ.state))

        samples = samples[I]
        mapping = Dict{Vector{S},Int}(s => I[i] for (s, i) in mapping)

        return new{S,T}(samples, mapping)
    end
end

function Base.:(==)(x::SampleSet, y::SampleSet)
    x.samples == y.samples
end

function Base.isempty(s::SampleSet)
    isempty(s.samples)
end

function Base.length(s::SampleSet)
    length(s.samples)
end

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
    return SampleSet{S,T}(Sample{S,T}[x.samples; y.samples])
end

function Base.merge!(x::SampleSet{S,T}, y::SampleSet{S,T}) where {S,T}
    i = length(x.samples)

    for sample in y.samples
        if haskey(x.mapping, sample.state)
            x.samples[x.mapping[sample.state]].reads += sample.reads
        else
            push!(x.samples, sample)
            i = x.mapping[sample.state] = i + 1
        end
    end

    I = sortperm(x.samples, by=(ξ) -> (ξ.value, -ξ.reads, ξ.state))

    x.samples = x.samples[I]
    x.mapping = Dict{Vector{S},Int}(s => I[i] for (s, i) in x.mapping)

    x
end

function Base.empty!(s::SampleSet)
    empty!(s.samples)
    empty!(s.mapping)
end