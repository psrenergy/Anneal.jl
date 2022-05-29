# Manual

## Introduction
The core idea behind this package is to provide a toolbox for developing and integrating QUBO annealing/sampling tools with the [JuMP](https://jump.dev) mathematical programming environment.
Appart from the few couple bundled engines, Anneal.jl is inherently about extensions, which is achieved by implementing most of the [MOI](https://jump.dev/MathOptInterface.jl) requirements, leaving only the essential for the developer.

The annealers and samplers defined via the `AbstractSampler{T}` interface only support models given in a QUBO form, as explained below.

### QUBO
An optimization problem is in its QUBO form if it is written as
```math
\begin{array}{rl}
    \min & \mathbf{x}^{\intercal} \mathbf{Q}\, \mathbf{x} + c \\
    \text{s.t.} & \mathbf{x} \in \mathbb{B}^{n}
\end{array}
```
where ``\mathbf{Q} \in \mathbb{R}^{n}`` is a symmetric matrix and ``c \in \mathbb{R}`` the constant offset.

In terms of Julia's data structures, we define a *QUBO Normal Form* (NQF) with a triplet
```julia
(x::Dict{VI, Union{Int, Nothing}}, Q::Dict{Tuple{Int, Int}, T}, c::T)
```
where ``x`` provides a mapping between each MathOptInterface's `VariableIndex` and the corresponding integer index in `Q`.

Even though only QUBO formulations are supported as input, Anneal provides internal tools for working with Ising Model instances since many samplers rely on it.
Model validation and trivial QUBO/Insing conversion is made using the functions below.
```@docs
Anneal.isqubo
Anneal.qubo_normal_form
Anneal.ising_normal_form
```

## Defining a new sampler interface

The `Anneal.@anew` macro is available to speed up the interface setup process.
```@docs
Anneal.@anew
```

Inside a module scope for the new interface, one should call the `Anneal.@anew` macro, specifying the solver's attributes as described in the macro's docs. One must also define `MOI.get` methods for the `MOI.SolverName`, `MOI.RawSolver` and `MOI.SolverVersion` attributes. The last and most important step is to define the `Anneal.sample` method, which returns both a vector with every sample and also the sampling time. The whole standard definition is described in the next example.

```julia
module SuperAnnealer
    using Anneal

    Anneal.@anew begin
        NumberOfReads::Integer = 100
        SuperAttribute::Any = nothing
    end # This will define Optimizer{T} <: MOI.AbstractOptimizer

    # -*- MathOptInterface -*-
    function MOI.get(::Optimizer, MOI.SolverName)
        "Super Annealer"
    end

    function MOI.get(::Optimizer, MOI.SolverVersion)
        v"0.1.0" # Version strings are welcome!
    end

    function MOI.get(sampler::Optimizer, MOI.RawSolver)
        # Usually the sampler itself, since we are prtty much low-level here.
        # If you call another optimizer under the hood, you might want to return it.
        sampler 
    end

    function Anneal.sample(sampler::Optimizer)
        # Is your annealer running on the Ising Model? Have this:
        s, h, J, c = Anneal.ising_normal_form(sampler.x, sampler.Q, sampler.c)

        n = MOI.get(sampler, NumberOfReads())
        attr = MOI.get(sampler, SuperAttribute())

        t0 = time()
        results = [super_sample(h, J, attr) for i = 1:n]
        t1 = time()

        return (results, t1 - t0)
    end
end
```

Type assertion for `Anneal.sample`'s return can be done using the `::Tuple{Anneal.SamplerResults, Float64}` query.