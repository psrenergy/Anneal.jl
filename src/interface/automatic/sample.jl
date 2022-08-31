function Anneal.SampleSet{U,T}(
    sampler::AutomaticSampler,
    _states::Vector{Vector{U}},
    metadata::Union{Dict{String,Any},Nothing}=nothing,
) where {U,T}
    states = QUBOTools.swap_domain(
        Anneal.solver_domain(sampler),
        Anneal.model_domain(sampler),
        _states
    )

    samples = Anneal.Sample{U,T}[
        Anneal.Sample{U,T}(state, 1, Anneal.energy(state, sampler))
        for state in states
    ]

    return Anneal.SampleSet{U,T}(samples, metadata)
end

@doc raw"""
    __parse_results(sampler::AutomaticSampler, samples::Anneal.SampleSet)
    __parse_results(sampler::AutomaticSampler{T}, samples::Vector{Vector{U}}) where {T,U<:Integer}
""" function __parse_results end

function __parse_results(
    ::AutomaticSampler{T},
    results::Anneal.SampleSet{U,T},
) where {U,T}
    return results
end

function __parse_results(
    sampler::AutomaticSampler{T},
    results::Vector{Vector{U}},
) where {U,T}
    return Anneal.SampleSet{U,T}(sampler, results)
end

function Anneal.sample!(sampler::AutomaticSampler)
    # ~*~ Timing Information ~*~ #
    time_data = Dict{String,Any}()
    
    # ~*~ Run Sampling ~*~ # 
    sampleset = let results = @timed Anneal.sample(sampler)
        time_data["total"] = results.time
        
        Anneal.__parse_results(sampler, results.value)
    end

    # ~*~ Time metadata ~*~ #
    if !haskey(sampleset.metadata, "time")
        sampleset.metadata["time"] = time_data
    elseif !haskey(sampleset.metadata["time"], "total")
        sampleset.metadata["time"]["total"] = time_data["total"]
    end

    # ~*~ Update sampleset ~*~ #
    backend = QUBOTools.backend(sampler)
    backend.sampleset = sampleset

    nothing
end