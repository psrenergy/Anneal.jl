function test_exact_sampler()
    @testset "Exact Sampler" verbose = true begin
    Anneal.test(Anneal.ExactSampler.Optimizer)
    end
end