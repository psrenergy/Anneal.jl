module IdentitySampler

using Anneal
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
    result = @timed sample_state(sampler, n)
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
    s = Vector{MOI.VariableIndex}(undef, n)

    for i = 1:n
        v = QUBOTools.variable_inv(sampler, i)
        x = MOI.get(sampler, MOI.VariablePrimalStart(), v)

        if isnothing(x)
            error("Missing warm-start value for state variable '$v'")
        else
            s[i] = x
        end
    end

    return s
end

end # module