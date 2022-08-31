@doc raw"""
    __parse_results(sampler::AutomaticSampler, samples::Anneal.SampleSet)
    __parse_results(sampler::AutomaticSampler{T}, samples::Vector{Vector{U}}) where {T,U<:Integer}
""" function __parse_results end

function __parse_results(
    sampler::AutomaticSampler,
    results::Anneal.SampleSet
)
    results = QUBOTools.swap_sense(
        Anneal.solver_sense(sampler),
        Anneal.model_sense(sampler),
        results,
    )

    results = QUBOTools.swap_domain(
        Anneal.solver_domain(sampler),
        Anneal.model_domain(sampler),
        results,
    )

    return results
end

function __parse_results(
    sampler::AutomaticSampler{T},
    results::Vector{Vector{U}}
) where {T,U<:Integer}

    return Anneal.SampleSet{U,T}(results, sampler)
end

function Anneal.sample!(sampler::AutomaticSampler)
    results = @timed Anneal.sample(sampler)
    sampleset = Anneal.__parse_results(sampler, results.value)

    # ~*~ Time metadata ~*~ #
    if !haskey(sampleset.metadata, "time")
        sampleset.metadata["time"] = Dict{String,Any}(
            "total" => results.time,
        )
    elseif !haskey(sampleset.metadata["time"], "total")
        sampleset.metadata["time"]["total"] = results.time
    end

    # ~*~ Update sampleset ~*~ #
    QUBOTools.sample!(
        sampler,
        sampleset;
        sense=sampler.sense,
        domain=sampler.domain
    )

    nothing
end