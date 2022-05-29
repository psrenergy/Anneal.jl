# -*- :: Random sampler :: -*-
Anneal.@anew begin
    NumberOfReads::Int     = 1_000
    RandomBias::Float64    = 0.5
    RandomSeed::Maybe{Int} = nothing
    RandomGenerator::Any   = MersenneTwister
end

# -*- :: Biased Random State Generation :: -*-
function random_sample(sampler::Optimizer, rng, bias::Float64)
    s = Int.(rand(rng, Float64, sampler.n) .< bias)

    return (s, 1, Anneal.energy(sampler, s))
end

function Anneal.sample(sampler::Optimizer)
    bias = MOI.get(sampler, RandomBias())
    seed = MOI.get(sampler, RandomSeed())

    Rng = MOI.get(sampler, RandomGenerator())
    rng = Rng(seed)

    t₀ = time()
    samples = [random_sample(sampler, rng, bias) for _ = 1:MOI.get(sampler, NumberOfReads())]
    t₁ = time()

    δt = t₁ - t₀

    return (samples, δt)
end