function __test_basic_examples(optimizer::Type{<:AbstractSampler})
    n = 3
    
    # ~ QUBO Matrix
    Q = [-1  2  2;2 -1  2;2  2 -1]

    # ~ Boolean States
    ↑ = 0.0
    ↓ = 1.0

    Test.@testset "Basic ~ Bool ~ Min" begin
        model = JuMP.Model(optimizer)

        JuMP.@variable(model, x[1:n], Bin)
        JuMP.@objective(model, Min, x' * Q * x)

        JuMP.optimize!(model)

        Test.@test JuMP.result_count(model) == 2^n # ~ 8

        for i = 1:3
            xi = JuMP.value.(x; result=i)
            yi = JuMP.objective_value(model; result=i)

            Test.@test xi ≈ [↑, ↑, ↓] || xi ≈ [↑, ↓, ↑] || xi ≈ [↓, ↑, ↑]
            Test.@test yi ≈ -1.0
        end

        let i = 4
            xi = JuMP.value.(x; result=i)
            yi = JuMP.objective_value(model; result=i)

            Test.@test xi ≈ [↑, ↑, ↑]
            Test.@test yi ≈ 0.0
        end

        for i = 5:7
            xi = JuMP.value.(x; result=i)
            yi = JuMP.objective_value(model; result=i)

            Test.@test xi ≈ [↑, ↓, ↓] || xi ≈ [↓, ↓, ↑] || xi ≈ [↓, ↑, ↓]
            Test.@test yi ≈ 2.0
        end

        let i = 8
            xi = JuMP.value.(x; result=i)
            yi = JuMP.objective_value(model; result=i)

            Test.@test xi ≈ [↓, ↓, ↓]
            Test.@test yi ≈ 9.0
        end
    end

    Test.@testset "Basic ~ Bool ~ Max" begin
        model = JuMP.Model(optimizer)

        JuMP.@variable(model, x[1:n], Bin)
        JuMP.@objective(model, Max, x' * Q * x)

        JuMP.optimize!(model)

        Test.@test JuMP.result_count(model) == 2^n # ~ 8

        let i = 1
            xi = JuMP.value.(x; result=i)
            yi = JuMP.objective_value(model; result=i)

            Test.@test xi ≈ [↓, ↓, ↓]
            Test.@test yi ≈ 9.0
        end

        for i = 2:4
            xi = JuMP.value.(x; result=i)
            yi = JuMP.objective_value(model; result=i)

            Test.@test xi ≈ [↑, ↓, ↓] || xi ≈ [↓, ↓, ↑] || xi ≈ [↓, ↑, ↓]
            Test.@test yi ≈ 2.0
        end

        let i = 5
            xi = JuMP.value.(x; result=i)
            yi = JuMP.objective_value(model; result=i)

            Test.@test xi ≈ [↑, ↑, ↑]
            Test.@test yi ≈ 0.0
        end

        for i = 6:8
            xi = JuMP.value.(x; result=i)
            yi = JuMP.objective_value(model; result=i)

            Test.@test xi ≈ [↑, ↑, ↓] || xi ≈ [↑, ↓, ↑] || xi ≈ [↓, ↑, ↑]
            Test.@test yi ≈ -1.0
        end
    end

    # ~ Ising Hamiltonian
    J = [0 4 4; 0 0 4; 0 0 0]
    h = [-1;-1;-1]

    # ~ Spin states
    ↑ = -1.0
    ↓ =  1.0

    Test.@testset "Basic ~ Spin ~ Min" begin
        model = JuMP.Model(optimizer)

        JuMP.@variable(model, s[1:n], Anneal.Spin)
        JuMP.@objective(model, Min, s' * J * s + h' * s)

        JuMP.optimize!(model)

        Test.@test JuMP.result_count(model) == 2^n # ~ 8

        for i = 1:3
            si = JuMP.value.(s; result=i)
            Hi = JuMP.objective_value(model; result=i)

            Test.@test si ≈ [↓, ↓, ↑] || si ≈ [↓, ↑, ↓] || si ≈ [↑, ↓, ↓]
            Test.@test Hi ≈ -5.0
        end

        for i = 4:6
            si = JuMP.value.(s; result=i)
            Hi = JuMP.objective_value(model; result=i)

            Test.@test si ≈ [↑, ↑, ↓] || si ≈ [↑, ↓, ↑] || si ≈ [↓, ↑, ↑]
            Test.@test Hi ≈ -3.0
        end

        let i = 7
            si = JuMP.value.(s; result=i)
            Hi = JuMP.objective_value(model; result=i)

            Test.@test si ≈ [↓, ↓, ↓]
            Test.@test Hi ≈ 9.0
        end

        let i = 8
            si = JuMP.value.(s; result=i)
            Hi = JuMP.objective_value(model; result=i)

            Test.@test si ≈ [↑, ↑, ↑]
            Test.@test Hi ≈ 15.0
        end
    end

    Test.@testset "Basic ~ Spin ~ Max" begin
        model = JuMP.Model(optimizer)

        JuMP.@variable(model, s[1:n], Anneal.Spin)
        JuMP.@objective(model, Max, s' * J * s + h' * s)

        JuMP.optimize!(model)

        Test.@test JuMP.result_count(model) == 2^n # ~ 8

        let i = 1
            si = JuMP.value.(s; result=i)
            Hi = JuMP.objective_value(model; result=i)

            Test.@test si ≈ [↑, ↑, ↑]
            Test.@test Hi ≈ 15.0
        end

        let i = 2
            si = JuMP.value.(s; result=i)
            Hi = JuMP.objective_value(model; result=i)

            Test.@test si ≈ [↓, ↓, ↓]
            Test.@test Hi ≈ 9.0
        end

        for i = 3:5
            si = JuMP.value.(s; result=i)
            Hi = JuMP.objective_value(model; result=i)

            Test.@test si ≈ [↑, ↑, ↓] || si ≈ [↑, ↓, ↑] || si ≈ [↓, ↑, ↑]
            Test.@test Hi ≈ -3.0
        end

        for i = 6:8
            si = JuMP.value.(s; result=i)
            Hi = JuMP.objective_value(model; result=i)

            Test.@test si ≈ [↓, ↓, ↑] || si ≈ [↓, ↑, ↓] || si ≈ [↑, ↓, ↓]
            Test.@test Hi ≈ -5.0
        end
    end

    nothing
end