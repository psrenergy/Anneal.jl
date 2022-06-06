function test_anneal(Optimizer::Type{<:AbstractSampler})
    @test hasmethod(MOI.get, (Optimizer, MOI.SolverName))
    @test hasmethod(MOI.get, (Optimizer, MOI.SolverVersion)) 
    @test hasmethod(MOI.get, (Optimizer, MOI.RawSolver))

    @test hasmethod(Anneal.sample, (Optimizer,))
end