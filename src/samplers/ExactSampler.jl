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

    # ~*~ Sample All States ~*~ #
    result = @timed sample_states(n)
    states = result.value

    # ~*~ Timing Information ~*~ #
    time_data = Dict{String,Any}(
        "effective" => result.time
    )

    # ~*~ Write Solution Metadata ~*~ #
    metadata = Dict{String,Any}(
        "time"   => time_data,
        "origin" => "Exact Sampler @ Anneal.jl"
    )

    # ~*~ Return Sample Set ~*~ #
    return Anneal.SampleSet{T}(sampler, states, metadata)
end

sample_states(n::Integer) = digits.(Int, 0:(2^n - 1); base=2, pad=n)

end # module