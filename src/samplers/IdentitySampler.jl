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

    # ~*~ Timing Information ~*~ #
    time_data = Dict{String,Any}()

    # ~*~ Retrieve warm-start state ~*~ #
    state = let results = @timed Int[
            MOI.get(
                sampler,
                MOI.VariablePrimalStart(),
                QUBOTools.variable_inv(sampler, i)
            )
            for i = 1:n
        ]

        time_data["sampling"] = results.time

        results.value
    end

    # ~*~ Write Solution Metadata ~*~ #
    metadata = Dict{String,Any}(
        "time"   => time_data,
        "origin" => "Identity Sampler"
    )

    # ~*~ Return Sample Set ~*~ #
    Anneal.SampleSet{Int,T}(sampler, [state], metadata)
end

end # module