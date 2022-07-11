function random_sample(rng::Any, n::Integer, random_bias::Float64)
    Int.(rand(rng, Float64, n) .< random_bias)
end

function Anneal.sample(sampler::Optimizer{T}) where {T}
    random_bias = MOI.get(sampler, RandomBias())
    random_seed = MOI.get(sampler, RandomSeed())

    rng = random_seed |> MOI.get(sampler, RandomGenerator())

    m = MOI.get(sampler, NumberOfReads())
    n = MOI.get(sampler, MOI.NumberOfVariables())

    t₀ = time()
    samples = Vector{Int}[random_sample(rng, n, random_bias) for _ = 1:m]
    t₁ = time()
    δt = t₁ - t₀

    metadata = Dict{String,Any}(
        "time" => Dict{String,Any}(
            "total" => δt,
        ),
    )

    BQPIO.SampleSet{Int,T}(samples, sampler, metadata)
end