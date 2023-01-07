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

### The [`@anew`](@id anew) macro
`Anneal.@anew` is available to speed up the interface setup process.
This mechanism was created to reach the majority of the target audience, that is, researchers interested in integrating their QUBO/Ising samplers in a common optimization ecossystem.

```@docs
Anneal.@anew
```

Inside a module scope for the new interface, one should call the [`Anneal.@anew`](@ref anew) macro, specifying the solver's attributes as described in the macro's docs.
The second and last step is to define the `Anneal.sample(::Optimizer)` method, that must return a [`Anneal.SampleSet`](@ref sampleset).

Using it might be somehow restrictive in comparison to the regular [JuMP/MOI Solver Interface workflow](https://jump.dev/MathOptInterface.jl/stable/tutorials/implementing/).
Yet, our guess is that most of this package's users are not considering going deeper into the MOI internals that soon.

### [`@anew`](@ref anew-macro) example
The following example is intended to illustrate the usage of the macro, showing how simple it should be to implement a wrapper for a sampler implemented in another language such as C or C++.

```julia
module SuperSampler
    using Anneal

    Anneal.@anew Optimizer begin
        name    = "Super Sampler"
        sense   = :max
        domain  = :spin
        version = v"1.0.2"
        attributes = begin
            SuperAttribute::String = "super"
            NumberOfReads["num_reads"]::Integer = 1_000
        end
    end

    model = Model(SuperSampler.Optimizer)

    @variable(model, x[1:n], Bin)
    @objective(model, Min, x' * Q * x)

    function Anneal.sample(sampler::Optimizer{T}) where {T}
        # ~ Is your annealer running on the Ising Model? Have this:
        h, J, u, v = Anneal.ising(
            sampler,
            Vector, # Here we opt for a sparse, vector representation
        )

        n = MOI.get(sampler, MOI.NumberOfVariables())

        # ~ Retrieve Attributes ~ #
        num_reads = MOI.get(sampler, NumberOfReads())
        @assert num_reads > 0

        super_attr = MOI.get(sampler, SuperAttribute())
        @assert super_attr ∈ ("super", "ultra", "mega")    

        # ~*~ Timing Information ~*~ #
        time_data = Dict{String,Any}()

        # ~*~ Run Algorithm ~*~ #
        result = @timed Vector{Int}[
            super_sample(h, J, u, v; attr=super_attr)
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
        #   Anneal.jl computes the energy and organizes your
        #   solutions automatically, following the variable
        #   domain conventions specified previously.
        return Anneal.SampleSet{T}(sampler, states, metadata)
    end

    function super_sample(h, J, u, v; super_attr, kws...)
        return ccall(
            :super_sample,
            Vector{Int},
            (
                Ptr{Cdouble},
                Ptr{Cdouble},
                Ptr{Cdouble},
                Ptr{Cdouble},
                Cint,
                Cstring,
            ),
            h,
            J,
            u,
            v,
            super_attr,
        )
    end
end
```

### Walkthrough
Now, it's time to go through the example in greater detail.
First of all, the entire work must be done within a module.

```julia
module SuperSampler
    using Anneal
```

By provding the `using Anneal` statement, very little will be dumped into the namespace apart from the `MOI = MathOptInterface` constant.
MOI's methods will soon be very important to access our optimizer's attributes.

```julia
Anneal.@anew Optimizer begin
    name    = "Super Sampler"
    sense   = :max
    domain  = :spin
    version = v"1.0.2"
    attributes = begin
        SuperAttribute::String = "super"
        NumberOfReads["num_reads"]::Integer = 1_000
    end
end
```

The first parameter in the `@anew` call is the optimizer's identifier.
It defaults to `Optimizer` and, in this case, is responsible for defining the `Optimizer{T} <: MOI.AbstractOptimizer` struct.
A `begin...end` block comes next, with a few key-value pairs.

!!! info
    Our solver, when deployed to be used within JuMP, will probably have its users to follow the usual construct:

    ```julia
    using JuMP
    using SuperSampler

    model = Model(SuperSampler.Optimizer)
    ```

The solver `name` must be a string, and will be used as the return value for [`MOI.get(::Optimizer, ::MOI.SolverName())`](https://jump.dev/MathOptInterface.jl/stable/reference/models/#MathOptInterface.SolverName).

```julia
name = "Super Sampler"
```

The `sense` and `domain` values indicate how our new solvers expect its models to be presented and, even more importantly, how the resulting samples should be interpreted.
Their values must be either `:min` or `:max` and `:boll` or `:spin`, respectively.
Strings, symbols and literals are supported as input for these fields.

```julia
sense  = :max
domain = :spin
```

The other metadata entry is the `version` assignment, which is returned by [`MOI.get(::Optimizer, ::MOI.SolverVersion())`](https://jump.dev/MathOptInterface.jl/stable/reference/models/#MathOptInterface.SolverVersion).
In order to consistently support [semantic versioning](https://semver.org/) it is required that the version number comes as a _v-string_ e.g. `v"major.minor.patch"`.

```julia
version = v"1.0.2"
```

# Model Mapping

# Automatic Tests
```@docs
Anneal.test
```