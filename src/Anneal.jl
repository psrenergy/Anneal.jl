module Anneal

using BQPIO
using MathOptInterface
const MOI = MathOptInterface
const MOIU = MOI.Utilities

const SQF{T} = MOI.ScalarQuadraticFunction{T}
const SQT{T} = MOI.ScalarQuadraticTerm{T}
const SAF{T} = MOI.ScalarAffineFunction{T}
const SAT{T} = MOI.ScalarAffineTerm{T}
const VI = MOI.VariableIndex
const CI = MOI.ConstraintIndex

import Test

# -*- Exports: Interface -*-
export AbstractSampler, @anew

# -*- Exports: Submodules -*-
export ExactSampler, RandomSampler, IdentitySampler

# -*- Includes: Anneal -*-
include("lib/error.jl")
include("lib/tools.jl")
include("interface/interface.jl")
include("interface/MOI_wrapper.jl")
# include("interface/macros.jl")
# include("interface/tests.jl")

# -*- Includes: Submodules -*-
include("samplers/random/RandomSampler.jl")
# include("samplers/exact/exact.jl")
# include("samplers/identity/identity.jl")

end # module