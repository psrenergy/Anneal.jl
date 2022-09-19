# Manual

## Introduction
The core idea behind this package is to provide a toolbox for developing and integrating [QUBO](https://en.wikipedia.org/wiki/Quadratic_unconstrained_binary_optimization) sampling tools with the [JuMP](https://jump.dev) mathematical programming environment.
Appart from the few couple exported utility engines, Anneal.jl is inherently about extensions, which is achieved by implementing most of the [MOI](https://jump.dev/MathOptInterface.jl) requirements, leaving only the essential for the developer.

### QUBO
An optimization problem is in its QUBO form if it is written as

```math
\begin{array}{rl}
           \min & \alpha \left[ \mathbf{x}'\mathbf{Q}\,\mathbf{x} + \mathbf{\ell}'\mathbf{x} + \beta \right] \\
    \text{s.t.} & \mathbf{x} \in S \cong \mathbb{B}^{n}
\end{array}
```
with linear terms ``\mathbf{\ell} \in \mathbb{R}^{n}`` and quadratic ``\mathbf{Q} \in \mathbb{R}^{n \times n}``. ``\alpha, \beta \in \mathbb{R}`` are, respectively, the scaling and offset factors.

The MOI-JuMP optimizers defined using the `Anneal.AbstractSampler{T} <: MOI.AbstractOptimizer` interface only support models given in the QUBO form.
_Anneal.jl_ employs [QUBOTools](https://github.com/psrenergy/QUBOTools.jl) on many tasks involving data management and querying.
It is worth taking a look at [QUBOTool's docs](https://psrenergy.github.io/QUBOTools.jl).

## Defining a new sampler interface

### Showcase
Before explaining in detail how to use this package, it's good to list a few examples for the reader to grasp.
Below, there are links to the files where the actual interfaces are implemented, including thin wrappers, interfacing with Python and Julia implementations of common algorithms and heuristics.

| Project                                                                                   | Source Code                                                                                                                       |
| :---------------------------------------------------------------------------------------- | :-------------------------------------------------------------------------------------------------------------------------------- |
| [DWaveNeal.jl](https://github.com/psrenergy/DWaveNeal.jl)                                 | [DWaveNeal](https://github.com/psrenergy/DWaveNeal.jl/blob/main/src/DWaveNeal.jl)                                                 |
| [IsingSolvers.jl](https://github.com/psrenergy/IsingSolvers.jl)                           | [GreedyDescent](https://github.com/psrenergy/IsingSolvers.jl/blob/main/src/solvers/greedy_descent.jl)                             |
|                                                                                           | [ILP](https://github.com/psrenergy/IsingSolvers.jl/blob/main/src/solvers/ilp.jl)                                                  |
|                                                                                           | [MCMCRandom](https://github.com/psrenergy/IsingSolvers.jl/blob/main/src/solvers/mcmc_random.jl)                                   |
| [QuantumAnnealingInterface.jl](https://github.com/psrenergy/QuantumAnnealingInterface.jl) | [QuantumAnnealingInterface](https://github.com/psrenergy/QuantumAnnealingInterface.jl/blob/main/src/QuantumAnnealingInterface.jl) |

### The [`@anew`](@id anew-macro) macro
`Anneal.@anew` is available to speed up the interface setup process.

```@docs
Anneal.@anew
```

Inside a module scope for the new interface, one should call the [`Anneal.@anew`](@ref anew-macro) macro, specifying the solver's attributes as described in the macro's docs.
The second and last step is to define the `Anneal.sample(::Optimizer)` method, that must return a [`Anneal.SampleSet`](@ref sampleset).

```julia
module SuperAnnealer
    using Anneal

    # This will define Optimizer{T} <: MOI.AbstractOptimizer
    Anneal.@anew begin
        name = "Super Sampler"
        sense = :max
        domain = :spin
        version = v"1.0.2"
        attributes = begin
            SuperAttribute::Any = nothing
            NumberOfReads("num_reads")::Integer = 1_000
        end
    end

    function Anneal.sample(sampler::Optimizer{T}) where {T}
        # ~ Is your annealer running on the Ising Model? Have this:
        h, J = Anneal.ising(
            Dict, # Here we opt for a sparse, dictionary representation 
            T,    # The coefficient type
            sampler
        )

        # ~ Retrieve Attributes ~ #
        num_reads = MOI.get(sample, NumberOfReads())
        @assert num_reads > 0

        super_attr = MOI.get(sample, SuperAttribute())
        @assert super_attr ∈ ("super", "ultra", "mega")    

        # ~*~ Timing Information ~*~ #
        time_data = Dict{String,Any}()

        # ~*~ Run Algorithm ~*~ #
        result = @timed Vector{Int}[
            super_sample(h, J; attr=super_attr)
            for _ = 1:num_reads
        ]
        states = result.value

        # ~*~ Record Time ~*~ #
        time_data["effective"] = result.time

        metadata = Dict{String,Any}(
            "time"   => time_data,
            "origin" => "Super Sampling method"
        )

        # ~ Here some magic happens:
        #   By providing the sampler and a vector of states,
        #   Anneal.jl computes the energy and arranges your
        #   solutions automatically, following the variable
        #   domain conventions specified previously.
        # ~ The last parameter is for JSON-like metadata.
        return Anneal.SampleSet{Int,T}(sampler, states, metadata)
    end

    function super_sample(h, J; super_attr, kws...)
        ccall(
        :super_sample,
        Vector{Int},
        (
            Ptr{Cdouble},
            Cint,
            Cstring,
        ),
        h,
        J,
        super_attr,
    )
    end
end
```