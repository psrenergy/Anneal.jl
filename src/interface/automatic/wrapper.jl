# ~*~ QUBOTools.jl ~*~ #
QUBOTools.backend(sampler::AutomaticSampler) = sampler.model

# ~*~ :: MathOptInterface :: ~*~ #
function MOI.empty!(sampler::AutomaticSampler)
    if !isnothing(sampler.model)
        empty!(QUBOTools.backend(sampler))
    end

    nothing
end

function MOI.is_empty(sampler::AutomaticSampler)
    return isnothing(sampler.model) || isempty(QUBOTools.backend(sampler))
end

function MOI.optimize!(sampler::AutomaticSampler)
    Anneal.sample!(sampler)

    nothing
end

function MOI.optimize!(sampler::AutomaticSampler, model::MOI.ModelLike)
    index_map = MOI.copy_to(sampler, model)

    MOI.optimize!(sampler)

    return (index_map, false)
end

function MOI.copy_to(sampler::AutomaticSampler{T}, model::MOI.ModelLike) where {T}
    sampler.model = build_qubo_model(T, model)::QUBOTools.StandardQUBOModel

    return MOIU.identity_index_map(model)
end

function Base.show(io::IO, sampler::AutomaticSampler)
    print(
        io,
        """
        Solver: $(MOI.get(sampler, MOI.SolverName()))

        with backend:
        $(QUBOTools.backend(sampler))
        """
    )
end

function MOI.get(sampler::AutomaticSampler, ps::MOI.PrimalStatus, ::VI)
    sampleset = QUBOTools.sampleset(sampler)::SampleSet

    ri = ps.result_index

    if isnothing(sampleset) || !(1 <= ri <= length(sampleset))
        return MOI.NO_SOLUTION
    else
        # ~ This status is also not very accurate, but
        #   all points are feasible in a general sense
        #   since these problems are unconstrained.
        return MOI.FEASIBLE_POINT
    end
end

function MOI.get(sampler::AutomaticSampler, ds::MOI.DualStatus, ::VI)
    sampleset = QUBOTools.sampleset(sampler)::SampleSet

    ri = ds.result_index

    if isnothing(sampleset) || !(1 <= ri <= length(sampleset))
        return MOI.NO_SOLUTION
    else
        # ~ This status is also not very accurate. Yes,
        #   all points are feasible in a general sense
        #   since the these problems are unconstrained.
        return MOI.FEASIBLE_POINT
    end
end

function MOI.get(sampler::AutomaticSampler, ::MOI.RawStatusString)
    sampleset = QUBOTools.sampleset(sampler)::SampleSet

    if isnothing(sampleset) || !haskey(samplset.metadata, "status")
        return ""
    else
        return sampleset.metadata["status"]::String
    end
end

function MOI.get(sampler::AutomaticSampler, ::MOI.ResultCount)
    sampleset = QUBOTools.sampleset(sampler)

    return length(sampleset)
end

function MOI.get(sampler::AutomaticSampler, ::MOI.TerminationStatus)
    sampleset = QUBOTools.sampleset(sampler)::SampleSet

    if isnothing(sampleset) || isempty(sampleset)
        return MOI.OPTIMIZE_NOT_CALLED
    else
        # ~ This one is a little bit tricky.
        # ~ It is nice if samplers implement this method in order to give
        #   more accurate information.
        return MOI.LOCALLY_SOLVED
    end
end

function MOI.get(sampler::AutomaticSampler{T}, ::MOI.ObjectiveSense) where {T}
    # ~ It is assumed that our backend represents a minimization problem
    #   by default.
    # ~ Scaling it with a negative value makes it a maximixation one.
    if QUBOTools.scale(sampler) >= zero(T)
        return MOI.MIN_SENSE
    else
        return MOI.MAX_SENSE
    end
end

function MOI.get(sampler::AutomaticSampler, ov::MOI.ObjectiveValue)
    sampleset = QUBOTools.sampleset(sampler)::SampleSet

    ri = ov.result_index

    if isnothing(sampleset) || isempty(sampleset)
        error("Invalid result index '$ri'; There are no solutions")
    elseif !(1 <= ri <= length(sampleset))
        error("Invalid result index '$ri'; There are $(length(sampleset)) solutions")
    end

    return sampleset[ri].value
end

function MOI.get(sampler::AutomaticSampler, ::MOI.SolveTimeSec)
    sampleset = QUBOTools.sampleset(sampler)::SampleSet

    if isnothing(sampleset) || !haskey(sampleset.metadata, "time")
        return NaN
    else
        time_data = sampleset.metadata["time"]

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
    sampleset = QUBOTools.sampleset(sampler)::SampleSet

    ri = vp.result_index

    if isnothing(sampleset) || isempty(sampleset)
        error("Invalid result index '$ri'; There are no solutions")
    elseif !(1 <= ri <= length(sampleset))
        error("Invalid result index '$ri'; There are $(length(sampleset)) solutions")
    end

    variable_map = QUBOTools.variable_map(sampler)

    if !haskey(variable_map, vi)
        error("Variable index '$vi' not in model")
    end

    value = sampleset[ri].state[variable_map[vi]]

    return convert(T, value)
end

function MOI.get(sampler::AutomaticSampler, ::MOI.NumberOfVariables)
    return QUBOTools.domain_size(sampler)
end

# ~*~ :: I/O :: ~*~ #
function Base.write(filename::String, sampler::AutomaticSampler)
    return write(
        filename,
        convert(
            QUBOTools.infer_model_type(filename),
            QUBOTools.backend(sampler),
        )
    )
end

function Base.read!(filename::String, sampler::AutomaticSampler)
    source = read(filename, QUBOTools.infer_model_type(filename))
    target = QUBOTools.backend(sampler)::QUBOTools.StandardQUBOModel

    copy!(target, source)

    nothing
end