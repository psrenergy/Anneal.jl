module ExactSampler

import Anneal
using MathOptInterface
const MOI = MathOptInterface

Anneal.@anew Optimizer begin
    name = "Exact Sampler"
    sense = :min
    domain = :bool
end

function Anneal.sample(sampler::Optimizer{T}) where {T}
    # ~*~ Retrieve Attributes ~*~ #
    n = MOI.get(sampler, MOI.NumberOfVariables())
    N = 2^n - 1

    # ~*~ Timing Information ~*~ #
    time_data = Dict{String,Any}()

    # ~*~ Sample All States ~*~ #
    states = let results = @timed Vector{Int}[digits(i; base=2, pad=n) for i = 0:N]
        time_data["sampling"] = results.time

        results.value
    end


    # ~*~ Write Solution Metadata ~*~ #
    metadata = Dict{String,Any}(
        "time"   => time_data,
        "origin" => "Exact Sampler"
    )

    # ~*~ Return Sample Set ~*~ #
    return Anneal.SampleSet{Int,T}(sampler, states, metadata)
end

end # module