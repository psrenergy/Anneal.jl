module RandomSampler

using Anneal
using Random
using MathOptInterface
const MOI = MathOptInterface
const VI = MOI.VariableIndex
const Maybe{T} = Union{T, Nothing}

include("sampler.jl")
include("MOI_wrapper.jl")

end # module