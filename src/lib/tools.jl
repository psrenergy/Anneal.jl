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