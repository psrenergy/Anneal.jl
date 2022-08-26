const __ANEW_REGISTRY = Set{Module}()

const __ANEW_DEFAULT_PARAMS() = Dict{Symbol,Any}(
    :name => "Binary Quadratic Sampler",
    :version => v"1.0.0",
    :domain => :bool,
    :attributes => Dict{Symbol, Any}[],
)

function __anew_error(msg::String)
    error("Invalid usage of @anew: $msg")
end

function __anew_parse_id(id::Symbol)
    if Base.isidentifier(id)
        return id
    else
        __anew_error("sampler identifier '$id' is not a valid one")
    end
end

function __anew_parse_id()
    return :Optimizer
end

function __anew_parse_param(::Val{X}, ::Any) where {X}
    __anew_error("invalid parameter '$X', valid options are: 'name', 'version', 'domain', 'attributes'")
end

function __anew_parse_param(::Val{:name}, value)
    if value isa String
        return value
    else
        __anew_error("parameter 'name' must be a 'String'")
    end
end

function __anew_parse_param(::Val{:version}, value)
    if value isa VersionNumber
        return value
    else
        __anew_error("parameter 'name' must be a 'VersionNumber'")
    end
end

function __anew_parse_param(::Val{:domain}, value)
    value = if value isa QuoteNode
        value.value
    elseif value isa String
        Symbol(value)
    else
        value
    end

    if value isa Symbol && (value === :bool || value === :spin)
        return value
    else
        __anew_error("parameter 'domain' must be either ':bool' or ':spin', not '$value'")
    end
end

function __anew_parse_param(::Val{:attributes}, value)
    if value isa Expr && value.head === :block
        return Dict{Symbol, Any}[
            attr for attr in __anew_parse_attr.(value.args)
            if !isnothing(attr)
        ]
    else
        __anew_error("parameter 'attributes' must be a `begin...end` block")
    end
end

function __anew_parse_attr(stmt)
    if stmt isa LineNumberNode
        return nothing
    elseif !(stmt isa Expr && stmt.head === :(=))
        __anew_error("each attribute definition must be an assignment to its default value")
    end

    attr, default = stmt.args

    type    = nothing
    optattr = nothing
    rawattr = nothing

    if attr isa Symbol # ~ MOI attribute only
        if !(Base.isidentifier(attr))
            anew_error("attribute identifier '$attr' is not a valid one")
        end

        optattr = attr
    elseif attr isa String # ~ Raw attribute only
        rawattr = attr
    elseif attr isa Expr && attr.head === :(::)
        attr, type = attr.args

        if attr isa Symbol
            if !(Base.isidentifier(attr))
                __anew_error("attribute identifier '$attr' is not a valid one")
            end

            optattr = attr
        elseif attr isa String
            rawattr = attr
        elseif attr isa Expr && (attr.head === :ref || item.head === :call)
            optattr, rawattr = attr.args

            if optattr isa Symbol && rawattr isa String
                if !(Base.isidentifier(optattr))
                    __anew_error("attribute identifier '$optattr' is not a valid one")
                end
            else
                __anew_error("invalid attribute identifier '$name($raw)'")
            end
        else
            __anew_error("invalid attribute identifier '$attr'")
        end
    elseif attr isa Expr && (attr.head === :ref || attr.head === :call)
        optattr, rawattr = attr.args

        if optattr isa Symbol && rawattr isa String
            if !(Base.isidentifier(optattr))
                __anew_error("attribute identifier '$optattr' is not a valid one")
            end
        else
            __anew_error("invalid attribute identifier '$name[$rawattr]'")
        end
    else
        __anew_error("invalid attribute signature '$attr'")
    end

    return Dict{Symbol, Any}(
        :type    => type,
        :default => default,
        :optattr => optattr,
        :rawattr => rawattr,
    )
end

function __anew_parse_params(block::Expr)
    @assert block.head === :block

    params = __ANEW_DEFAULT_PARAMS()

    for item in block.args
        if item isa LineNumberNode
            continue
        elseif item isa Expr && item.head === :(=)
            param, value = item.args

            if param isa Symbol && Base.isidentifier(param)
                params[param] = __anew_parse_param(Val(param), value)
            else
                __anew_error("sampler parameter key must be a valid identifier")
            end
        else
            __anew_error("sampler parameters must be `key = value` pairs")
        end
    end

    return params
end

function __anew_parse_params()
    __ANEW_DEFAULT_PARAMS()
end

function __anew_parse(args...)
    __anew_error("macro takes exactly one or two arguments")
end

function __anew_parse(expr)
    if expr isa Symbol # Name
        return (
            __anew_parse_id(expr),
            __anew_parse_params(),
        )
    elseif (expr isa Expr && expr.head === :block)
        return (
            __anew_parse_id(),
            __anew_parse_params(expr),
        )
    else
        __anew_error("single argument must be either an identifier or a `begin...end` block")
    end
end

function __anew_parse()
    return (__anew_parse_id(), __anew_parse_params())
end

function __anew_parse(id, block)
    id = if !(id isa Symbol)
        __anew_error("first argument must be an identifier")
    else
        __anew_parse_id(id)
    end

    params = if !(block isa Expr && block.head === :block)
        __anew_error("second argument must be a `begin...end` block")
    else
        __anew_parse_params(block)
    end

    return (id, params)
end

function __anew_attr(attr)
    type    = attr[:type]
    default = attr[:default]
    optattr = attr[:optattr]
    rawattr = attr[:rawattr]

    if !isnothing(optattr) && !isnothing(rawattr)
        return quote
            struct $(esc(optattr)) <: Anneal.AbstractSamplerAttribute end

            push!(
                __SAMPLER_ATTRIBUTES,
                Anneal.SamplerAttribute{$(esc(type))}(
                    $(esc(default));
                    rawattr=$(esc(rawattr)),
                    optattr=$(esc(optattr))()
                )
            )
        end
    elseif !isnothing(optattr)
        return quote
            struct $(esc(optattr)) <: Anneal.AbstractSamplerAttribute end

            push!(
                __SAMPLER_ATTRIBUTES,
                Anneal.SamplerAttribute{$(esc(type))}(
                    $(esc(default));
                    optattr=$(esc(optattr))()
                )
            )
        end
    elseif !isnothing(rawattr)
        return quote
            push!(
                __SAMPLER_ATTRIBUTES,
                Anneal.SamplerAttribute{$(esc(type))}(
                    $(esc(default));
                    rawattr=$(esc(rawattr))
                )
            )
        end
    else
        error("Looks like some assertions were skipped. Did you turn any optimizations on?")
    end
end

@doc raw"""
    @anew(expr)

The `@anew` macro receives a `begin ... end` block with an attribute definition on each of the block's statements.

All attributes must be presented as an assignment to the default value of that attribute. To create a MathOptInterface optimizer attribute, an identifier must be present on the left hand side. If a solver-specific, raw attribute is desired, its name must be given as a string, e.g. between double quotes. In the special case where an attribute could be accessed in both ways, the identifier must be followed by the parenthesised raw attribute string. In any case, the attribute type can be specified typing the type assertion operator `::` followed by the type itself just before the equal sign.

For example, a list of the valid syntax variations for the *number of reads* attribute follows:
    - `"num_reads" = 1_000`
    - `"num_reads"::Integer = 1_000`
    - `NumberOfReads = 1_000`
    - `NumberOfReads::Integer = 1_000`
    - `NumberOfReads["num_reads"] = 1_000`
    - `NumberOfReads["num_reads"]::Integer = 1_000`

Example
```
Anneal.@anew Optimizer begin
    name = "Super Sampler"
    version = v"1.0.2"
    domain = :spin
    attributes = begin
        NumberOfReads["num_reads]::Integer = 1_000
        SuperAttribute["super_attr"] = nothing
    end
end
```
"""
macro anew(raw_args...)
    if __module__ === Main
        __anew_error("macro must be called from within a module (not Main)")
    elseif __module__ ∈ Anneal.__ANEW_REGISTRY
        __anew_error("macro should be called only once within a module")
    else
        push!(Anneal.__ANEW_REGISTRY, __module__)
    end

    args = map(
        a -> macroexpand(__module__, a),
        raw_args,
    )

    id, params = __anew_parse(args...)

    name = params[:name]

    version = params[:version]

    domain = if params[:domain] === :bool
        :(QUBOTools.BoolDomain)
    elseif params[:domain] === :spin
        :(QUBOTools.SpinDomain)
    else
        error("domain ≂̸ :spin, :bool")
    end

    attributes = __anew_attr.(params[:attributes])

    # ~ For this mechanism to work it is very important that the
    #   @anew macro is called at most once inside each module.
    quote
        const __SAMPLER_ATTRIBUTES = Anneal.SamplerAttribute[]

        struct $(esc(id)){T} <: Anneal.AutomaticSampler{T}
            # ~*~ QUBOTools Backend ~*~ #
            backend::QUBOTools.StandardQUBOModel{MOI.VariableIndex,Int,T,$(domain)}
            # ~*~ Attributes ~*~ #
            attrs::Anneal.SamplerAttributeData{T}

            function $(esc(id)){T}(args...; kws...) where {T}
                new{T}(
                    QUBOTools.StandardQUBOModel{MOI.VariableIndex,Int,T,$(domain)}(),
                    Anneal.SamplerAttributeData{T}(
                        copy.(__SAMPLER_ATTRIBUTES)
                    ),
                )
            end

            function $(esc(id))(args...; kws...)
                $(esc(id)){Float64}(args...; kws...)
            end
        end

        QUBOTools.backend(sampler::$(esc(id))) = sampler.backend

        MOI.get(::$(esc(id)), ::MOI.SolverName)    = $(esc(name))
        MOI.get(::$(esc(id)), ::MOI.SolverVersion) = $(esc(version))

        $(attributes...)
    end
end