module RandomSampler

using BQPIO
using Anneal
using Random
using MathOptInterface
const MOI = MathOptInterface
const VI = MOI.VariableIndex

const OPTIMIZER_BACKEND{T} = BQPIO.StandardBQPModel{VI,Int,T,BQPIO.BoolDomain}

struct Optimizer{T} <: Anneal.AbstractSampler{T}
    # ~*~ Backend ~*~
    backend::OPTIMIZER_BACKEND{T}
    # ~*~ Attributes ~*~
    number_of_reads::Int
    random_bias::Float64
    random_seed::Union{Int,Nothing}
    random_generator::Any

    function Optimizer{T}(
        backend::OPTIMIZER_BACKEND{T};
        number_of_reads::Integer=1_000,
        random_bias::Float64=0.5,
        random_seed::Union{Integer,Nothing}=nothing,
        random_generator::Any=MersenneTwister
    ) where {T}
        new{T}(
            backend,
            number_of_reads,
            random_bias,
            random_seed,
            random_generator,
        )
    end

    function Optimizer{T}() where {T}
        backend = BQPIO.StandardBQPModel{VI,Int,T,BQPIO.BoolDomain}(
            Dict{Int,T}(),
            Dict{Tuple{Int,Int},T}(),
            Dict{VI,Int}();
        )

        new{T}(backend)
    end
end

end # module