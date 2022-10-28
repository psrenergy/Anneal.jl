function parse_results(::AutomaticSampler, ::S) where {S}
    throw(Anneal.SampleError("Invalid results of type '$S'"))
end

function parse_results(
    sampler::AutomaticSampler{T},
    results::Anneal.SampleSet{T,U},
) where {T,U}
    S = Anneal.solver_domain(sampler)
    M = Anneal.model_domain(sampler)

    return QUBOTools.swap_domain(S, M, results)
end

function Anneal.sample!(sampler::AutomaticSampler)
    # ~*~ Run Sampling ~*~ # 
    results   = @timed Anneal.sample(sampler)
    sampleset = Anneal.parse_results(sampler, results.value)

    # ~*~ Timing Information ~*~ #
    time_data = Dict{String,Any}(
        "total" => results.time
    )

    # ~*~ Time metadata ~*~ #
    if !haskey(sampleset.metadata, "time")
        sampleset.metadata["time"] = time_data
    elseif !haskey(sampleset.metadata["time"], "total")
        sampleset.metadata["time"]["total"] = time_data["total"]
    end

    # ~*~ Update sampleset ~*~ #
    model = Anneal.backend(sampler)::QUBOTools.StandardQUBOModel
    model.sampleset = sampleset

    return nothing
end