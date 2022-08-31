@doc raw"""
    __parse_results(sampler::AutomaticSampler, samples::Anneal.SampleSet)
    __parse_results(sampler::AutomaticSampler{T}, samples::Vector{Vector{U}}) where {T,U<:Integer}
""" function __parse_results end

function __parse_results(
    sampler::AutomaticSampler{T},
    results::Anneal.SampleSet{U,T},
) where {U,T}
    if Anneal.model_domain(sampler) === Anneal.solver_domain(sampler)
        return results
    elseif Anneal.model_domain(sampler) === QUBOTools.SpinDomain
        samples = Anneal.Sample{U,T}[
            Anneal.Sample{U,T}(
                (2 .* sample.state) .- 1,
                sample.reads,
                sample.value,
            )
            for sample in results.samples
        ]
    elseif Anneal.model_domain(sampler) === QUBOTools.BoolDomain
        samples = Anneal.Sample{U,T}[
            Anneal.Sample{U,T}(
                (sample.state .+ 1) .÷ 2,
                sample.reads,
                sample.value,
            )
            for sample in results.samples
        ]
    end

    return Anneal.SampleSet{U,T}(
        samples,
        deepcopy(results.metadata),
    )
end

function __parse_results(
    sampler::AutomaticSampler{T},
    results::Vector{Vector{U}},
) where {T,U}
    return Anneal.SampleSet{U,T}(sampler, results)
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
    backend = QUBOTools.backend(sampler)
    backend.sampleset = sampleset

    nothing
end