function IdentitySampler.test_config!(model::JuMP.Model)
    for x in JuMP.all_variables(model)
        JuMP.set_start_value(x, 1.0)
    end

    return nothing
end

function IdentitySampler.test_config!(model::MOI.ModelLike)
    for xi in MOI.get(model, MOI.ListOfVariableIndices())
        MOI.set(model, MOI.VariablePrimalStart(), xi, 1.0)
    end
    
    return nothing
end

function test_identiy_sampler()
    IdentitySampler.test(; examples = true)
end