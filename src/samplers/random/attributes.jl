struct NumberOfReads <: Anneal.AbstractSamplerAttribute end

function MOI.get(sampler::Optimizer, ::NumberOfReads)
    sampler.number_of_reads
end

function MOI.set(sampler::Optimizer, ::NumberOfReads, number_of_reads::Integer)
    @assert number_of_reads > 0
    sampler.number_of_reads = number_of_reads
end

struct RandomBias <: Anneal.AbstractSamplerAttribute end

function MOI.get(sampler::Optimizer, ::RandomBias)
    sampler.random_bias
end

function MOI.set(sampler::Optimizer, ::RandomBias, random_bias::Float64)
    @assert 0.0 <= random_bias <= 1.0
    sampler.random_bias = random_bias
end

struct RandomSeed <: Anneal.AbstractSamplerAttribute end

function MOI.get(sampler::Optimizer, ::RandomSeed)
    sampler.random_seed
end

function MOI.set(sampler::Optimizer, ::RandomSeed, random_seed::Union{Integer, Nothing})
    @assert random_seed > 0
    sampler.random_seed = random_seed
end

struct RandomGenerator <: Anneal.AbstractSamplerAttribute end

function MOI.get(sampler::Optimizer, ::RandomGenerator)
    sampler.random_generator
end

function MOI.set(sampler::Optimizer, ::RandomGenerator, random_generator::Any)
    sampler.random_generator = random_generator
end
