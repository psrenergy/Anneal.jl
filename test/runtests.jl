using Test
using Anneal
using JuMP

using MathOptInterface
const MOI = MathOptInterface
const MOIU = MOI.Utilities

# -*- Library -*- #
include("library/error.jl")

function test_library()
    @testset "-*- Library -*-" verbose = true begin
        test_error_library()
    end
end

# -*- Utility Samplers -*- #
include("samplers/exact.jl")
include("samplers/identity.jl")
include("samplers/random.jl")

function test_samplers()
    @testset "-*- Utility Samplers -*-" verbose = true begin
        test_exact_sampler()
        test_identiy_sampler()
        test_random_sampler()
    end
end

# ~*~ :: Run tests :: ~*~ #
function main()
    @testset "~*~ :: Anneal.jl Tests :: ~*~" verbose = true begin
        test_library()
        test_samplers()
    end
end

main() # Here we go!