module RandomSampler

using Anneal # MOI is exported
using Random

Anneal.@anew Optimizer begin
    name = "Random Sampler"
    sense = :min
    domain = :bool
    attributes = begin
        RandomSeed["seed"]::Union{Integer,Nothing} = nothing
        NumberOfReads["num_reads"]::Integer = 1_000
    end
end

function Anneal.sample(sampler::Optimizer{T}) where {T}
    # ~*~ Retrieve Attributes ~*~ #
    n         = MOI.get(sampler, MOI.NumberOfVariables())
    seed      = MOI.get(sampler, RandomSampler.RandomSeed())
    num_reads = MOI.get(sampler, RandomSampler.NumberOfReads())

    # ~*~ Validate Input ~*~ #
    if isnothing(seed)
        seed = trunc(Int, time())
    end

    @assert seed >= 0
    @assert num_reads >= 0

    # ~*~ Sample Random States ~*~ #
    rng = MersenneTwister(seed)

    result = @timed sample_states(rng, n, num_reads)
    states = result.value

    # ~*~ Timing Information ~*~ #
    time_data = Dict{String,Any}(
        "effective" => result.time
    )

    # ~*~ Write Solution Metadata ~*~ #
    metadata = Dict{String,Any}(
        "time"   => time_data,
        "origin" => "Random Sampler"
    )

    # ~*~ Return Sample Set ~*~ #
    return Anneal.SampleSet{T}(sampler, states, metadata)
end

function sample_states(rng, n::Integer, num_reads::Integer)
    return [rand(rng, (0,1), n) for _ = 1:num_reads]
end

end # module