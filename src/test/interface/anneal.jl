function __test_anneal_interface(::Type{S}) where {S<:AbstractSampler}
    Test.@testset "Anneal" verbose = true begin
        Test.@test hasmethod(Anneal.sample, (S,))
    end
end