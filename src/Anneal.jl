module Anneal

# ~*~ Imports: MathOptInterface ~*~ #
import JuMP
import MathOptInterface
const MOI = MathOptInterface
const MOIU = MOI.Utilities
const SQF{T} = MOI.ScalarQuadraticFunction{T}
const SQT{T} = MOI.ScalarQuadraticTerm{T}
const SAF{T} = MOI.ScalarAffineFunction{T}
const SAT{T} = MOI.ScalarAffineTerm{T}
const VI = MOI.VariableIndex
const CI = MOI.ConstraintIndex

# ~*~ Exports: MathOptInterface ~*~ #
export MOI

# ~*~ Imports: QUBOTools Backend ~*~ # 
import QUBOTools: QUBOTools, SampleSet, Sample, backend
import QUBOTools: ising, qubo, energy, adjacency

# ~*~ See:
# https://github.com/jump-dev/MathOptInterface.jl/issues/1985
QUBOTools.varcmp(x::VI, y::VI) = isless(x.value, y.value)

# ~*~ Imports: Tests + Benchmarking ~*~ #
import Test

# -*- Includes: Anneal -*- #
include("lib/error.jl")
include("lib/types.jl")
include("lib/tools.jl")

include("interface/abstract/interface.jl")
include("interface/abstract/wrapper.jl")

include("interface/automatic/interface.jl")
include("interface/automatic/attributes.jl")
include("interface/automatic/macros.jl")
include("interface/automatic/sample.jl")
include("interface/automatic/wrapper.jl")

# -*- Exports: Interface -*- #
export AbstractSampler
export @anew

# -*- Includes: Tests -*-
include("test/test.jl")

# -*- Includes: Benchmark -*-
include("benchmark/benchmark.jl")

# -*- Includes: Submodules -*-
include("samplers/IdentitySampler.jl")
include("samplers/ExactSampler.jl")
include("samplers/RandomSampler.jl")

# -*- Exports: Submodules -*- #
export IdentitySampler
export ExactSampler
export RandomSampler

end # module