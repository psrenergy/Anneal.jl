@doc raw"""
    isqubo(model::MOI.ModelLike)
    
Tells if a given model is ready to be interpreted as a QUBO model.

For it to be true, a few conditions must be met:
 1. All variables must be binary (`MOI.VariableIndex ∈ MOI.ZeroOne`)
 2. No other constraints are allowed
 3. The objective function must be of type `MOI.ScalarQuadraticFunction`, `MOI.ScalarAffineFunction` or `MOI.VariableIndex`
 4. The objective sense must be either `MOI.MIN_SENSE` or `MOI.MAX_SENSE`
""" function isqubolike end

function isqubolike(model::MOI.ModelLike)
    F = MOI.get(model, MOI.ObjectiveFunctionType())

    if !(F <: Union{SQF,SAF,VI})
        return false
    end

    S = MOI.get(model, MOI.ObjectiveSense())

    if !(S === MOI.MAX_SENSE || S === MOI.MIN_SENSE)
        return false
    end

    # List of Variables
    v = Set{VI}(MOI.get(model, MOI.ListOfVariableIndices()))

    for (F, S) in MOI.get(model, MOI.ListOfConstraintTypesPresent())
        if (F === VI && S === MOI.ZeroOne)
            for cᵢ in MOI.get(model, MOI.ListOfConstraintIndices{F,S}())
                vᵢ = MOI.get(model, MOI.ConstraintFunction(), cᵢ)

                # Account for variable as binary
                delete!(v, vᵢ)
            end
        else
            # Non VariableIndex-in-ZeroOne Constraint
            return false
        end
    end

    if !isempty(v)
        # Some variable is not covered by binary constraints
        return false
    end

    return true
end

function BQPIO.StandardBQPModel{T}(model::MOI.ModelLike) where {T}
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
                # so the main diagonal is doubled.
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

    BQPIO.StandardBQPModel{VI,Int,T,BQPIO.BoolDomain}(
        L,
        Q,
        x;
        offset=c,
    )
end