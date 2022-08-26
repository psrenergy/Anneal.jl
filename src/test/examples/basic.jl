function __test_basic_examples(optimizer::Type{<:AbstractSampler})
    Test.@testset "Basic" begin
        model = JuMP.Model(optimizer)

        Q = [-1 2 2
            2 -1 2
            2 2 -1]

        JuMP.@variable(model, x[1:3], Bin)
        JuMP.@objective(model, Min, x' * Q * x)

        JuMP.optimize!(model)

        Test.@test JuMP.result_count(model) == 8

        for i = 1:3
            xi = JuMP.value.(x; result=i)
            yi = JuMP.objective_value(model; result=i)

            Test.@test xi ≈ [0.0, 0.0, 1.0] || xi ≈ [0.0, 1.0, 0.0] || xi ≈ [1.0, 0.0, 0.0]
            Test.@test yi ≈ -1.0
        end

        let i = 4
            xi = JuMP.value.(x; result=i)
            yi = JuMP.objective_value(model; result=i)

            Test.@test xi ≈ [0.0, 0.0, 0.0]
            Test.@test yi ≈ 0.0
        end

        for i = 5:7
            xi = JuMP.value.(x; result=i)
            yi = JuMP.objective_value(model; result=i)

            Test.@test xi ≈ [0.0, 1.0, 1.0] || xi ≈ [1.0, 1.0, 0.0] || xi ≈ [1.0, 0.0, 1.0]
            Test.@test yi ≈ 2.0
        end

        let i = 8
            xi = JuMP.value.(x; result=i)
            yi = JuMP.objective_value(model; result=i)

            Test.@test xi ≈ [1.0, 1.0, 1.0]
            Test.@test yi ≈ 9.0
        end
    end

    nothing
end