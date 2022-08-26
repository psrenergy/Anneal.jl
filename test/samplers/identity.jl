function test_identiy_sampler()
    @testset "Identity Sampler" verbose = true begin
    Anneal.test(Anneal.IdentitySampler.Optimizer)
    end
end