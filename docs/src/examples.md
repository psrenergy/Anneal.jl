# Examples

## Simple QUBO
```@example simple-qubo
using JuMP
using Anneal

model = Model(SimulatedAnnealer.Optimizer)

Q = [ 1.0  2.0 -3.0
      2.0 -1.5 -2.0
     -3.0 -2.0  0.5 ]

@variable(model, x[i = 1:3], Bin)
@objective(model, Min, x' * Q * x)

optimize!(model)

for i = 1:result_count(model)
      xi = value.(x; result = i)
      yi = objective_value(model; result = i)
      println("f($xi) = $yi")
end
```

## Optimizer Settings
```@example simple-qubo
set_optimizer_parameter(model, SimulatedAnnealer.NumberOfReads(), 500)
get_optimizer_parameter(model, SimulatedAnnealer.NumberOfReads())
```