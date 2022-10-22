function Anneal.SampleSet{T,U}(
    sampler::AutomaticSampler,
    _states::Vector{Vector{U}},
    metadata::Union{Dict{String,Any},Nothing}=nothing,
) where {T,U}
    states = QUBOTools.swap_domain(
        Anneal.solver_domain(sampler),
        Anneal.model_domain(sampler),
        _states
    )

    samples = Anneal.Sample{T,U}[
        Anneal.Sample{T,U}(state, Anneal.energy(sampler, state))
        for state in states
    ]

    return Anneal.SampleSet{T,U}(samples, metadata)
end

@doc raw"""
    __parse_results(sampler::AutomaticSampler, samples::Anneal.SampleSet)
    __parse_results(sampler::AutomaticSampler{T}, samples::Vector{Vector{U}}) where {T,U<:Integer}
""" function __parse_results end

function __parse_results(
    ::AutomaticSampler{T},
    results::Anneal.SampleSet{T,U},
) where {T,U}
    return results
end

function __parse_results(
    sampler::AutomaticSampler{T},
    results::Vector{Vector{U}},
) where {T,U}
    return Anneal.SampleSet{T,U}(sampler, results)
end

function Anneal.sample!(sampler::AutomaticSampler)
    # ~*~ Run Sampling ~*~ # 
    result = @timed Anneal.sample(sampler)

    sampleset = Anneal.__parse_results(sampler, result.value)

    # ~*~ Timing Information ~*~ #
    time_data = Dict{String,Any}(
        "total" => result.time
    )

    # ~*~ Time metadata ~*~ #
    if !haskey(sampleset.metadata, "time")
        sampleset.metadata["time"] = time_data
    elseif !haskey(sampleset.metadata["time"], "total")
        sampleset.metadata["time"]["total"] = time_data["total"]
    end

    # ~*~ Update sampleset ~*~ #
    backend = QUBOTools.backend(sampler)
    backend.sampleset = sampleset

    return nothing
end