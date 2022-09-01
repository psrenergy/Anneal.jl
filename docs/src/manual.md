# Manual

## Introduction
The core idea behind this package is to provide a toolbox for developing and integrating QUBO annealing/sampling tools with the [JuMP](https://jump.dev) mathematical programming environment.
Appart from the few couple exported utility engines, Anneal.jl is inherently about extensions, which is achieved by implementing most of the [MOI](https://jump.dev/MathOptInterface.jl) requirements, leaving only the essential for the developer.

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
Anneal.qubo
Anneal.ising
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

    function Anneal.sample(sampler::Optimizer{T}) where {T}
        # ~ Is your annealer running on the Ising Model? Have this:
        h, J = Anneal.ising(
            Dict, # Here we opt for a sparse, dictionary representation 
            T,    # The type for coefficients
            sampler
        )

        n    = MOI.get(sampler, NumberOfReads())
        attr = MOI.get(sampler, SuperAttribute())

        result = @timed Vector{Int}[super_sample(h, J; attr=attr) for i = 1:n]
        states = result.value

        metadata = Dict{String,Any}(
            "time" => Dict{String,Any}(
                "sampling" => result.time
            ),
            "origin" => "Super sampling method"
        )

        # ~ Here some magic happens:
        #   By providing the sampler and a vector of states,
        #   Anneal.jl computes the energy and arranges your
        #   solutions automatically, following the variable
        #   domain conventions specified previously.
        # ~ The last parameter is for JSON-like metadata.
        return Anneal.SampleSet{Int,T}(sampler, states, metadata)
    end

    function super_sample(h, J; kws...)
        ... # your own magic here!
    end
end
```

Type assertion for `Anneal.sample`'s return can be done using the `::Tuple{Anneal.SamplerResults, Float64}` query.