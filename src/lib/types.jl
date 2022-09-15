# ~*~ MathOptInterface ~*~ #

@doc raw"""
    Spin()

The set ``\left\lbrace{}{-1, 1}\right\rbrace{}``.
""" struct Spin <: MOI.AbstractScalarSet end

function MOIU._to_string(options::MOIU._PrintOptions, ::Anneal.Spin)
    return string(MOIU._to_string(options, ∈), " {-1, 1}")
end

function MOIU._to_string(::MOIU._PrintOptions{MIME"text/latex"}, ::Anneal.Spin)
    return raw"\in \left\lbrace{}{-1, 1}\right\rbrace{}"
end

# ~*~ JuMP ~*~ #
# Ref: https://jump.dev/JuMP.jl/stable/developers/extensions/#extend_variable_macro

struct SpinInfo
    info::JuMP.VariableInfo
end

function JuMP.build_variable(
    ::Function,
    info::JuMP.VariableInfo,
    ::Type{Anneal.Spin};
    kwargs...
)
    return Anneal.SpinInfo(info)
end

function JuMP.add_variable(
    model::JuMP.Model,
    info::Anneal.SpinInfo,
    name::String,
)
    x = JuMP.add_variable(model, JuMP.ScalarVariable(info.info), name)

    JuMP.@constraint(model, x ∈ Anneal.Spin())

    return x
end

JuMP.in_set_string(::MIME"text/plain", ::Anneal.Spin) = "spin"
JuMP.in_set_string(::MIME"text/latex", ::Anneal.Spin) = raw"\in \left\langle{}-1, 1\right\rangle{}}"