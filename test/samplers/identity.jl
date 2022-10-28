function test_identiy_sampler()
    @testset "Identity Sampler" verbose = true begin
        IdentitySampler.test(; examples = false)
    end
end