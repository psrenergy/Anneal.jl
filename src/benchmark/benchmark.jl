@doc raw"""
    benchmark(sampler::AbstractSampler)

""" function benchmark end

function Anneal.benchmark(sampler::AbstractSampler)
    
end

@doc raw"""
    benchmark_suite(sampler::AbstractSampler)

## Example

```
using Anneal
using SuperSampler

SUITE = Anneal.benchmark_suite(SuperSampler.Optimizer)
```
""" function benchmark_suite end

function Anneal.benchmark_suite(sampler::AbstractSampler)
    suite = BenchmarkTools.BenchmarkGroup()

    return suite
end