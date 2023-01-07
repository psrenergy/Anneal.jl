function _parse_results(results)
    sampleset  = results.value
    total_time = results.time

    # ~*~ Timing Information ~*~ #
    metadata = QUBOTools.metadata(sampleset)
    timedata = Dict{String,Any}("total" => total_time)

    if !haskey(metadata, "time")
        metadata["time"] = timedata
    elseif !haskey(sampleset.metadata["time"], "total")
        metadata["time"]["total"] = timedata["total"]
    end

    return sampleset
end

function Anneal.sample!(sampler::AutomaticSampler)
    # ~*~ Run Sampling ~*~ # 
    results = @timed Anneal.sample(sampler)

    target_results = _parse_results(results)
    source_results = QUBOTools.cast(
        QUBOTools.sense(backend(sampler)),
        QUBOTools.sense(frontend(sampler)),
        QUBOTools.domain(backend(sampler)),
        QUBOTools.domain(frontend(sampler)),
        target_results,
    )

    # ~*~ Update sampleset ~*~ #
    copy!(sampleset(backend(sampler)), target_results)
    copy!(sampleset(frontend(sampler)), source_results)

    return nothing
end