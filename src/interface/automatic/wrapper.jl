# ~*~ QUBOTools.jl ~*~ #
QUBOTools.backend(sampler::AutomaticSampler)  = sampler.target
QUBOTools.frontend(sampler::AutomaticSampler) = sampler.source

# ~*~ :: MathOptInterface :: ~*~ #
function MOI.empty!(sampler::AutomaticSampler)
    sampler.source = nothing
    sampler.target = nothing

    return sampler
end

function MOI.is_empty(sampler::AutomaticSampler)
    return isnothing(sampler.source) && isnothing(sampler.target)
end

function MOI.optimize!(sampler::AutomaticSampler)
    Anneal.sample!(sampler)

    return nothing
end

function MOI.copy_to(sampler::AutomaticSampler{T}, model::MOI.ModelLike) where {T}
    MOI.empty!(sampler)

    # Collect warm-start values
    for vi in MOI.get(model, MOI.ListOfVariableIndices())
        xi = MOI.get(model, MOI.VariablePrimalStart(), vi)

        MOI.set(sampler, MOI.VariablePrimalStart(), vi, xi)
    end

    sampler.source = Anneal.parse_qubo_model(T, model)::QUBOTools.Model
    sampler.target = QUBOTools.cast(
        Anneal.model_sense(sampler),
        Anneal.solver_sense(sampler),
        Anneal.model_domain(sampler),
        Anneal.solver_domain(sampler),
        sampler.source,
    )::QUBOTools.Model

    return MOIU.identity_index_map(model)
end

function Base.show(io::IO, sampler::AutomaticSampler)
    print(
        io,
        """
        Solver: $(MOI.get(sampler, MOI.SolverName()))

        with backend:
        $(QUBOTools.backend(sampler))
        """,
    )
end

function MOI.get(sampler::AutomaticSampler, ps::MOI.PrimalStatus, ::VI)
    sampleset = QUBOTools.sampleset(frontend(sampler))

    ri = ps.result_index

    if !(1 <= ri <= length(sampleset))
        return MOI.NO_SOLUTION
    else
        # ~ This status is also not very accurate, but
        #   all points are feasible in a general sense
        #   since these problems are unconstrained.
        return MOI.FEASIBLE_POINT
    end
end

function MOI.get(sampler::AutomaticSampler, ds::MOI.DualStatus, ::VI)
    sampleset = QUBOTools.sampleset(frontend(sampler))

    ri = ds.result_index

    if !(1 <= ri <= length(sampleset))
        return MOI.NO_SOLUTION
    else
        # ~ This status is also not very accurate. Yes,
        #   all points are feasible in a general sense
        #   since the these problems are unconstrained.
        return MOI.FEASIBLE_POINT
    end
end

function MOI.get(sampler::AutomaticSampler, ::MOI.RawStatusString)
    metadata = QUBOTools.metadata(QUBOTools.sampleset(frontend(sampler)))::Dict{String,Any}

    if !haskey(metadata, "status")
        return ""
    else
        return metadata["status"]::String
    end
end

function MOI.get(sampler::AutomaticSampler, ::MOI.ResultCount)
    return length(QUBOTools.sampleset(frontend(sampler)))
end

function MOI.get(sampler::AutomaticSampler, ::MOI.TerminationStatus)
    sampleset = QUBOTools.sampleset(frontend(sampler))

    if isempty(sampleset)
        return MOI.OPTIMIZE_NOT_CALLED
    else
        # ~ This one is a little bit tricky.
        # ~ It is nice if samplers implement this method in order to give
        #   more accurate information.
        return MOI.LOCALLY_SOLVED
    end
end

function MOI.get(sampler::AutomaticSampler{T}, ::MOI.ObjectiveSense) where {T}
    sense = QUBOTools.sense(frontend(sampler))

    if sense === QUBOTools.Min
        return MOI.MIN_SENSE
    else
        return MOI.MAX_SENSE
    end
end

function MOI.get(sampler::AutomaticSampler, ov::MOI.ObjectiveValue)
    sampleset = QUBOTools.sampleset(frontend(sampler))

    ri = ov.result_index

    if isempty(sampleset)
        error("Invalid result index '$ri'; There are no solutions")
    elseif !(1 <= ri <= length(sampleset))
        error("Invalid result index '$ri'; There are $(length(sampleset)) solutions")
    end

    if MOI.get(sampler, MOI.ObjectiveSense()) === MOI.MAX_SENSE
        ri = length(sampleset) - ri + 1
    end

    return QUBOTools.value(sampleset, ri)
end

function MOI.get(sampler::AutomaticSampler, ::MOI.SolveTimeSec)
    metadata = QUBOTools.metadata(QUBOTools.sampleset(frontend(sampler)))

    if !haskey(metadata, "time")
        return NaN
    else
        time_data = metadata["time"]

        if haskey(time_data, "sample")
            return time_data["sample"]::Float64
        elseif haskey(time_data, "total")
            return time_data["total"]::Float64
        else
            return NaN
        end
    end
end

function MOI.get(sampler::AutomaticSampler{T}, vp::MOI.VariablePrimal, vi::VI) where {T}
    sampleset = QUBOTools.sampleset(frontend(sampler))

    ri = vp.result_index

    if isempty(sampleset)
        error("Invalid result index '$ri'; There are no solutions")
    elseif !(1 <= ri <= length(sampleset))
        error("Invalid result index '$ri'; There are $(length(sampleset)) solutions")
    end

    variable_map = QUBOTools.variable_map(frontend(sampler))

    if !haskey(variable_map, vi)
        error("Variable index '$vi' not in model")
    end

    if MOI.get(sampler, MOI.ObjectiveSense()) === MOI.MAX_SENSE
        ri = length(sampleset) - ri + 1
    end

    value = QUBOTools.state(sampleset, ri, variable_map[vi])

    return convert(T, value)
end

function MOI.get(sampler::AutomaticSampler, ::MOI.NumberOfVariables)
    return QUBOTools.domain_size(frontend(sampler))
end

# ~*~ File IO: Base API ~*~ #
# function Base.write(
#     filename::AbstractString,
#     sampler::AutomaticSampler,
#     fmt::QUBOTools.AbstractFormat = QUBOTools.infer_format(filename),
# )
#     return QUBOTools.write_model(filename, frontend(sampler), fmt)
# end

# function Base.read!(
#     filename::AbstractString,
#     sampler::AutomaticSampler,
#     fmt::QUBOTools.AbstractFormat = QUBOTools.infer_format(filename),
# )
#     sampler.source = QUBOTools.read_model(filename, fmt)
#     sampler.target = QUBOTools.format(sampler, sampler.source)

#     return sampler
# end

MOI.supports(::AbstractSampler, ::MOI.VariablePrimalStart, ::MOI.VariableIndex) = true

function MOI.supports(sampler::AutomaticSampler, raw_attr::MOI.RawOptimizerAttribute)
    return haskey(sampler.attrs.rawattrs, raw_attr.name)
end
