# ~*~ :: MathOptInterface Attributes :: ~*~ ::
const _MOI_ATTRIBUTES =
    Union{MOI.Name,MOI.Silent,MOI.TimeLimitSec,MOI.NumberOfThreads,MOI.VariablePrimalStart}

mutable struct _MOIAttributeData{T}
    # ~*~ Regular ~*~
    name::String
    silent::Bool
    time_limit_sec::Union{Float64,Nothing}
    number_of_threads::Int
    # ~*~ Extra ~*~
    variable_primal_start::Dict{VI,T}

    function _MOIAttributeData{T}(;
        name::String                           = "",
        silent::Bool                           = false,
        time_limit_sec::Union{Float64,Nothing} = nothing,
        number_of_threads::Integer             = Threads.nthreads(),
        variable_primal_start                  = Dict{VI,T}(),
    ) where {T}
        return new{T}(
            name,
            silent,
            time_limit_sec,
            number_of_threads,
            variable_primal_start,
        )
    end
end

# ~*~ :: get :: ~*~ ::
function MOI.get(::_MOIAttributeData, ::X) where {X<:MOI.AbstractOptimizerAttribute}
    error("Attribute '$X' is not supported")
end

MOI.get(data::_MOIAttributeData, ::MOI.Name)            = data.name
MOI.get(data::_MOIAttributeData, ::MOI.Silent)          = data.silent
MOI.get(data::_MOIAttributeData, ::MOI.TimeLimitSec)    = data.time_limit_sec
MOI.get(data::_MOIAttributeData, ::MOI.NumberOfThreads) = data.number_of_threads

function MOI.get(data::_MOIAttributeData, ::MOI.VariablePrimalStart, vi::VI)
    return get(data.variable_primal_start, vi, nothing)
end

# ~*~ :: set :: ~*~ ::
function MOI.set(data::_MOIAttributeData, ::MOI.Name, name::String)
    data.name = name

    return nothing
end

function MOI.set(data::_MOIAttributeData, ::MOI.Silent, silent::Bool)
    data.silent = silent

    return nothing
end

function MOI.set(
    data::_MOIAttributeData,
    ::MOI.TimeLimitSec,
    time_limit_sec::Union{Float64,Nothing},
)
    @assert isnothing(time_limit_sec) || time_limit_sec >= 0.0

    data.time_limit_sec = time_limit_sec

    return nothing
end

function MOI.set(data::_MOIAttributeData, ::MOI.NumberOfThreads, number_of_threads::Integer)
    @assert number_of_threads > 0

    data.number_of_threads = number_of_threads

    return nothing
end

function MOI.set(
    data::_MOIAttributeData{T},
    ::MOI.VariablePrimalStart,
    vi::VI,
    value::T,
) where {T}
    data.variable_primal_start[vi] = value

    return nothing
end

function MOI.set(
    data::_MOIAttributeData{T},
    ::MOI.VariablePrimalStart,
    vi::VI,
    ::Nothing,
) where {T}
    delete!(data.variable_primal_start, vi)

    return nothing
end

# ~*~ :: Sampler Attributes :: ~*~ ::
abstract type AbstractSamplerAttribute <: MOI.AbstractOptimizerAttribute end

const _SAMPLER_ATTRIBUTES = Union{_MOI_ATTRIBUTES,<:AbstractSamplerAttribute}

mutable struct SamplerAttribute{T<:Any}
    value::T
    rawattr::Union{String,Nothing}
    optattr::Union{<:AbstractSamplerAttribute,Nothing}

    function SamplerAttribute{T}(
        default::T;
        rawattr::Union{String,Nothing}                     = nothing,
        optattr::Union{<:AbstractSamplerAttribute,Nothing} = nothing,
    ) where {T}
        @assert !(isnothing(rawattr) && isnothing(optattr))

        return new{T}(default, rawattr, optattr)
    end
end

SamplerAttribute(args...) = SamplerAttribute{Any}(args...)

function Base.copy(attr::SamplerAttribute{T}) where {T}
    return SamplerAttribute{T}(attr.value; rawattr = attr.rawattr, optattr = attr.optattr)
end

struct _SamplerAttributeData{T}
    rawattrs::Dict{String,SamplerAttribute}
    optattrs::Dict{AbstractSamplerAttribute,SamplerAttribute}
    moiattrs::_MOIAttributeData{T}

    function _SamplerAttributeData{T}(attrs::Vector) where {T}
        rawattrs = Dict{String,SamplerAttribute}()
        optattrs = Dict{AbstractSamplerAttribute,SamplerAttribute}()
        moiattrs = _MOIAttributeData{T}()

        for attr::SamplerAttribute in attrs
            if !isnothing(attr.rawattr)
                rawattrs[attr.rawattr] = attr
            end

            if !isnothing(attr.optattr)
                optattrs[attr.optattr] = attr
            end
        end

        return new{T}(rawattrs, optattrs, moiattrs)
    end
end

# ~*~ :: get :: ~*~ ::
function MOI.get(data::_SamplerAttributeData, attr::_MOI_ATTRIBUTES, args...)
    return MOI.get(data.moiattrs, attr, args...)
end

function MOI.get(data::_SamplerAttributeData, attr::AbstractSamplerAttribute)
    if haskey(data.optattrs, attr)
        return data.optattrs[attr].value
    else
        error("Attribute '$attr' is not supported")
    end
end

function MOI.get(data::_SamplerAttributeData, raw_attr::String)
    if haskey(data.rawattrs, raw_attr)
        return data.rawattrs[raw_attr].value
    else
        error("Attribute '$raw_attr' is not supported")
    end
end

function MOI.get(sampler::AutomaticSampler, attr::_SAMPLER_ATTRIBUTES)
    return MOI.get(sampler.attrs, attr)
end

function MOI.get(sampler::AutomaticSampler, attr::MOI.VariablePrimalStart, vi::VI)
    return MOI.get(sampler.attrs, attr, vi)
end

function MOI.get(sampler::AutomaticSampler, attr::MOI.RawOptimizerAttribute)
    return MOI.get(sampler.attrs, attr.name)
end

# ~*~ :: set :: ~*~ ::
function MOI.set(data::_SamplerAttributeData, attr::_MOI_ATTRIBUTES, args...)
    MOI.set(data.moiattrs, attr, args...)

    return nothing
end

function MOI.set(data::_SamplerAttributeData, attr::AbstractSamplerAttribute, value)
    if haskey(data.optattrs, attr)
        data.optattrs[attr].value = value
    else
        error("Attribute '$attr' is not supported")
    end

    return nothing
end

function MOI.set(data::_SamplerAttributeData, raw_attr::String, value)
    if haskey(data.rawattrs, raw_attr)
        data.rawattrs[raw_attr].value = value
    else
        error("Attribute '$raw_attr' is not supported")
    end

    return nothing
end

function MOI.set(sampler::AutomaticSampler, attr::_SAMPLER_ATTRIBUTES, value)
    MOI.set(sampler.attrs, attr, value)

    return nothing
end

function MOI.set(
    sampler::AutomaticSampler{T},
    attr::MOI.VariablePrimalStart,
    vi::VI,
    value::Union{T,Nothing},
) where {T}
    MOI.set(sampler.attrs, attr, vi, value)

    return nothing
end

function MOI.set(sampler::AutomaticSampler, attr::MOI.RawOptimizerAttribute, value)
    MOI.set(sampler.attrs, attr.name, value)

    return nothing
end

function MOI.supports(
    ::AutomaticSampler,
    ::_SAMPLER_ATTRIBUTES
)
    return true
end

function MOI.supports(
    ::AutomaticSampler,
    ::MOI.VariablePrimalStart,
    ::Type{MOI.VariableIndex},
)
    return true
end