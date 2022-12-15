# A new Sampler
This guide aims to provide a tutorial on how to implement new sampler interfaces using [Anneal.jl](https://github.com/psrenergy/Anneal.jl).

## The `@anew` macro
Using the [`Anneal.@anew`](@ref anew-macro) macro is the most straightforward way to get your sampler running right now.
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
In order to work smoothly, this approach leverages the [`QUBOTools`](https://github.com/psrenergy/QUBOTools.jl) backend.

We expect that most users will be happy with this approach and it is likely that it will be improved and receive support very often.

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