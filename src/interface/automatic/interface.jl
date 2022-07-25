abstract type AutomaticSampler{T} <: Sampler{T} end

@doc raw"""
""" function __parse_results end

__parse_results(::AutomaticSampler, sampleset::Anneal.SampleSet) = sampleset

function __parse_results(sampler::AutomaticSampler{T}, samples::Vector{Vector{<:Integer}}) where T
    Anneal.SampleSet{Int, T}(samples, sampler)
end

function Anneal.sample(::AutomaticSampler)
    error("'Anneal.sample' is not implemented")
end

function Anneal.sample!(sampler::AutomaticSampler)
    results = @timed Anneal.sample(sampler)

    sampleset = Anneal.__parse_results(sampler, results.value)::Anneal.SampleSet

    if !haskey(sampleset.metadata, "time")
        sampleset.metadata["time"] = Dict{String, Any}(
            "total" => results.time,
        )
    elseif !haskey(sampleset.metadata["time"], "total")
        sampleset.metadata["time"]["total"] = results.time
    end

    backend = BQPIO.backend(sampler)
    backend.sampleset = sampleset

    nothing
end