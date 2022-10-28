function test_exact_sampler()
    @testset "Exact Sampler" verbose = true begin
        ExactSampler.test(; examples=true)
    end
end