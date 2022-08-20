function QUBOTools.StandardBQPModel{T}(model::MOI.ModelLike) where {T}
    if !isqubolike(model)
        # Throws default massage (ToQUBO.jl advertisement 😎)
        throw(QUBOError(nothing))
    end

    x = Dict{VI,Int}(xᵢ => i for (i, xᵢ) in enumerate(MOI.get(model, MOI.ListOfVariableIndices())))
    L = Dict{Int,T}()
    Q = Dict{Tuple{Int,Int},T}()
    c = zero(T)

    F = MOI.get(model, MOI.ObjectiveFunctionType())
    f = MOI.get(model, MOI.ObjectiveFunction{F}())

    if F <: VI
        Q[f, f] = one(T)
    elseif F <: SAF
        for a in f.terms
            cᵢ = a.coefficient
            xᵢ = a.variable

            i = x[xᵢ]

            L[i] = get(L, i, zero(T)) + cᵢ
        end

        c += f.constant
    elseif F <: SQF
        for a in f.affine_terms
            cᵢ = a.coefficient
            xᵢ = a.variable

            i = x[xᵢ]

            L[i] = get(L, i, zero(T)) + cᵢ
        end

        for a in f.quadratic_terms
            cᵢⱼ = a.coefficient
            xᵢ = a.variable_1
            xⱼ = a.variable_2

            i = x[xᵢ]
            j = x[xⱼ]

            if i > j
                # Not sure if this even happens.
                i, j = j, i
            end

            if i == j
                # MOI assumes 
                #   SQF := ½ x Q x + ax + b
                # ∴ the main diagonal is doubled
                L[i] = get(L, i, zero(T)) + cᵢⱼ / 2
            else
                Q[i, j] = get(Q, (i, j), zero(T)) + cᵢⱼ
            end
        end

        c += f.constant
    end

    if MOI.get(model, MOI.ObjectiveSense()) === MOI.MAX_SENSE
        L = Dict{Int,T}(k => -Lₖ for (k, Lₖ) in L)
        Q = Dict{Tuple{Int,Int},T}(k => -Qₖ for (k, Qₖ) in Q)
        c = -c
    end

    QUBOTools.StandardBQPModel{VI,Int,T,QUBOTools.BoolDomain}(
        L,
        Q,
        x;
        offset=c
    )
end

function QUBOTools.backend(::X) where {X<:Sampler}
    error("'QUBOTools.backend' not implemented for '$X'")
end

# ~*~ :: MathOptInterface :: ~*~ #
function MOI.empty!(sampler::Sampler)
    empty!(QUBOTools.backend(sampler))
end

function MOI.is_empty(sampler::Sampler)
    isempty(QUBOTools.backend(sampler))
end

function MOI.optimize!(sampler::Sampler)
    Anneal.sample!(sampler)

    nothing
end

function MOI.optimize!(sampler::Sampler, model::MOI.ModelLike)
    index_map = MOI.copy_to(sampler, model)
    
    MOI.optimize!(sampler)

    return (index_map, false)
end

function Base.show(io::IO, sampler::Sampler)
    print(
        io,
        """
        $(MOI.get(sampler, MOI.SolverName())) Binary Quadratic Sampler

        with backend:
        """
    )
    print(io, QUBOTools.backend(sampler))
end

function MOI.copy_to(sampler::Sampler{T}, model::MOI.ModelLike) where {T}
    copy!(
        QUBOTools.backend(sampler),
        QUBOTools.StandardBQPModel{T}(model),
    )

    return MOIU.identity_index_map(model)
end

function MOI.get(sampler::Sampler, ps::MOI.PrimalStatus, ::VI)
    sampleset = QUBOTools.sampleset(sampler)

    ri = ps.result_index

    if isnothing(sampleset) || !(1 <= ri <= length(sampleset))
        MOI.NO_SOLUTION
    else
        # ~ This status is also not very accurate. Yes,
        #   all points are feasible in a general sense
        #   since the these problems are unconstrained.
        MOI.FEASIBLE_POINT
    end
end

function MOI.get(sampler::Sampler, ds::MOI.DualStatus, ::VI)
    sampleset = QUBOTools.sampleset(sampler)

    ri = ds.result_index

    if isnothing(sampleset) || !(1 <= ri <= length(sampleset))
        MOI.NO_SOLUTION
    else
        # ~ This status is also not very accurate. Yes,
        #   all points are feasible in a general sense
        #   since the these problems are unconstrained.
        MOI.FEASIBLE_POINT
    end
end

function MOI.get(sampler::Sampler, ::MOI.RawStatusString)
    sampleset = QUBOTools.sampleset(sampler)

    if isnothing(sampleset) || !haskey(samplset.metadata, "status")
        ""
    else
        sampleset.metadata["status"]::String
    end
end

function MOI.get(sampler::Sampler, ::MOI.ResultCount)
    length(QUBOTools.sampleset(sampler))
end

function MOI.get(sampler::Sampler, ::MOI.TerminationStatus)
    sampleset = QUBOTools.sampleset(sampler)

    if isnothing(sampleset) || isempty(sampleset)
        MOI.OPTIMIZE_NOT_CALLED
    else
        # ~ This one is a little bit tricky.
        # ~ It is nice if samplers implement this method
        #   in order to give more accurate information.
        MOI.LOCALLY_SOLVED
    end
end

function MOI.get(sampler::Sampler, ov::MOI.ObjectiveValue)
    sampleset = QUBOTools.sampleset(sampler)

    ri = ov.result_index

    if isnothing(sampleset) || isempty(sampleset)
        error("Invalid result index '$ri'; There are no solutions")
    elseif !(1 <= ri <= length(sampleset))
        error("Invalid result index '$ri'; There are $(length(sampleset)) solutions")
    end

    return sampleset[ri].value
end

function MOI.get(sampler::Sampler, ::MOI.SolveTimeSec)
    sampleset = QUBOTools.sampleset(sampler)

    if isnothing(sampleset) || !haskey(sampleset.metadata, "time")
        0.0
    else
        time_data = sampleset.metadata["time"]

        if haskey(time_data, "sample")
            time_data["sample"]::Float64
        elseif haskey(time_data, "total")
            time_data["total"]::Float64
        else
            0.0
        end
    end
end

function MOI.get(sampler::Sampler, vp::MOI.VariablePrimal, vi::VI)
    sampleset = QUBOTools.sampleset(sampler)

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

    return sampleset[ri].state[variable_map[vi]]
end

function MOI.get(sampler::Sampler, ::MOI.NumberOfVariables)
    QUBOTools.domain_size(sampler)
end

# ~*~ :: I/O :: ~*~ #
function Base.write(filename::String, sampler::Sampler)
    write(
        filename,
        convert(
            QUBOTools.infer_model_type(filename),
            QUBOTools.backend(sampler),
        )
    )

    nothing
end

function Base.read!(filename::String, sampler::Sampler)
    copy!(
        QUBOTools.backend(sampler),
        read(
            filename,
            QUBOTools.infer_model_type(filename)
        )
    )

    nothing
end