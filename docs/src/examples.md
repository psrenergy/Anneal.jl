# Examples

## Solving Simple QUBO Model with Anneal's [`RandomSampler`](@ref random-sampler)

```@example simple-workflow
using JuMP
using Anneal

model = Model(RandomSampler.Optimizer)

Q = [
    -1.0  2.0  2.0
     2.0 -1.0  2.0
     2.0  2.0 -1.0
]

@variable(model, x[1:3], Bin)
@objective(model, Min, x' * Q * x)

optimize!(model)
```

### Recover Results

```@example simple-workflow
for i = 1:result_count(model)
    # State vector
    xi = value.(x; result=i)

    # Energy
    yi = objective_value(model; result=i)

    # Sampling Frequency
    ri = reads(model; result=i)

    println("f($xi) = $(yi)\t×$(ri)")
end
```

### Plot: Sampling distribution

```@example simple-workflow
using Plots

# Extract SampleSet
ω = sampleset(model)

plot(ω)
```