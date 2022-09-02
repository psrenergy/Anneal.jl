# ~*~ :: MathOptInterface Attributes :: ~*~ ::
const MOI_ATTRIBUTES = Union{
    MOI.Name,
    MOI.Silent,
    MOI.TimeLimitSec,
    MOI.NumberOfThreads,
    # MOI.VariablePrimalStart,
}

mutable struct MOIAttributeData{T}
    # ~*~ Regular ~*~
    name::String
    silent::Bool
    time_limit_sec::Union{Float64,Nothing}
    number_of_threads::Int
    # ~*~ Extra ~*~
    variable_primal_start::Dict{VI,T}

    function MOIAttributeData{T}(;
        name::String="",
        silent::Bool=false,
        time_limit_sec::Union{Float64,Nothing}=nothing,
        number_of_threads::Integer=Threads.nthreads(),
        variable_primal_start=Dict{VI,T}()
    ) where {T}

        new{T}(
            name,
            silent,
            time_limit_sec,
            number_of_threads,
            variable_primal_start,
        )
    end

    function MOIAttributeData(; kws...)
        MOIAttributeData{Float64}(; kws...)
    end
end

# ~*~ :: get :: ~*~ ::
function Base.getindex(::MOIAttributeData, ::X) where {X<:MOI.AbstractOptimizerAttribute}
    error("Attribute '$X' is not supported")
end

Base.getindex(moiattrs::MOIAttributeData, ::MOI.Name) = moiattrs.name
Base.getindex(moiattrs::MOIAttributeData, ::MOI.Silent) = moiattrs.silent
Base.getindex(moiattrs::MOIAttributeData, ::MOI.TimeLimitSec) = moiattrs.time_limit_sec
Base.getindex(moiattrs::MOIAttributeData, ::MOI.NumberOfThreads) = moiattrs.number_of_threads

function Base.getindex(moiattrs::MOIAttributeData{T}, ::MOI.VariablePrimalStart, vi::VI) where {T}
    if haskey(moiattrs.variable_primal_start, vi)
        return moiattrs.variable_primal_start[vi]
    else
        error("No warm-start value for '$vi'")
    end
end

# ~*~ :: set :: ~*~ ::
Base.setindex!(moiattrs::MOIAttributeData, name::String, ::MOI.Name) = (moiattrs.name = name)
Base.setindex!(moiattrs::MOIAttributeData, silent::Bool, ::MOI.Silent) = (moiattrs.silent = silent)

function Base.setindex!(moiattrs::MOIAttributeData, time_limit_sec::Union{Float64,Nothing}, ::MOI.TimeLimitSec)
    @assert isnothing(time_limit_sec) || time_limit_sec >= 0.0

    moiattrs.time_limit_sec = time_limit_sec
end

function Base.setindex!(moiattrs::MOIAttributeData, number_of_threads::Integer, ::MOI.NumberOfThreads)
    @assert number_of_threads > 0

    moiattrs.number_of_threads = number_of_threads
end

function Base.setindex!(moiattrs::MOIAttributeData{T}, value::T, ::MOI.VariablePrimalStart, vi::VI) where {T}
    moiattrs.variable_primal_start[vi] = value
end

# ~*~ :: Sampler Attributes :: ~*~ ::
abstract type AbstractSamplerAttribute <: MOI.AbstractOptimizerAttribute end

mutable struct SamplerAttribute{T<:Any}
    value::T
    rawattr::Union{String,Nothing}
    optattr::Union{<:AbstractSamplerAttribute,Nothing}

    function SamplerAttribute{T}(
        default::T;
        rawattr::Union{String,Nothing}=nothing,
        optattr::Union{<:AbstractSamplerAttribute,Nothing}=nothing
    ) where {T}
        @assert !isnothing(rawattr) || !isnothing(optattr)

        new{T}(default, rawattr, optattr)
    end

    function SamplerAttribute(args...)
        SamplerAttribute{Any}(args...)
    end
end

function Base.copy(attr::SamplerAttribute{T}) where {T}
    SamplerAttribute{T}(
        attr.value;
        rawattr=attr.rawattr,
        optattr=attr.optattr
    )
end

struct SamplerAttributeData{T}
    rawattrs::Dict{String,SamplerAttribute}
    optattrs::Dict{AbstractSamplerAttribute,SamplerAttribute}
    moiattrs::MOIAttributeData{T}

    function SamplerAttributeData{T}(attrs::Vector) where {T}
        rawattrs = Dict{String,SamplerAttribute}()
        optattrs = Dict{AbstractSamplerAttribute,SamplerAttribute}()
        moiattrs = MOIAttributeData{T}()

        for attr::SamplerAttribute in attrs
            if !isnothing(attr.rawattr)
                rawattrs[attr.rawattr] = attr
            end

            if !isnothing(attr.optattr)
                optattrs[attr.optattr] = attr
            end
        end

        new{T}(rawattrs, optattrs, moiattrs)
    end
end

# ~*~ :: get :: ~*~ ::
function Base.getindex(attrs::SamplerAttributeData, attr::MOI_ATTRIBUTES, args...)
    return attrs.moiattrs[attr, args...]
end

function Base.getindex(attrs::SamplerAttributeData, attr::AbstractSamplerAttribute)
    if haskey(attrs.optattrs, attr)
        data = attrs.optattrs[attr]

        return data.value
    else
        error("Attribute '$attr' is not supported")
    end
end

function Base.getindex(attrs::SamplerAttributeData, raw_attr::String)
    if haskey(attrs.rawattrs, raw_attr)
        data = attrs.rawattrs[raw_attr]

        return data.value
    else
        error("Attribute '$raw_attr' is not supported")
    end
end

function MOI.get(sampler::AutomaticSampler, attr::Union{MOI_ATTRIBUTES,AbstractSamplerAttribute})
    return sampler.attrs[attr]
end

function MOI.get(sampler::AutomaticSampler, attr::MOI.VariablePrimalStart, vi::VI)
    return sampler.attrs[attr, vi]
end

function MOI.get(sampler::AutomaticSampler, attr::MOI.RawOptimizerAttribute)
    return sampler.attrs[attr.name]
end

# ~*~ :: set :: ~*~ ::
function Base.setindex!(attrs::SamplerAttributeData, value, attr::MOI_ATTRIBUTES, args...)
    attrs.moiattrs[attr, args...] = value
end

function Base.setindex!(attrs::SamplerAttributeData, value, attr::AbstractSamplerAttribute)
    if haskey(attrs.optattrs, attr)
        data = attrs.optattrs[attr]

        data.value = value
    else
        error("Attribute '$attr' is not supported")
    end
end

function Base.setindex!(attrs::SamplerAttributeData, value, raw_attr::String)
    if haskey(attrs.rawattrs, raw_attr)
        data = attrs.rawattrs[raw_attr]

        data.value = value
    else
        error("Attribute '$raw_attr' is not supported")
    end
end

function MOI.set(sampler::AutomaticSampler, attr::Union{MOI_ATTRIBUTES,AbstractSamplerAttribute}, value)
    sampler.attrs[attr] = value
end

function MOI.set(sampler::AutomaticSampler, attr::MOI.VariablePrimalStart, vi::VI, value)
    sampler.attrs[attr, vi] = value
end

function MOI.set(sampler::AutomaticSampler, attr::MOI.RawOptimizerAttribute, value)
    sampler.attrs[attr.name] = value
end