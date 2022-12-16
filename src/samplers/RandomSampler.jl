module RandomSampler

using Anneal # MOI is exported
using Random

Anneal.@anew Optimizer begin
    name = "Random Sampler"
    sense = :min
    domain = :bool
    attributes = begin
        RandomSeed["seed"]::Union{Integer,Nothing} = nothing
        NumberOfReads["num_reads"]::Integer = 1_000
    end
end

function Anneal.sample(sampler::Optimizer{T}) where {T}
    # ~*~ Retrieve Model ~*~ #
    Q, α, β = Anneal.qubo(sampler, Dict, T)

    # ~*~ Retrieve Attributes ~*~ #
    n    = MOI.get(sampler, MOI.NumberOfVariables())
    m    = MOI.get(sampler, RandomSampler.NumberOfReads())
    seed = MOI.get(sampler, RandomSampler.RandomSeed())

    # ~*~ Validate Input ~*~ #
    if isnothing(seed)
        seed = trunc(Int, time())
    end

    @assert m >= 0
    @assert seed >= 0

    # ~*~ Sample Random States ~*~ #
    rng     = MersenneTwister(seed)
    results = @timed random_sample(rng, Q, α, β, n, m)
    samples = results.value

    # ~*~ Timing Information ~*~ #
    time_data = Dict{String,Any}(
        "effective" => results.time
    )

    # ~*~ Write Solution Metadata ~*~ #
    metadata = Dict{String,Any}(
        "time"   => time_data,
        "origin" => "Random Sampler @ Anneal.jl"
    )

    # ~*~ Return Sample Set ~*~ #
    return Anneal.SampleSet{T}(samples, metadata)
end

function random_sample(
    rng,
    Q::Dict{Tuple{Int,Int},T},
    α::T,
    β::T,
    n::Integer,
    m::Integer,
) where {T}
    samples = Vector{Sample{T,Int}}(undef, m)

    for i = 1:m
        ψ = rand(rng, (0, 1), n)

        samples[i] = Sample{T,Int}(ψ, α * (Anneal.value(Q, ψ) + β))
    end

    return samples
end

end # module