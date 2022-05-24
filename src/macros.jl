function anew_error(item::Any)
    error("Invalid usage of @anew: '$item'")
end

macro anew(expr)
    expr = macroexpand(__module__, expr)

    if !(expr isa Expr && expr.head === :block)
        anew_error(expr)
    end

    attrs = Symbol[]
    hints = Tuple{Symbol,Any,Any}[]

    for stmt in expr.args
        if stmt isa LineNumberNode
            continue
        elseif stmt isa Expr
            if stmt.head === :(::) && stmt.args[1] isa Symbol
                attr, type = stmt.args
                push!(attrs, (attr))
                push!(hints, (attr, hint, :Any))
                continue
            elseif stmt.head === :(=)
                stmt, hint = stmt.args
                if stmt isa Expr && stmt.head == :(::) && stmt.args[1] isa Symbol
                    attr, type = stmt.args
                    push!(attrs, (attr))
                    push!(hints, (attr, hint, type))
                    continue
                end
            end
        end

        anew_error(stmt)
    end

    quote
        $((:(struct $(attr) <: AbstractSamplerAttribute end) for attr in attrs)...)

        mutable struct Optimizer{T} <: AbstractSampler{T}
            x::Dict{MOI.VariableIndex,Maybe{Int}}
            y::Dict{Int,MOI.VariableIndex}
            Q::Dict{Tuple{Int,Int},T}
            c::T
            n::Int

            sample_set::SampleSet{Int,T}
            moi::SamplerMOI{T}
            settings::Dict{Any,Any}

            function Optimizer{T}(kws::Pair{<:MOI.AbstractOptimizerAttribute,<:Any}...) where {T}
                optimizer = new{T}(
                    Dict{MOI.VariableIndex,Union{Int,Nothing}}(),
                    Dict{Int,MOI.VariableIndex}(),
                    Dict{Tuple{Int,Int},T}(),
                    zero(T),
                    0,
                    SampleSet{Int,T}(),
                    SamplerMOI{T}(),
                    Dict{Any,Any}($((:($(esc(attr))() => convert($(esc(type)), $(esc(hint)))) for (attr, hint, type) in hints)...), kws...),
                )

                # Register raw optimizer attributes
                merge!(
                    optimizer.moi.raw_optimizer_attributes,
                    Dict{Symbol, Any}(nameof(typeof(attr)) => attr for attr in keys(optimizer.settings))
                )

                return optimizer
            end

            function Optimizer(kws::Pair{<:MOI.AbstractOptimizerAttribute,<:Any}...)
                return Optimizer{Float64}(kws...)
            end
        end
    end
end