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

import Test

# ~*~ Imports: Backend ~*~ # 
import QUBOTools: QUBOTools, SampleSet, Sample
import QUBOTools: ising, qubo

# -*- Exports: Interface -*- #
export AbstractSampler, Sampler, @anew

# -*- Exports: Submodules -*- #
export IdentitySampler, ExactSampler, RandomSampler

# -*- Includes: Anneal -*- #
include("lib/error.jl")
include("lib/tools.jl")
include("interface/abstract/interface.jl")
include("interface/abstract/MOI_wrapper.jl")
include("interface/automatic/interface.jl")
include("interface/automatic/attributes.jl")
include("interface/automatic/macros.jl")
include("interface/automatic/QUBOTools_wrapper.jl")
include("interface/automatic/MOI_wrapper.jl")

# -*- Includes: Tests -*-
include("test/test.jl")

# -*- Includes: Submodules -*-
include("samplers/IdentitySampler.jl")
include("samplers/ExactSampler.jl")
include("samplers/RandomSampler.jl")

end # module