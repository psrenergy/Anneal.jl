@testset "Sampling Structures" begin
    α = Anneal.SampleSet{Int, Float64}(
        Anneal.Sample{Int, Float64}.([
            ([0, 0], 1, 0.0),
            ([0, 1], 2, 1.0),
            ([1, 0], 3, 2.0),
        ])
    )

    β = Anneal.SampleSet{Int, Float64}(
        Anneal.Sample{Int, Float64}.([
        ([0, 1], 2, 1.0),
        ([1, 0], 3, 2.0),
        ([1, 1], 4, 3.0),
        ])
    )

    γ = Anneal.SampleSet{Int, Float64}(
        Anneal.Sample{Int, Float64}.([
        ([0, 0], 1, 0.0),
        ([0, 1], 4, 1.0),
        ([1, 0], 6, 2.0),
        ([1, 1], 4, 3.0),
        ])
    )

    @test merge(α, β) == γ
end