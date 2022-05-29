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

Even though only QUBO formulations are supported as input (mostly due to the lack of backend support for spin variables e.g. ``s \in \{-1, 1\}``), Anneal provides internal tools for working with Ising Model instances since many samplers rely on it.
Validation and basic conversion is made using the functions below.

```@docs
Anneal.isqubo
Anneal.qubo_normal_form
Anneal.ising_normal_form
```

## Defining a Sampler

To speed up
```


```