function anew_error(msg::String)
    error("Invalid usage of @anew: $msg")
end

@doc raw"""
```
    @anew(expr)

The `@anew` macro receives a `begin ... end` block with an attribute definition on each of the block's statements.

All attributes must be presented as an assignment to the default value of that attribute. To create a MathOptInterface optimizer attribute, an identifier must be present on the left hand side. If a solver-specific, raw attribute is desired, its name must be given as a string, e.g. between double quotes. In the special case where an attribute could be accessed in both ways, the identifier must be followed by the parenthesised raw attribute string. In any case, the attribute type can be specified typing the type assertion operator `::` followed by the type itself just before the equal sign.

For example, a list of the valid syntax variations for the *number of reads* attribute follows:
    - "num_reads" = 1_000
    - "num_reads"::Integer = 1_000
    - NumberOfReads = 1_000
    - NumberOfReads::Integer = 1_000
    - NumberOfReads("num_reads") = 1_000
    - NumberOfReads("num_reads")::Integer = 1_000
```
"""
macro anew(expr)
    expr = macroexpand(__module__, expr)

    if !(expr isa Expr && expr.head === :block)
        anew_error("missing begin ... end block")
    end

    attrs = Dict{Symbol,Any}[]

    for stmt in filter(line -> !(line isa LineNumberNode), expr.args)
        if !(stmt isa Expr && stmt.head === :(=))
            anew_error("no default value provided in '$stmt'")
        end

        item, init = stmt.args

        attr = if item isa Symbol
            Dict{Symbol,Any}(
                :raw => nothing,
                :attr => item,
                :init => init,
                :type => :Any,
            )
        elseif item isa String
            Dict{Symbol,Any}(
                :raw => item,
                :attr => nothing,
                :init => init,
                :type => :Any,
            )
        elseif item isa Expr && item.head === :(::)
            code, type = item.args

            if code isa Symbol
                Dict{Symbol,Any}(
                    :raw => nothing,
                    :attr => code,
                    :init => init,
                    :type => type,
                )
            elseif code isa String
                Dict{Symbol,Any}(
                    :raw => code,
                    :attr => nothing,
                    :init => init,
                    :type => type,
                )
            elseif code isa Expr && code.head === :call
                name, raw = code.args
                if name isa Symbol && raw isa String
                    Dict{Symbol,Any}(
                        :raw => raw,
                        :attr => name,
                        :init => init,
                        :type => type,
                    )
                else
                    anew_error("invalid attribute identifier '$name($raw)'")
                end
            else
                anew_error("invalid attribute identifier '$code'")
            end
        elseif item isa Expr && item.head === :call
            name, raw = item.args
            if name isa Symbol && raw isa String
                Dict{Symbol,Any}(
                    :raw => raw,
                    :attr => name,
                    :init => init,
                    :type => :Any,
                )
            else
                anew_error("invalid attribute identifier '$name($raw)'")
            end
        else
            anew_error("invalid attribute signature '$item'")
        end

        push!(attrs, attr)
    end

    blocks = Expr[]

    defaults = Expr[]

    for attr in attrs
        if !isnothing(attr[:attr])
            push!(blocks, quote
                struct $(attr[:attr]) <: AbstractSamplerAttribute end
            end)
        end

        push!(defaults, quote
            Dict{Symbol,Any}(
                :raw  => $(esc(attr[:raw])),
                :attr => $(esc(attr[:attr])),
                :init => $(esc(attr[:init])),
                :type => $(esc(attr[:type])),
            )
        end)
    end

    push!(blocks, quote
        mutable struct Optimizer{T} <: AbstractSampler{T}
            x::Dict{MOI.VariableIndex,Maybe{Int}}
            y::Dict{Int,MOI.VariableIndex}
            Q::Dict{Tuple{Int,Int},T}
            c::T
            n::Int

            sample_set::SampleSet{Int,T}
            moi::SamplerMOI{T}
            attrs::SamplerAttributes

            function Optimizer{T}() where {T}
                new{T}(
                    Dict{MOI.VariableIndex,Union{Int,Nothing}}(),
                    Dict{Int,MOI.VariableIndex}(),
                    Dict{Tuple{Int,Int},T}(),
                    zero(T),
                    0,
                    SampleSet{Int,T}(),
                    SamplerMOI{T}(),
                    SamplerAttributes(Dict{Symbol,Any}[$(defaults...)]),
                )
            end

            function Optimizer()
                Optimizer{Float64}()
            end
        end
    end)

    quote
        $(blocks...)
    end
end