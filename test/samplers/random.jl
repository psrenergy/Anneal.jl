function test_random_sampler()
    @testset "Random Sampler" verbose = true begin
        RandomSampler.test(; examples = true)
    end
end