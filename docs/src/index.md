# Anneal.jl Documentation

## Introduction
This package aims to provide a common [MOI](https://github.com/jump-dev/MathOptInterface.jl)-compliant API for [QUBO](https://en.wikipedia.org/wiki/Quadratic_unconstrained_binary_optimization) Sampling & Annealing machines.
It also contains a few utility samplers and testing tools for performance comparison, sanity checks and basic analysis features.

## Quick Start

### Installation
[Anneal.jl](https://github.com/psrenergy/Anneal.jl) is registered in Julia's General Registry and is available for download using the standard package manager.

```julia-repl
julia> ]add Anneal
```
or
```julia-repl
julia> import Pkg; Pkg.add("Anneal")
``` 

You might also be interested in the latest development version:

```julia-repl
julia> ]add Anneal#master
```

### Example
```@example
using JuMP
using Anneal

model = Model(ExactSampler.Optimizer)

Q = [
    -1.0  2.0  2.0
     2.0 -1.0  2.0
     2.0  2.0 -1.0
]

@variable(model, x[1:3], Bin)
@objective(model, Min, x' * Q * x)

optimize!(model)

for i = 1:result_count(model)
    xᵢ = value.(x; result=i)
    yᵢ = objective_value(model; result=i)
    rᵢ = reads(model; result=i)
    println("f($xᵢ) = $yᵢ ($rᵢ)")
end
```

## Citing Anneal.jl
```tex
@software{anneal.jl:2022,
  author = {Pedro Xavier and Tiago Andrade and Joaquim Garcia and David Bernal},
  title        = {Anneal.jl},
  month        = {sep},
  year         = {2022},
  publisher    = {Zenodo},
  version      = {v0.4.2},
  doi          = {10.5281/zenodo.6390515},
  url          = {https://doi.org/10.5281/zenodo.6390515}
}
```