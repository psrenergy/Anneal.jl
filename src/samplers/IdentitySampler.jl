module IdentitySampler

import Anneal
using MathOptInterface
const MOI = MathOptInterface

Anneal.@anew Optimizer begin
    name = "Identity Sampler"
    sense = :min
    domain = :bool
end

function Anneal.sample(sampler::Optimizer{T}) where {T}
    # ~*~ Retrieve Attributes ~*~ #
    n = MOI.get(sampler, MOI.NumberOfVariables())

    # ~*~ Sample Random States ~*~ #
    results = @timed Vector{Int}[Int[
        MOI.get(
            sampler,
            MOI.VariablePrimalStart(),
            QUBOTools.variable_inv(sampler, i)
        )
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