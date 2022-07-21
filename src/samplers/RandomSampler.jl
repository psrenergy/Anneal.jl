module RandomSampler

import BQPIO
import Anneal

using Random
using MathOptInterface
const MOI = MathOptInterface
const VI = MOI.VariableIndex

mutable struct OptimizerAttributes
    number_of_reads::Int
    random_bias::Float64
    random_seed::Union{Int,Nothing}
    random_generator::Any

    function OptimizerAttributes(;
        number_of_reads::Integer = 1_000,
        random_bias::Float64 = 0.5,
        random_seed::Union{Integer, Nothing} = nothing,
        random_generator::Any = Random.MersenneTwister,
        )

        new(
            number_of_reads,
            random_bias,
            random_seed,
            random_generator,
        )
    end
end

const BQPIO_BACKEND{T} = BQPIO.StandardBQPModel{VI,Int,T,BQPIO.BoolDomain}

struct Optimizer{T} <: Anneal.Sampler{T, BQPIO.BoolDomain}
    # ~*~ Backend ~*~
    backend::
    # ~*~ MOI Attributes ~*~
    moi_attrs::Anneal.MOIAttributes{T}
    # ~*~ Optimizer Attributes ~*~
    opt_attrs::OptimizerAttributes
    
    function Optimizer{T}() where T
        new{T}(
            BQPIO.StandardBQPModel{VI, Int, T, BQPIO.BoolDomain}(),
            Anneal.MOIAttributes{T}(),
            OptimizerAttributes(),
        )
    end

    function Optimizer()
        Optimizer{Float64}()
    end
end

BQPIO.backend(sampler::Optimizer) = sampler.backend

MOI.get(::Optimizer, ::MOI.SolverName) = "Random Sampler"
MOI.get(::Optimizer, ::MOI.SolverVersion) = v"1.0.0"

struct NumberOfReads <: Anneal.AbstractSamplerAttribute end

function MOI.get(sampler::Optimizer, ::NumberOfReads)
    sampler.opt_attrs.number_of_reads
end

function MOI.set(sampler::Optimizer, ::NumberOfReads, number_of_reads::Integer)
    @assert number_of_reads > 0
    sampler.opt_attrs.number_of_reads = number_of_reads
    
    nothing
end

struct RandomBias <: Anneal.AbstractSamplerAttribute end

function MOI.get(sampler::Optimizer, ::RandomBias)
    sampler.opt_attrs.random_bias
end

function MOI.set(sampler::Optimizer, ::RandomBias, random_bias::Float64)
    @assert 0.0 <= random_bias <= 1.0
    sampler.opt_attrs.random_bias = random_bias
    
    nothing
end

struct RandomSeed <: Anneal.AbstractSamplerAttribute end

function MOI.get(sampler::Optimizer, ::RandomSeed)
    sampler.opt_attrs.random_seed
end

function MOI.set(sampler::Optimizer, ::RandomSeed, random_seed::Union{Integer, Nothing})
    @assert isnothing(random_seed) || random_seed > 0
    sampler.opt_attrs.random_seed = random_seed

    nothing
end

struct RandomGenerator <: Anneal.AbstractSamplerAttribute end

function MOI.get(sampler::Optimizer, ::RandomGenerator)
    sampler.opt_attr.random_generator
end

function MOI.set(sampler::Optimizer, ::RandomGenerator, random_generator::Any)
    sampler.opt_attr.random_generator = random_generator

    nothing
end

random_sample(rng::Any, n::Integer, random_bias::Float64) = Int.(rand(rng, Float64, n) .< random_bias)

function Anneal.sample(sampler::Optimizer{T}) where {T}
    random_bias = MOI.get(sampler, RandomBias())
    random_seed = MOI.get(sampler, RandomSeed())

    rng = random_seed |> MOI.get(sampler, RandomGenerator())

    m = MOI.get(sampler, NumberOfReads())
    n = MOI.get(sampler, MOI.NumberOfVariables())

    # ~*~ Sample Random States ~*~ #
    t₀ = time()

    samples = Vector{Int}[random_sample(rng, n, random_bias) for _ = 1:m]
    
    t₁ = time()

    # ~ Write Solution Metadata ~ #
    metadata = Dict{String,Any}(
        "time" => Dict{String,Any}(
            "total" => (t₁ - t₀),
        ),
    )

    BQPIO.SampleSet{Int,T}(samples, sampler, metadata)
end

end # module