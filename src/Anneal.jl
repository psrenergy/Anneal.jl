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
include(joinpath("lib", "error.jl"))
include(joinpath("lib", "tools.jl"))
include(joinpath("lib", "samples.jl"))
include(joinpath("interface", "interface.jl"))
include(joinpath("interface", "MOI_wrapper.jl"))
include(joinpath("interface", "macros.jl"))

# -*- Includes: Submodules -*-
include(joinpath("samplers", "random", "random.jl"))
include(joinpath("samplers", "exact", "exact.jl"))
include(joinpath("samplers", "identity", "identity.jl"))
include(joinpath("samplers", "simulated", "simulated.jl"))

end # module