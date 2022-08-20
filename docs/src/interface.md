# A new Sampler

This guide aims to provide be a Tutorial on how to implement new sampler interfaces using [Anneal.jl](https://github.com/psrenergy/Anneal.jl).
There are basically three paths to follow, each one depending on the desired level of control over the wrapper's behaviour.

## The `@anew` macro
Using the [`Anneal.@anew`](@ref) macro is the most straightforward way to get your sampler running right now.
Apart from the macro call it is needed to implement the [`Anneal.sample`](@ref) method.

### I. Imports
First of all, we are going to import both `Anneal.jl` and also `MathOptInterface.jl`, commonly aliased as `MOI`.
```julia
import Anneal
import MathOptInterface
const MOI = MathOptInterface
```

### II. `@anew`
This macro takes two arguments: the identifier of the sampler's `struct`, and a `begin...end` block containing configuration parameters as *key-value* pairs.
If ommited, the first defaults to `Optimizer`, following regular `MOI` conventions.


```julia
Anneal.@anew Optimizer begin
    name    = "Super Sampler"
    version = v"0.1.0"
    domain  = :spin

    attributes = begin
        NumberOfReads["num_reads"]::Integer = 1_000
        SuperAttribute["super_attr"]::String = "super"
    end
end
```

```julia
function Anneal.sample(sampler::Optimizer{T}) where T
    # ~ Retrieve Problem in Array form ~
    x, s, Q, c = Anneal.qubo(Array, sampler)

    # ~ Retrieve Attributes ~ #
    num_reads = MOI.get(sample, NumberOfReads())
    @assert num_reads > 0

    super_attr = MOI.get(sample, SuperAttribute())
    @assert super_attr ∈ ("super", "ultra", "mega")    

    # ~*~ Call Super Sampler ~*~ #
    t0 = time()

    samples = ccall(
        :super_sample,
        Vector{Int},
        (
            Ptr{Cdouble},
            Cint,
            Cstring,
        ),
        Q,
        num_reads,
        super_attr,
    )

    t1 = time()

    # ~ Write Solution Metadata ~ #
    metadata = Dict{String, Any}(
        "solver" => "Super Sampler (C++)",
        "time" => Dict{String, Any}(
            "total" => (t1 - t0),
        )
    )

    # ~ Return Sample Set ~
    return Anneal.SampleSet{Int, T}(samples, sampler, metadata)
end
```

Types are guaranteed to be consistent. In the other hand, values must undergo assertion


We expect that most users will be happy with this approach and it is likely that it will be improved very often.

### The [`QUBOTools`](https://github.com/psrenergy/QUBOTools.jl) backend

If you want to dive deeper into

```julia
import Anneal
import QUBOTools

const QUBOTools_BACKEND{T} = QUBOTools.StandardBQPModel{VI, Int, T, QUBOTools.BoolDomain}

mutable struct Optimizer{T} <: Anneal.Sampler{T}
    backend::QUBOTools_BACKEND{T}
end

QUBOTools.backend(sampler::Optimizer) = sampler.backend
```

## MathOptInterface API Coverage
This Document is intended to help keeping track of which MOI API Methods and Properties have been implemented for a new solver or model interface.

### Reference:
[jump.dev/MathOptInterface.jl/stable/tutorials/implementing/](https://jump.dev/MathOptInterface.jl/stable/tutorials/implementing/)

### Optimizer Interface
| Method                                        | Status |
| :-------------------------------------------- | :----: |
| `MOI.empty!(::Optimizer)`                     |   ✅    |
| `MOI.is_empty(::Optimizer)::Bool`             |   ✅    |
| `MOI.optimize!(::Optimizer, ::MOI.ModelLike)` |   ✅    |
| `Base.show(::IO, ::Optimizer)`                |   ✔️    |

### The `copy_to` interface 
| Method                                      | Status |
| :------------------------------------------ | :----: |
| `MOI.copy_to(::Optimizer, ::MOI.ModelLike)` |   ✅    |

### Constraint Support
| Method                                                              | Status |
| :------------------------------------------------------------------ | :----: |
| `MOI.supports_constraint(::Optimizer, ::F, ::S)::Bool where {F, S}` |   ✔️    |

## Attributes
| Property                    | Type      | `get` | `set` | `supports` |
| :-------------------------- | :-------- | :---: | :---: | :--------: |
| `MOI.SolverName`            | `String`  |   Ⓜ️   |   -   |     -      |
| `MOI.SolverVersion`         | `String`  |   Ⓜ️   |   -   |     -      |
| `MOI.RawSolver`             | `String`  |   ✔️   |   -   |     -      |
| `MOI.Name`                  | `String`  |   Ⓜ️   |   Ⓜ️   |     Ⓜ️      |
| `MOI.Silent`                | `Bool`    |   Ⓜ️   |   Ⓜ️   |     Ⓜ️      |
| `MOI.TimeLimitSec`          | `Float64` |   Ⓜ️   |   Ⓜ️   |     Ⓜ️      |
| `MOI.RawOptimizerAttribute` | `Any`     |   Ⓜ️   |   Ⓜ️   |     Ⓜ️      |
| `MOI.NumberOfThreads`       | `Int`     |   Ⓜ️   |   Ⓜ️   |     Ⓜ️      |

## Solution
| Property                | Type                        | `get` | `set` | `supports` |
| :---------------------- | :-------------------------- | :---: | :---: | :--------: |
| `MOI.PrimalStatus`      | `MOI.ResultStatusCode`      |   Ⓜ️   |   -   |     -      |
| `MOI.DualStatus`        | `MOI.ResultStatusCode`      |   Ⓜ️   |   -   |     -      |
| `MOI.RawStatusString`   | `String`                    |   Ⓜ️   |   -   |     -      |
| `MOI.ResultCount`       | `Int`                       |   Ⓜ️   |   -   |     -      |
| `MOI.TerminationStatus` | `MOI.TerminationStatusCode` |   Ⓜ️   |   -   |     -      |
| `MOI.ObjectiveValue`    | `T`                         |   Ⓜ️   |   -   |     -      |
| `MOI.SolveTimeSec`      | `Float64`                   |   Ⓜ️   |   -   |     -      |
| `MOI.VariablePrimal`    | `T`                         |   Ⓜ️   |   -   |     -      |

## Warm Start
| Property                  | Type  | `get` | `set` | `supports` |
| :------------------------ | :---: | :---: | :---: | :--------: |
| `MOI.VariablePrimalStart` |  `T`  |   Ⓜ️   |   Ⓜ️   |     Ⓜ️      |

## Key
| Symbol | Meaning                                           |
| :----: | :------------------------------------------------ |
|   Ⓜ️    | Implemented via the [`@anew`]() macro             |
|   ✅    | Available for [`Sampler{T}`]()                    |
|   ✔️    | Available for [`AbstracSampler{T}`]()             |
|   ⚠️    | Must be implemented                               |
|   ❌    | Not implemented, but you can do it if you want to |