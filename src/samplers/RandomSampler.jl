module RandomSampler

import Anneal
using MathOptInterface
const MOI = MathOptInterface

Anneal.@anew Optimizer begin
    name = "Random Sampler"
    sense = :min
    domain = :bool
    attributes = begin
        NumberOfReads["num_reads"]::Integer = 1_000
    end
end

function Anneal.sample(sampler::Optimizer{T}) where {T}
    # ~*~ Retrieve Attributes ~*~ #
    n         = MOI.get(sampler, MOI.NumberOfVariables())
    num_reads = MOI.get(sampler, RandomSampler.NumberOfReads())

    # ~*~ Sample Random States ~*~ #
    result = @timed sample_states(n, num_reads)
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

function sample_states(n::Integer, num_reads::Integer)
    return Vector{Int}[rand((0,1), n) for _ = 1:num_reads]
end

end # module