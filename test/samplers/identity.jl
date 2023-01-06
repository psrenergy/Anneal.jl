function test_identiy_sampler()
    IdentitySampler.test(; examples = true) do model
        for x in JuMP.all_variables(model)
            JuMP.set_start_value(x, 1.0)
        end
    end

    return nothing
end