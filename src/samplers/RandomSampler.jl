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
    n = MOI.get(sampler, MOI.NumberOfVariables())
    num_reads = MOI.get(sampler, RandomSampler.NumberOfReads())

    # ~*~ Timing Information ~*~ #
    time_data = Dict{String,Any}()

    # ~*~ Sample Random States ~*~ #
    states = let results = @timed Vector{Int}[rand(Bool, n) for _ = 1:num_reads]
        time_data["sampling"] = results.time

        results.value
    end

    # ~*~ Write Solution Metadata ~*~ #
    metadata = Dict{String,Any}(
        "time"   => time_data,
        "origin" => "Random Sampler"
    )

    # ~*~ Return Sample Set ~*~ #
    Anneal.SampleSet{Int,T}(sampler, states, metadata)
end

end # module