function test_random_sampler()
    @testset "Random Sampler" verbose = true begin
    Anneal.test(Anneal.RandomSampler.Optimizer)
    end
end