abstract type AbstractBQPIOSampler{T} <: AbstractSampler{T} end

function BQPIO.backend(::X) where X <: AbstractBQPIOSampler
    error("'BQPIO.backend' not implemented for '$X'")
end

function BQPIO.backend!(::X, ::BQPIO.AbstractBQPModel) where X <: AbstractBQPIOSampler
    error("'BQPIO.backend!' not implemented for '$X'")
end

# ~*~ :: MathOptInterface :: ~*~ #
function MOI.empty!(sampler::AbstractBQPIOSampler)
    empty!(BQPIO.backend(sampler))
end

function MOI.is_empty(sampler::AbstractBQPIOSampler)
    isempty(BQPIO.backend(sampler))
end

function MOI.optimize!(sampler::AbstractBQPIOSampler)
    Anneal.sample!(sampler)
end

function MOI.optimize!(sampler::AbstractBQPIOSampler, model::ModelLike)
    MOI.copy_to!(sampler, model)
    MOI.optimize!(sampler)
end

function Base.show(io::IO, sampler::AbstractBQPIOSampler)
    print(
        io,
        """
        $(MOI.get(sampler, ::MOI.SolverName())) Binary Quadratic Sampler

        with backend:
        """
    )
    print(io, BQPIO.backend(sampler))
end

function MOI.copy_to!(sampler::AbstractBQPIOSampler{T}, model::ModelLike) where T
    BQPIO.backend!(sampler, BQPIO.StandardBQPModel{T}(model))
end