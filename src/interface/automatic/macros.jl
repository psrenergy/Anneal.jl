ANEW_DEFAULT_PARAMS() = Dict{Symbol,Any}(
    :name => "Binary Quadratic Sampler",
    :version => v"1.0.0",
    :domain => :bool,
    :attributes => Dict{Symbol,Any},
)

struct ANEW_ATTR{T}
    raw::Union{String,Nothing}
    attr::Union{Symbol,Nothing}
    init::T

    function ANEW_ATTR{T}(;
        raw::Union{String,Nothing}=nothing,
        attr::Union{Symbol,Nothing}=nothing,
        init::T
    ) where {T}
        @assert isnothing(raw) ⊼ isnothing(attr)

        new{T}(raw, attr, init)
    end

    function ANEW_ATTR(; kws...)
        ANEW_ATTR{Any}(; kws...)
    end
end

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
        ANEW_ATTR[attr for attr in anew_parse_attr.(value.args) if !isnothing(attr)]
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

    item, init = stmt.args

    if item isa Symbol # ~ MOI attribute only
        if !(Base.isidentifier(item))
            anew_error("attribute identifier '$item' is not a valid one")
        end

        ANEW_ATTR(;
            attr=item,
            init=init
        )
    elseif item isa String # ~ Raw attribute only
        ANEW_ATTR(;
            raw=item,
            init=init
        )
    elseif item isa Expr && item.head === :(::)
        code, type = item.args

        T = eval(type)

        if code isa Symbol
            if !(Base.isidentifier(code))
                anew_error("attribute identifier '$code' is not a valid one")
            end

            ANEW_ATTR{T}(;
                attr=code,
                init=init
            )
        elseif code isa String
            ANEW_ATTR{T}(;
                raw=code,
                init=init
            )
        elseif code isa Expr && (code.head === :ref || item.head === :call)
            name, raw = code.args

            if name isa Symbol && raw isa String
                if !(Base.isidentifier(name))
                    anew_error("attribute identifier '$name' is not a valid one")
                end

                ANEW_ATTR{T}(;
                    raw=raw,
                    attr=name,
                    init=init
                )
            else
                anew_error("invalid attribute identifier '$name($raw)'")
            end
        else
            anew_error("invalid attribute identifier '$code'")
        end
    elseif item isa Expr && (item.head === :ref || item.head === :call)
        name, raw = item.args

        if name isa Symbol && raw isa String
            ANEW_ATTR(;
                raw=raw,
                attr=name,
                init=init
            )
        else
            anew_error("invalid attribute identifier '$name($raw)'")
        end
    else
        anew_error("invalid attribute signature '$item'")
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

    @show params

    return params
end

function anew_parse_params()
    params = ANEW_DEFAULT_PARAMS()

    @show params

    return params
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

function anew_attr(id::Symbol, attr::ANEW_ATTR{T}) where {T}
    if !isnothing(attr.attr) && !isnothing(attr.raw)
        quote
            struct $(attr.attr) <: Anneal.SamplerAttribute end

            function MOI.get(sampler::$(id), ::$(attr.attr))
                MOI.get(sampler, MOI.RawOptimizerAttribute($(attr.raw)))
            end

            function MOI.set(sampler::$(id), ::$(attr.attr), value::$(T))
                MOI.set(sampler, MOI.RawOptimizerAttribute($(attr.raw)), value)

                nothing
            end
        end
    elseif !isnothing(attr.attr)
        quote
            struct $(attr.attr) <: Anneal.SamplerAttribute end

            function MOI.get(sampler::$(id), attr::$(attr.attr))
                get(sampler.opt_attr, attr, $(esc(attr.init)))::$(T)
            end

            function MOI.set(sampler::$(id), attr::$(attr.attr), value::$(T))
                setitem!(sample.opt_attr, value, attr)

                nothing
            end
        end
    elseif !isnothing(attr.raw)
        quote end
    else
        error("both 'attr' and 'raw' are 'nothing' for 'ANEW_ATTR'")
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
        anew_error("macro must be called from within a module (not Main)")
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

    attributes = [anew_attr(id, attr) for attr in params[:attributes]]

    quote
        $(attributes...)

        const __BACKEND{T} = BQPIO.StandardBQPModel{MOI.VariableIndex,Int,T,$(domain)}
        const __RAW_ATTRS = Dict{String, Any}()

        struct $(esc(id)){T} <: Anneal.Sampler{T}
            # ~*~ BQPIO Backend ~*~ #
            backend::__BACKEND{T}
            # ~*~ MathOptInterface ~*~ #
            moi_attrs::MOIAttributes{T}
            # ~*~ Optimizer Attributes ~*~ #
            raw_attrs::Dict{String,Any}
            opt_attrs::Dict{Any,Any}

            function $(esc(id)){T}() where {T}
                backend = __BACKEND{T}()

                new{T}(
                    __BACKEND{T}(),
                    MOIAttributes{T}(),
                    deepcopy(__RAW_ATTRS),
                    Dict{Any,Any}(),
                )
            end

            function $(esc(id))()
                $(esc(id)){Float64}()
            end
        end

        BQPIO.backend(sampler::$(esc(id))) = sampler.backend

        MOI.get(::$(esc(id)), ::MOI.SolverName) = $(esc(name))
        MOI.get(::$(esc(id)), ::MOI.SolverVersion) = $(esc(version))
    end
end