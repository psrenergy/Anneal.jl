const ANEW_REGISTRY = Set{Module}()

struct ANEW_SAMPLER_ATTR{T}
    default::T
    optattr::Union{Symbol,Nothing}
    rawattr::Union{String,Nothing}

    function ANEW_SAMPLER_ATTR{T}(
        default::T;
        optattr::Union{Symbol,Nothing}=nothing,
        rawattr::Union{String,Nothing}=nothing
    ) where {T}
        new{T}(default, optattr, rawattr)
    end

    function ANEW_SAMPLER_ATTR(args...; kws...)
        ANEW_SAMPLER_ATTR{Any}(args...; kws...)
    end
end

ANEW_DEFAULT_PARAMS() = Dict{Symbol,Any}(
    :name => "Binary Quadratic Sampler",
    :version => v"1.0.0",
    :domain => :bool,
    :attributes => Anneal.ANEW_SAMPLER_ATTR[],
)

function anew_error(msg::String)
    error("Invalid usage of @anew: $msg")
end

function anew_parse_id(id::Symbol)
    if Base.isidentifier(id)
        return id
    else
        anew_error("sampler identifier '$id' is not a valid one")
    end
end

function anew_parse_id()
    return :Optimizer
end

function anew_parse_param(::Val{X}, ::Any) where {X}
    anew_error("invalid parameter '$X', valid options are: 'name', 'version', 'domain', 'attributes'")
end

function anew_parse_param(::Val{:name}, value)
    if value isa String
        return value
    else
        anew_error("parameter 'name' must be a 'String'")
    end
end

function anew_parse_param(::Val{:version}, value)
    if value isa VersionNumber
        return value
    else
        anew_error("parameter 'name' must be a 'VersionNumber'")
    end
end

function anew_parse_param(::Val{:domain}, value)
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
        anew_error("parameter 'domain' must be either ':bool' or ':spin', not '$value'")
    end
end

function anew_parse_param(::Val{:attributes}, value)
    if value isa Expr && value.head === :block
        Anneal.ANEW_SAMPLER_ATTR[
            attr for attr in anew_parse_attr.(value.args)
            if !isnothing(attr)
        ]
    else
        anew_error("parameter 'attributes' must be a `begin...end` block")
    end
end

function anew_parse_attr(stmt)
    if stmt isa LineNumberNode
        return nothing
    elseif !(stmt isa Expr && stmt.head === :(=))
        anew_error("each attribute definition must be an assignment to its default value")
    end

    attr, value = stmt.args

    default = eval(value)

    if attr isa Symbol # ~ MOI attribute only
        if !(Base.isidentifier(attr))
            anew_error("attribute identifier '$attr' is not a valid one")
        end

        Anneal.ANEW_SAMPLER_ATTR(
            default;
            optattr=attr
        )
    elseif attr isa String # ~ Raw attribute only
        Anneal.ANEW_SAMPLER_ATTR(
            default;
            rawattr=attr
        )
    elseif attr isa Expr && attr.head === :(::)
        attr, type = attr.args

        T = eval(type)

        if attr isa Symbol
            if !(Base.isidentifier(attr))
                anew_error("attribute identifier '$attr' is not a valid one")
            end

            Anneal.ANEW_SAMPLER_ATTR{T}(
                default;
                optattr=attr
            )
        elseif attr isa String
            Anneal.ANEW_SAMPLER_ATTR{T}(
                default;
                rawattr=attr
            )
        elseif attr isa Expr && (attr.head === :ref || item.head === :call)
            optattr, rawattr = attr.args

            if optattr isa Symbol && rawattr isa String
                if !(Base.isidentifier(optattr))
                    anew_error("attribute identifier '$optattr' is not a valid one")
                end

                Anneal.ANEW_SAMPLER_ATTR{T}(
                    default;
                    rawattr=rawattr,
                    optattr=optattr
                )
            else
                anew_error("invalid attribute identifier '$name($raw)'")
            end
        else
            anew_error("invalid attribute identifier '$attr'")
        end
    elseif attr isa Expr && (attr.head === :ref || attr.head === :call)
        optattr, rawattr = attr.args

        if optattr isa Symbol && rawattr isa String
            if !(Base.isidentifier(optattr))
                anew_error("attribute identifier '$optattr' is not a valid one")
            end

            Anneal.ANEW_SAMPLER_ATTR(
                default;
                rawattr=rawattr,
                optattr=optattr
            )
        else
            anew_error("invalid attribute identifier '$name[$rawattr]'")
        end
    else
        anew_error("invalid attribute signature '$attr'")
    end
end

function anew_parse_params(block::Expr)
    @assert block.head === :block

    params = ANEW_DEFAULT_PARAMS()

    for item in block.args
        if item isa LineNumberNode
            continue
        elseif item isa Expr && item.head === :(=)
            param, value = item.args

            if param isa Symbol && Base.isidentifier(param)
                params[param] = anew_parse_param(Val(param), value)
            else
                anew_error("sampler parameter key must be a valid identifier")
            end
        else
            anew_error("sampler parameters must be `key = value` pairs")
        end
    end

    params
end

function anew_parse_params()
    ANEW_DEFAULT_PARAMS()
end

function anew_parse(args...)
    anew_error("macro takes exactly one or two arguments")
end

function anew_parse(expr)
    if expr isa Symbol # Name
        return (
            anew_parse_id(expr),
            anew_parse_params(),
        )
    elseif (expr isa Expr && expr.head === :block)
        return (
            anew_parse_id(),
            anew_parse_params(expr),
        )
    else
        anew_error("single argument must be either an identifier or a `begin...end` block")
    end
end

function anew_parse()
    return (anew_parse_id(), anew_parse_params())
end

function anew_parse(id, block)
    id = if !(id isa Symbol)
        anew_error("first argument must be an identifier")
    else
        anew_parse_id(id)
    end

    params = if !(block isa Expr && block.head === :block)
        anew_error("second argument must be a `begin...end` block")
    else
        anew_parse_params(block)
    end

    return (id, params)
end

function anew_attr(attr::Anneal.ANEW_SAMPLER_ATTR{T}) where {T}
    if !isnothing(attr.optattr) && !isnothing(attr.rawattr)
        return quote
            struct $(esc(attr.optattr)) <: Anneal.AbstractSamplerAttribute end

            push!(
                __SAMPLER_ATTRIBUTES,
                Anneal.SamplerAttribute{$(T)}(
                    $(attr.default);
                    rawattr=$(esc(attr.rawattr)),
                    optattr=$(esc(attr.optattr))()
                )
            )
        end
    elseif !isnothing(attr.optattr)
        return quote
            struct $(esc(attr.optattr)) <: Anneal.AbstractSamplerAttribute end

            push!(
                __SAMPLER_ATTRIBUTES,
                Anneal.SamplerAttribute{$(T)}(
                    $(attr.default);
                    optattr=$(esc(attr.optattr))()
                )
            )
        end
    elseif !isnothing(attr.rawattr)
        return quote
            push!(
                __SAMPLER_ATTRIBUTES,
                Anneal.SamplerAttribute{$(T)}(
                    $(attr.default);
                    rawattr=$(esc(attr.rawattr))
                )
            )
        end
    else
        error("Looks like some assertions were skipped. Did you turn some optimizations on?")
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
        # anew_error("macro must be called from within a module (not Main)")
    elseif __module__ ∈ Anneal.ANEW_REGISTRY
        anew_error("macro should be called only once within a module")
    else
        push!(Anneal.ANEW_REGISTRY, __module__)
    end

    args = map(
        a -> macroexpand(__module__, a),
        raw_args,
    )

    id, params = anew_parse(args...)

    name = params[:name]

    version = params[:version]

    domain = if params[:domain] === :bool
        :(BQPIO.BoolDomain)
    elseif params[:domain] === :spin
        :(BQPIO.SpinDomain)
    else
        error("domain ≂̸ :spin, :bool")
    end

    attr_blocks = anew_attr.(params[:attributes])

    # ~ For this mechanism to work it is very important that the
    #   @anew macro is called at most once inside each module.
    quote
        const __SAMPLER_ATTRIBUTES = Anneal.SamplerAttribute[]

        struct $(esc(id)){T} <: Anneal.AutomaticSampler{T}
            # ~*~ BQPIO Backend ~*~ #
            backend::BQPIO.StandardBQPModel{MOI.VariableIndex,Int,T,$(domain)}
            # ~*~ Attributes ~*~ #
            attrs::Anneal.SamplerAttributeData{T}

            function $(esc(id)){T}(args...; kws...) where {T}
                new{T}(
                    BQPIO.StandardBQPModel{MOI.VariableIndex,Int,T,$(domain)}(),
                    Anneal.SamplerAttributeData{T}(
                        copy.(__SAMPLER_ATTRIBUTES)
                    ),
                )
            end

            function $(esc(id))(args...; kws...)
                $(esc(id)){Float64}(args...; kws...)
            end
        end

        BQPIO.backend(sampler::$(esc(id))) = sampler.backend

        MOI.get(::$(esc(id)), ::MOI.SolverName) = $(esc(name))
        MOI.get(::$(esc(id)), ::MOI.SolverVersion) = $(esc(version))

        $(attr_blocks...)
    end
end