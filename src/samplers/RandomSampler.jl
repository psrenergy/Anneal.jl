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
    m = MOI.get(sampler, RandomSampler.NumberOfReads())
    n = MOI.get(sampler, MOI.NumberOfVariables())

    # ~*~ Sample Random States ~*~ #
    results = @timed Vector{Int}[rand(Bool, n) for _ = 1:m]
    samples = results.value

    # ~*~ Write Solution Metadata ~*~ #
    metadata = Dict{String,Any}(
        "time" => Dict{String,Any}(
            "sample" => results.time,
        ),
    )

    # ~*~ Return Sample Set ~*~ #
    Anneal.SampleSet{Int,T}(sampler, samples, metadata)
end

end # module