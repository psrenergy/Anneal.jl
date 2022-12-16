# ~ Currently, all models in this context are unconstrained by definition.
MOI.supports_constraint(
    ::AbstractSampler,
    ::Type{<:MOI.AbstractFunction},
    ::Type{<:MOI.AbstractSet},
) = false

# ~ They are also binary
MOI.supports_constraint(
    ::AbstractSampler,
    ::Type{<:MOI.VariableIndex},
    ::Type{<:MOI.ZeroOne},
) = true

MOI.supports_constraint(
    ::AbstractSampler,
    ::Type{<:MOI.VariableIndex},
    ::Type{<:Anneal.Spin},
) = true

# ~ Objective Function Support
MOI.supports(
    ::AbstractSampler,
    ::MOI.ObjectiveFunction{<:Any}
) = false

MOI.supports(
    ::AbstractSampler{T},
    ::MOI.ObjectiveFunction{<:Union{SQF{T}, SAF{T}, VI}}
) where {T} = true

# By default, all samplers are their own raw solvers.
MOI.get(sampler::AbstractSampler, ::MOI.RawSolver) = sampler

# Since problems are unconstrained, all available solutions are feasible.
function MOI.get(sampler::AbstractSampler, ps::MOI.PrimalStatus)
    n = MOI.get(sampler, MOI.ResultCount())
    i = ps.result_index

    if 1 <= i <= n
        return MOI.FEASIBLE_POINT
    else
        return MOI.NO_SOLUTION
    end
end

MOI.get(::AbstractSampler, ::MOI.DualStatus) = MOI.NO_SOLUTION

# ~ Introduce `reads(model; result = i)` interface.
#   The `reads` function is exported.
function QUBOTools.reads(model::JuMP.Model; result::Integer = 1)
    return QUBOTools.reads(model, result)
end

# ~ Give access to QUBOTools' queries.
# Other packages, such as ToQUBO.jl, also would like to apply 
# this extesion to connect JuMP and QUBOTools.
# ToQUBO.jl and Anneal.jl share many use cases, but are inde-
# pendent in a conceptual sense.
if !hasmethod(QUBOTools.backend, (JuMP.Model,))
    function QUBOTools.backend(model::JuMP.Model)
        return QUBOTools.frontend(JuMP.unsafe_backend(model))
    end
end

function QUBOTools.Sense(sense::MOI.OptimizationSense)
    if sense === MOI.MIN_SENSE
        return QUBOTools.Sense(:min)
    elseif sense === MOI.MAX_SENSE
        return QUBOTools.Sense(:max)
    else
        error("Invalid sense for QUBO: '$sense'")
    end
end