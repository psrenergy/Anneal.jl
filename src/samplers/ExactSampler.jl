module ExactSampler

import Anneal
using MathOptInterface
const MOI = MathOptInterface

Anneal.@anew Optimizer begin
    name   = "Exact Sampler"
    sense  = :min
    domain = :bool
end

function Anneal.sample(sampler::Optimizer{T}) where {T}
    # ~*~ Retrieve Model ~*~ #
    Q, α, β = Anneal.qubo(sampler, Dict, T)

    # ~*~ Retrieve Attributes ~*~ #
    n = MOI.get(sampler, MOI.NumberOfVariables())

    # ~*~ Sample All States ~*~ #
    results = @timed exact_sample(Q, α, β, n)
    samples = results.value

    # ~*~ Timing Information ~*~ #
    time_data = Dict{String,Any}(
        "effective" => results.time
    )

    # ~*~ Write Solution Metadata ~*~ #
    metadata = Dict{String,Any}(
        "time"   => time_data,
        "origin" => "Exact Sampler @ Anneal.jl"
    )

    # ~*~ Return Sample Set ~*~ #
    return Anneal.SampleSet{T}(samples, metadata)
end

@inline sample_state(i::Integer, n::Integer) = digits(Int, i - 1; base=2, pad=n)

function exact_sample(Q::Dict{Tuple{Int,Int},T}, α::T, β::T, n::Integer) where {T}
    m       = 2^n
    samples = Vector{Anneal.Sample{T,Int}}(undef, m)

    for i = 1:m
        ψ = sample_state(i, n)

        samples[i] = Anneal.Sample{T,Int}(ψ, α * (Anneal.energy(Q, ψ) + β))
    end

    return samples
end



end # module