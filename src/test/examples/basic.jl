function __test_basic_examples(config!::Function, sampler::Type{S}) where {S<:AbstractSampler}
    Test.@testset "⊚ Basic ⊚" verbose = true begin
        n = 3

        # ~ QUBO Matrix
        Q = [
            -1  2  2
             2 -1  2
             2  2 -1
        ]

        # ~ Boolean States
        ↑, ↓ = 0, 1

        Test.@testset "▷ Bool ⋄ Min" begin
            # -*- Build Model -*- #
            model = JuMP.Model(sampler)

            JuMP.@variable(model, x[1:n], Bin)
            JuMP.@objective(model, Min, x' * Q * x)

            # -* Configure Model *- #
            config!(model)

            # -*- Run -*- #
            JuMP.optimize!(model)

            Test.@test JuMP.result_count(model) > 0

            for i = 1:JuMP.result_count(model)
                xi = JuMP.value.(x; result = i)
                yi = JuMP.objective_value(model; result = i)

                if xi ≈ [↑, ↑, ↓] || xi ≈ [↑, ↓, ↑] || xi ≈ [↓, ↑, ↑]
                    Test.@test yi ≈ -1.0
                elseif xi ≈ [↑, ↑, ↑]
                    Test.@test yi ≈ 0.0
                elseif xi ≈ [↑, ↓, ↓] || xi ≈ [↓, ↓, ↑] || xi ≈ [↓, ↑, ↓]
                    Test.@test yi ≈ 2.0
                elseif xi ≈ [↓, ↓, ↓]
                    Test.@test yi ≈ 9.0
                else
                    Test.@test false
                end
            end
        end

        Test.@testset "▷ Bool ⋄ Max" begin
            # -*- Build Model -*- #
            model = JuMP.Model(sampler)
            
            JuMP.@variable(model, x[1:n], Bin)
            JuMP.@objective(model, Max, x' * Q * x)

            # -* Configure Model *- #
            config!(model)

            # -*- Run -*- #
            JuMP.optimize!(model)

            Test.@test JuMP.result_count(model) > 0

            for i = 1:JuMP.result_count(model)
                xi = JuMP.value.(x; result = i)
                yi = JuMP.objective_value(model; result = i)

                if xi ≈ [↓, ↓, ↓]
                    Test.@test yi ≈ 9.0
                elseif xi ≈ [↑, ↓, ↓] || xi ≈ [↓, ↓, ↑] || xi ≈ [↓, ↑, ↓]
                    Test.@test yi ≈ 2.0
                elseif xi ≈ [↑, ↑, ↑]
                    Test.@test yi ≈ 0.0
                elseif xi ≈ [↑, ↑, ↓] || xi ≈ [↑, ↓, ↑] || xi ≈ [↓, ↑, ↑]
                    Test.@test yi ≈ -1.0
                else
                    Test.@test false
                end
            end
        end

        # ~ Ising Hamiltonian
        J = [0 4 4; 0 0 4; 0 0 0]
        h = [-1; -1; -1]

        # ~ Spin states
        ↑, ↓ = -1, 1

        Test.@testset "▷ Spin ⋄ Min" begin
            # -*- Build Model -*- #
            model = JuMP.Model(sampler)

            JuMP.@variable(model, s[1:n], Anneal.Spin)
            JuMP.@objective(model, Min, s' * J * s + h' * s)

            # -* Configure Model *- #
            config!(model)

            # -*- Run -*- #
            JuMP.optimize!(model)

            Test.@test JuMP.result_count(model) > 0

            for i = 1:JuMP.result_count(model)
                si = JuMP.value.(s; result = i)
                Hi = JuMP.objective_value(model; result = i)

                if si ≈ [↓, ↓, ↑] || si ≈ [↓, ↑, ↓] || si ≈ [↑, ↓, ↓]
                    Test.@test Hi ≈ -5.0
                elseif si ≈ [↑, ↑, ↓] || si ≈ [↑, ↓, ↑] || si ≈ [↓, ↑, ↑]
                    Test.@test Hi ≈ -3.0
                elseif si ≈ [↓, ↓, ↓]
                    Test.@test Hi ≈ 9.0
                elseif si ≈ [↑, ↑, ↑]
                    Test.@test Hi ≈ 15.0
                else
                    Test.@test false
                end
            end
        end

        Test.@testset "▷ Spin ⋄ Max" begin
            # -*- Build Model -*- #
            model = JuMP.Model(sampler)

            JuMP.@variable(model, s[1:n], Anneal.Spin)
            JuMP.@objective(model, Max, s' * J * s + h' * s)

            # -* Configure Model *- #
            config!(model)

            # -*- Run -*- #
            JuMP.optimize!(model)

            Test.@test JuMP.result_count(model) > 0

            for i = 1:JuMP.result_count(model)
                si = JuMP.value.(s; result = i)
                Hi = JuMP.objective_value(model; result = i)

                if si ≈ [↑, ↑, ↑]
                    Test.@test Hi ≈ 15.0
                elseif si ≈ [↓, ↓, ↓]
                    Test.@test Hi ≈ 9.0
                elseif si ≈ [↑, ↑, ↓] || si ≈ [↑, ↓, ↑] || si ≈ [↓, ↑, ↑]
                    Test.@test Hi ≈ -3.0
                elseif si ≈ [↓, ↓, ↑] || si ≈ [↓, ↑, ↓] || si ≈ [↑, ↓, ↓]
                    Test.@test Hi ≈ -5.0
                else
                    Test.@test false
                end
            end
        end
    end

    return nothing
end