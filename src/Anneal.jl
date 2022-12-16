module Anneal

# ~*~ Imports: JuMP + MathOptInterface ~*~ #
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
import QUBOTools: QUBOTools, SampleSet, Sample, backend, frontend
import QUBOTools: ising, qubo, adjacency, reads, state, value
import QUBOTools: sampleset, variables, indices
import QUBOTools: ↑, ↓

# ~*~ Expots: QUBOTools Backend ~*~ #
export QUBOTools, SampleSet, Sample
export ising, qubo, adjacency, reads, state, value
export sampleset, variables, indices
export ↑, ↓

# ~*~ See:
# https://github.com/jump-dev/MathOptInterface.jl/issues/1985
QUBOTools.varcmp(x::VI, y::VI) = isless(x.value, y.value)

# ~*~ Imports: Tests + Benchmarking ~*~ #
import Test
import BenchmarkTools

# -*- Includes: Library -*- #
include("lib/error.jl")
include("lib/types.jl")
include("lib/tools.jl")

# -*- Exports: Spin Variables -*- #
export Spin

# -*- Includes: Interface -*- #
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