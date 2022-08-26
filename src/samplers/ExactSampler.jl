module ExactSampler

import Anneal
using MathOptInterface
const MOI = MathOptInterface

Anneal.@anew Optimizer begin
    name = "Exact Sampler"
end

function Anneal.sample(sampler::Optimizer{T}) where {T}
    # ~*~ Retrieve Attributes ~*~ #
    n = MOI.get(sampler, MOI.NumberOfVariables())
    N = 2^n - 1

    # ~*~ Sample Random States ~*~ #
    results = @timed begin
        states = Vector{Int}[digits(i; base=2, pad=n) for i = 0:N]

        Anneal.Sample{Int,T}[
            Anneal.Sample{Int,T}(
                ψ,
                1,
                Anneal.energy(ψ, sampler)
            )
            for ψ in states
        ]
    end

    samples = results.value

    # ~*~ Write Solution Metadata ~*~ #
    metadata = Dict{String,Any}(
        "time" => Dict{String,Any}(
            "sample" => results.time,
        )
    )

    # ~*~ Return Sample Set ~*~ #
    return Anneal.SampleSet{Int,T}(samples, metadata)
end

end # module