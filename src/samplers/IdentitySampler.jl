module IdentitySampler

import Anneal
using MathOptInterface
const MOI = MathOptInterface

Anneal.@anew Optimizer begin
    name = "Identity Sampler"
end

function Anneal.sample(sampler::Optimizer{T}) where {T}
    # ~*~ Retrieve Attributes ~*~ #
    v = BQPIO.variable_inv(sampler)
    n = MOI.get(sampler, MOI.NumberOfVariables())

    # ~*~ Sample Random States ~*~ #
    results = @timed Vector{Int}[[
        MOI.get(sampler, MOI.VariablePrimalStart(), v[i])
        for i = 1:n
    ]]
    samples = results.value

    # ~*~ Write Solution Metadata ~*~ #
    metadata = Dict{String,Any}(
        "time" => Dict{String,Any}(
            "sample" => results.time,
        )
    )

    # ~*~ Return Sample Set ~*~ #
    Anneal.SampleSet{Int,T}(sampler, samples, metadata)
end

end # module