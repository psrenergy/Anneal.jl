module Anneal

using MathOptInterface
const MOI = MathOptInterface
const MOIU = MOI.Utilities

const SQF{T} = MOI.ScalarQuadraticFunction{T}
const SQT{T} = MOI.ScalarQuadraticTerm{T}
const SAF{T} = MOI.ScalarAffineFunction{T}
const SAT{T} = MOI.ScalarAffineTerm{T}
const VI = MOI.VariableIndex
const CI = MOI.ConstraintIndex
const Maybe{T} = Union{T, Nothing}

# -*- Exports: Interface -*-
export MOI, AbstractSampler, AbstractSamplerAttribute, @anew

# -*- Exports: Submodules -*-
export ExactSampler, RandomSampler, IdentitySampler
export SimulatedAnnealer

# -*- Includes: Anneal -*-
include("error.jl")
include("tools.jl")
include("samples.jl")
include("interface.jl")
include("MOI_wrapper.jl")
include("macros.jl")

# -*- Includes: Submodules -*-
include("samplers/random/random.jl")
using .RandomSampler

include("samplers/exact/exact.jl")
using .ExactSampler

include("samplers/identity/identity.jl")
using .IdentitySampler

include("annealers/simulated/simulated.jl")
using .SimulatedAnnealer

end # module