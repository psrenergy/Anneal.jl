@doc raw"""
    build_qubo_model(model::MOI.ModelLike)
    build_qubo_model(T::Type, model::MOI.ModelLike)

If the given model is ready to be interpreted as a QUBO model, then returns the corresponding `QUBOTools.StandardQUBOModel`.

A few conditions must be met:
    1. All variables must be binary of a single kind (`VI ∈ MOI.ZeroOne` or `VI ∈ Anneal.Spin`)
    2. No other constraints are allowed
    3. The objective function must be of type `MOI.ScalarQuadraticFunction`, `MOI.ScalarAffineFunction` or `MOI.VariableIndex`
    4. The objective sense must be either `MOI.MIN_SENSE` or `MOI.MAX_SENSE`
""" function build_qubo_model end

function build_qubo_model(model::MOI.ModelLike)
    return build_qubo_model(Float64, model)
end

function __is_quadratic(model::MOI.ModelLike)
    return MOI.get(model, MOI.ObjectiveFunctionType()) <: Union{SQF,SAF,VI}
end

function __is_unconstrained(model::MOI.ModelLike)
    for (F, S) in MOI.get(model, MOI.ListOfConstraintTypesPresent())
        if !(F === VI && (S === MOI.ZeroOne || S === Spin))
            return false
        end
    end

    return true
end

function __is_optimization(model::MOI.ModelLike)
    S = MOI.get(model, MOI.ObjectiveSense())

    return (S === MOI.MAX_SENSE || S === MOI.MIN_SENSE)
end

function __extract_qubo_model(::Type{T}, Ω::Set{VI}, model::MOI.ModelLike, ::QUBOTools.BoolDomain) where {T}
    L = Dict{VI,T}(xᵢ => zero(T) for xᵢ ∈ Ω)
    Q = Dict{Tuple{VI,VI},T}()

    offset = zero(T)

    F = MOI.get(model, MOI.ObjectiveFunctionType())
    f = MOI.get(model, MOI.ObjectiveFunction{F}())

    if F <: VI
        L[f] += one(T)
    elseif F <: SAF
        for a in f.terms
            cᵢ = a.coefficient
            xᵢ = a.variable

            L[xᵢ] += cᵢ
        end

        offset += f.constant
    elseif F <: SQF
        for a in f.affine_terms
            cᵢ = a.coefficient
            xᵢ = a.variable

            L[xᵢ] += cᵢ
        end

        for a in f.quadratic_terms
            cᵢⱼ = a.coefficient
            xᵢ = a.variable_1
            xⱼ = a.variable_2

            if xᵢ == xⱼ
                # ~ MOI assumes 
                #       SQF := ½ x' Q x + a' x + β
                #   Thus, the main diagonal is doubled from our point of view
                # ~ Also, in this case, x² = x
                L[xᵢ] += cᵢⱼ / 2
            else
                Q[xᵢ, xⱼ] = get(Q, (xᵢ, xⱼ), zero(T)) + cᵢⱼ
            end
        end

        offset += f.constant
    end

    return (L, Q, offset)
end

function __extract_qubo_model(::Type{T}, Ω::Set{VI}, model::MOI.ModelLike, ::QUBOTools.SpinDomain) where {T}
    L = Dict{VI,T}(xᵢ => zero(T) for xᵢ ∈ Ω)
    Q = Dict{Tuple{VI,VI},T}()

    offset = zero(T)

    F = MOI.get(model, MOI.ObjectiveFunctionType())
    f = MOI.get(model, MOI.ObjectiveFunction{F}())

    if F <: VI
        L[f] += one(T)
    elseif F <: SAF
        for a in f.terms
            cᵢ = a.coefficient
            xᵢ = a.variable

            L[xᵢ] += cᵢ
        end

        offset += f.constant
    elseif F <: SQF
        for a in f.affine_terms
            cᵢ = a.coefficient
            xᵢ = a.variable

            L[xᵢ] += cᵢ
        end

        for a in f.quadratic_terms
            cᵢⱼ = a.coefficient
            xᵢ = a.variable_1
            xⱼ = a.variable_2

            if xᵢ == xⱼ
                # ~ MOI assumes 
                #       SQF := ½ s' J s + h' s + β
                #   Thus, the main diagonal is doubled from our point of view
                # ~ Also, in this case, s² = 1
                offset += cᵢⱼ / 2
            else
                Q[xᵢ, xⱼ] = get(Q, (xᵢ, xⱼ), zero(T)) + cᵢⱼ
            end
        end

        offset += f.constant
    end

    return (L, Q, offset)
end


function build_qubo_model(T::Type, model::MOI.ModelLike)
    # ~*~ Check for emptiness ~*~ #
    if MOI.is_empty(model)
        @warn "The given model is empty"
        return QUBOTools.StandardQUBOModel{VI,Int,T,QUBOTools.BoolDomain}()
    end

    # ~*~ Validate Model ~*~ #
    flag = false

    if !__is_quadratic(model)
        @warn "The given model's objective function is not a quadratic or linear polynomial"
        flag = true
    end

    if !__is_optimization(model)
        @warn "The given model lacks an optimization sense"
        flag = true
    end

    if !__is_unconstrained(model)
        @warn "The given model is not unconstrained"
        flag = true
    end

    Ω = Set{VI}(MOI.get(model, MOI.ListOfVariableIndices()))
    𝔹 = Set{VI}(
        MOI.get(model, MOI.ConstraintFunction(), cᵢ)
        for cᵢ in MOI.get(model, MOI.ListOfConstraintIndices{VI,MOI.ZeroOne}())
    )
    𝕊 = Set{VI}(
        MOI.get(model, MOI.ConstraintFunction(), cᵢ)
        for cᵢ in MOI.get(model, MOI.ListOfConstraintIndices{VI,Spin}())
    )

    # ~*~ Retrieve Variable Domain ~*~ #
    # Assuming:
    # - 𝕊, 𝔹 ⊆ Ω
    D = if !isempty(𝕊) && !isempty(𝔹)
        @error "The given model contains both boolean and spin variables"
        flag = true

        nothing
    elseif isempty(𝕊) # QUBO model?
        if 𝔹 != Ω
            @error "Not all variables in the given model are boolean"
            flag = true

            nothing
        else
            QUBOTools.BoolDomain
        end
    elseif isempty(𝔹) # Ising model?
        if 𝕊 != Ω
            @error "Not all variables in the given model are spin"
            flag = true

            nothing
        else
            QUBOTools.SpinDomain
        end
    end

    if flag
        # ~ Throws default message
        #   (ToQUBO.jl advertisement 😎)
        throw(QUBOError(nothing))
    end

    # ~*~ Retrieve Model ~*~ #
    L, Q, offset = __extract_qubo_model(T, Ω, model, D())

    # ~*~ Objective Sense ~*~ #
    sense = MOI.get(model, MOI.ObjectiveSense())

    scale = one(T) # ~ Assuming MIN_SENSE
    
    # ~*~ Invert Problem Sense ~*~ #
    if sense === MOI.MAX_SENSE
        L = Dict{VI,T}(i => -l for (i, l) in L)
        Q = Dict{Tuple{VI,VI},T}(ij => -q for (ij, q) in Q)
        scale = -scale
        offset = -offset
    end

    # ~*~ Return Model ~*~ #
    return QUBOTools.StandardQUBOModel{VI,Int,T,D}(
        L,
        Q;
        scale=scale,
        offset=offset
    )
end