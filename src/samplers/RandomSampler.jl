module RandomSampler

using Anneal # MOI is exported
using Random

Anneal.@anew Optimizer begin
    name    = "Random Sampler"
    sense   = :min
    domain  = :bool
    version = v"0.6.0"
    attributes = begin
        RandomSeed["seed"]::Union{Integer,Nothing}  = nothing
        NumberOfReads["num_reads"]::Integer         = 1_000
        RandomGenerator["rng"]::AbstractRNG         = Random.GLOBAL_RNG
    end
end

@doc raw"""
    RandomSampler.Optimizer{T}

## Attributes
- `RandomSeed`, `"seed"`: Random seed to initialize the random number generator.
- `NumberOfReads`, `"num_reads"`: Number of random states sampled per run.
- `RandomGenerator`, `"rng"`: Random Number Generator instance.
""" Optimizer

function Anneal.sample(sampler::Optimizer{T}) where {T}
    # ~*~ Retrieve Model ~*~ #
    Q, α, β = Anneal.qubo(sampler, Dict)

    # ~*~ Retrieve Attributes ~*~ #
    n         = MOI.get(sampler, MOI.NumberOfVariables())
    num_reads = MOI.get(sampler, RandomSampler.NumberOfReads())
    seed      = MOI.get(sampler, RandomSampler.RandomSeed())
    rng       = MOI.get(sampler, RandomSampler.RandomGenerator())

    # ~*~ Validate Input ~*~ #
    @assert num_reads >= 0
    @assert isnothing(seed) || seed >= 0
    @assert rng isa AbstractRNG

    # ~*~ Seed Random Number generator ~*~ #
    Random.seed!(rng, seed)

    # ~*~ Sample Random States ~*~ #
    results = @timed random_sample(rng, Q, α, β, n, num_reads)
    samples = results.value

    # ~*~ Write Solution Metadata ~*~ #
    metadata = Dict{String,Any}(
        "origin" => "Random Sampler @ Anneal.jl",
        # ~*~ Timing Information ~*~ #
        "time"   => Dict{String,Any}(
            "effective" => results.time
        ),
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
    num_reads::Integer,
) where {T}
    samples = Vector{Sample{T,Int}}(undef, num_reads)

    for i = 1:num_reads
        ψ = rand(rng, (0, 1), n)
        λ = Anneal.value(Q, ψ, α, β)

        samples[i] = Sample{T,Int}(ψ, λ)
    end

    return samples
end

end # module