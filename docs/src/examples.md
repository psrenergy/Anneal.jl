# Examples

## Simple QUBO
```@example
using JuMP
using Anneal

model = Model(SimulatedAnnealer.Optimizer)

Q = [ 1.0  2.0 -3.0
      2.0 -1.5 -2.0
     -3.0 -2.0  0.5 ]

@variable(model, x[i = 1:3], Bin)
@objective(model, Min, x' * Q * x)

optimize!(model)
```

## Optimizer Settings
```julia
set_optimizer_parameter(model, SimulatedAnnealer.NumReads, 500)
set_optimizer_parameter(model, SimulatedAnnealer.NumSweeps, 500)
```