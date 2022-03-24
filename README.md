# Anneal.jl 🔴🟢🟣🔵

Implements wrappers for QUBO Annealers & Samplers through the `AbstractSampler{T} <: MOI.AbstractOptimizer{T}` API, allowing `MathOptInterface` & `JuMP` integration.

<div align="center">
    <a href="/docs/src/assets/">
        <img src="/docs/src/assets/logo.svg" width=400px alt="Anneal.jl" />
    </a>  
</div>

## Quick Start
```julia
using JuMP
using Anneal

model = Model(SimulatedAnnealing.Optimizer)

Q = [ 1.0  2.0 -3.0
      2.0 -1.5 -2.0
     -3.0 -2.0  0.5 ]

@variable(model, x[i = 1:3], Bin)
@objective(model, Min, x' * Q * x)

optimize!(model)
```

## Supported Annealers & Samplers
| Module Name         | Descripition | Status |
| :------------------ | :----------: | :----: |
| `SimulatedAnnealer` |     `-`      |   ✔️    |
| `ExactSampler`      |     `-`      |   ✔️    |
| `RandomSampler`     |     `-`      |   ✔️    |
| `IdentitySampler`   |     `-`      |   ✔️    |