struct SamplerMOIAttr{T}
    name::String
    silent::Bool
    time_limit_sec::Union{Float64,Nothing}
    number_of_threads::Int
    solve_time_sec::Float64
    termination_status::MOI.TerminationStatusCode
    primal_status::MOI.ResultStatusCode
    dual_status::MOI.ResultStatusCode
    raw_status_string::String
    variable_primal_start::Union{Dict{VI, Int}, Nothing}
    objective_sense::MOI.OptimizationSense

    function SamplerMOIAttr{T}(;
        name::String = "",
        silent::Bool = false,
        time_limit_sec::Union{Float64,Nothing} = nothing,
        number_of_threads::Int = Threads.nthreads(),
        solve_time_sec::Float64 = NaN,
        termination_status::MOI.TerminationStatusCode = MOI.OPTIMIZE_NOT_CALLED,
        primal_status::MOI.ResultStatusCode = MOI.NO_SOLUTION,
        dual_status::MOI.ResultStatusCode = MOI.NO_SOLUTION,
        raw_status_string::Union{String, Nothing} = nothing,
        variable_primal_start::Union{Dict{VI, Int}, Nothing} = nothing,
        objective_sense::MOI.OptimizationSense = MOI.MIN_SENSE,
        )

        new{T}(
            name,
            silent,
            time_limit_sec,
            number_of_threads,
            solve_time_sec,
            termination_status,
            primal_status,
            dual_status,
            raw_status_string,
            variable_primal_start,
            objective_sense,
        )
    end
end

function MOI.empty!(backend::SamplerBackend)
    empty!(backend.backend)
    empty!(backend.moiattr)

    nothing
end

function MOI.get(backend::SamplerBackend, ::MOI.NumberOfVariables)
    length(backend.backend.variable_map)
end