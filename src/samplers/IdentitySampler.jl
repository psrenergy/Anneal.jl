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

    # ~*~ Retrieve warm-start state ~*~ #
    result = sample_state(sampler, n)
    states = [result.value]

    # ~*~ Timing Information ~*~ #
    time_data = Dict{String,Any}(
        "effective" => result.time
    )

    # ~*~ Write Solution Metadata ~*~ #
    metadata = Dict{String,Any}(
        "time"   => time_data,
        "origin" => "Identity Sampler @ Anneal.jl"
    )

    # ~*~ Return Sample Set ~*~ #
    return Anneal.SampleSet{T}(sampler, states, metadata)
end

function sample_state(sampler::Optimizer, n::Integer)
    v = MOI.VariableIndex[QUBOTools.variable_inv(sampler, i) for i = 1:n]

    return MOI.get.(sampler, MOI.VariablePrimalStart(), v)
end

end # module