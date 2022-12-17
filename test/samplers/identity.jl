function Anneal.test_config!(::IdentitySampler.Optimizer, model::JuMP.Model)
    for x in JuMP.all_variables(model)
        JuMP.set_start_value(x, 1.0)
    end

    return nothing
end

function test_identiy_sampler()
    @testset "Identity Sampler" verbose = true begin
        IdentitySampler.test(; examples = false)
    end
end