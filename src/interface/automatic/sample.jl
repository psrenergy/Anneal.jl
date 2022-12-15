function parse_results(::AutomaticSampler, ::S) where {S}
    throw(Anneal.SampleError("Invalid results of type '$S'"))
end

function parse_results(
    sampler::AutomaticSampler{T},
    results::Anneal.SampleSet{T,U},
) where {T,U}
    results = QUBOTools.swap_domain(
        Anneal.solver_domain(sampler),
        Anneal.model_domain(sampler),
        results
    )

    results = QUBOTools.swap_sense(
        Anneal.solver_sense(sampler),
        Anneal.model_sense(sampler),
        results
    )

    return results
end

function Anneal.sample!(sampler::AutomaticSampler)
    # ~*~ Run Sampling ~*~ # 
    results   = @timed Anneal.sample(sampler)
    sampleset = Anneal.parse_results(sampler, results.value)

    # ~*~ Timing Information ~*~ #
    timedata = Dict{String,Any}("total" => results.time)
    metadata = QUBOTools.metadata(sampleset)

    # ~*~ Time metadata ~*~ #
    if !haskey(metadata, "time")
        metadata["time"] = timedata
    elseif !haskey(sampleset.metadata["time"], "total")
        metadata["time"]["total"] = timedata["total"]
    end

    # ~*~ Update sampleset ~*~ #
    model = frontend(sampler)::QUBOTools.Model

    copy!(QUBOTools.sampleset(model), sampleset)

    return nothing
end