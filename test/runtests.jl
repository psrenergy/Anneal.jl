using Test
using Anneal

using MathOptInterface
const MOI = MathOptInterface
const MOIU = MOI.Utilities

# -*- QUBO Models -*-
include("qubo.jl")
include("error.jl")
include("tools.jl")
include("samples.jl")

include("interface/moi.jl")
include("interface/jump.jl")

# -*- Utility Samplers -*-
include("samplers/exact.jl")
include("samplers/identity.jl")
include("samplers/random.jl")

# -*- Interfaced Samplers -*-
include("samplers/simulated.jl")