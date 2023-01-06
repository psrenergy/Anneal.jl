function __test_anneal_interface(::Function, ::Type{S}) where {S<:AbstractSampler}
    Test.@testset "Anneal (Abstract)" verbose = true begin
        Test.@test hasmethod(Anneal.sample, (S,))
    end
end

function __test_anneal_interface(::Function, ::Type{S}) where {S<:AutomaticSampler}
    Test.@testset "Anneal (Automatic)" verbose = true begin
        Test.@test hasmethod(Anneal.sample, (S,))
        Test.@test hasmethod(Anneal.backend, (S,))
    end
end