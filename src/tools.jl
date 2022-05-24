@doc raw"""
    isqubo(model::MOI.ModelLike)
    
Tells if a given model is ready to be interpreted as a QUBO model.

For it to be true, a few conditions must be met:
 1. All variables must be binary (`MOI.VariableIndex ∈ MOI.ZeroOne`)
 2. No other constraints are allowed
 3. The objective function must be of type `MOI.ScalarQuadraticFunction`, `MOI.ScalarAffineFunction` or `MOI.VariableIndex`
 4. The objective sense must be either `MOI.MIN_SENSE` or `MOI.MAX_SENSE`
"""
function isqubo end

function isqubo(model::MOI.ModelLike)
    F = MOI.get(model, MOI.ObjectiveFunctionType())

    if !(F <: Union{SQF,SAF,VI})
        return false
    end

    S = MOI.get(model, MOI.ObjectiveSense())

    if !(S === MOI.MAX_SENSE || S === MOI.MIN_SENSE)
        return false
    end

    # List of Variables
    v = Set{VI}(MOI.get(model, MOI.ListOfVariableIndices()))

    for (F, S) in MOI.get(model, MOI.ListOfConstraintTypesPresent())
        if (F === VI && S === MOI.ZeroOne)
            for cᵢ in MOI.get(model, MOI.ListOfConstraintIndices{F,S}())
                vᵢ = MOI.get(model, MOI.ConstraintFunction(), cᵢ)

                # Account for variable as binary
                delete!(v, vᵢ)
            end
        else
            # Non VariableIndex-in-ZeroOne Constraint
            return false
        end
    end

    if !isempty(v)
        # Some variable is not covered by binary constraints
        return false
    end

    return true
end

@doc raw"""
    qubo_normal_form(model::MOI.ModelLike)
    qubo_normal_form(T::Type, model::MOI.ModelLike)

Returns a triple ``(x, Q, c)`` where:
 * `x::Dict{MOI.VariableIndex, Union{Int, Nothing}}` maps each of the model's variables to an integer index, to be used when interacting with `Q`.
 * `Q::Dict{Tuple{Int, Int}, T}` is a sparse representation of the QUBO Matrix.
 * `c::T` is the constant term associated with the problem.
"""
function qubo_normal_form end

function qubo_normal_form(T::Type, model::MOI.ModelLike)
    if !isqubo(model)
        throw(QUBOError())
    end

    u = Vector{VI}(MOI.get(model, MOI.ListOfVariableIndices()))
    v = Set{VI}(u)
    q = Dict{Tuple{VI,VI},T}()
    c = zero(T)

    F = MOI.get(model, MOI.ObjectiveFunctionType())
    f = MOI.get(model, MOI.ObjectiveFunction{F}())

    if F <: VI
        q[f, f] = one(T)
    elseif F <: SAF
        for a in f.terms
            cᵢ = a.coefficient
            xᵢ = a.variable

            q[xᵢ, xᵢ] = get(q, (xᵢ, xᵢ), zero(T)) + cᵢ

            delete!(v, xᵢ)
        end

        c += f.constant

    elseif F <: SQF

        for a in f.affine_terms
            cᵢ = a.coefficient
            xᵢ = a.variable

            q[xᵢ, xᵢ] = get(q, (xᵢ, xᵢ), zero(T)) + cᵢ

            delete!(v, xᵢ)
        end

        for a in f.quadratic_terms
            cᵢⱼ = a.coefficient
            xᵢ = a.variable_1
            xⱼ = a.variable_2

            if xᵢ == xⱼ
                cᵢⱼ /= 2
            end

            q[xᵢ, xⱼ] = get(q, (xᵢ, xⱼ), zero(T)) + cᵢⱼ

            delete!(v, xᵢ)
            delete!(v, xⱼ)
        end

        c += f.constant
    end

    x = Dict{VI,Maybe{Int}}()
    i = 0

    for xᵢ ∈ u
        x[xᵢ] = (xᵢ ∈ v) ? nothing : (i += 1)
    end

    if MOI.get(model, MOI.ObjectiveSense()) !== MOI.MIN_SENSE
        s = -one(T)
        c = -c
    else
        s = one(T)
    end

    Q = Dict{Tuple{Int,Int},T}((x[xᵢ], x[xⱼ]) => s * qᵢⱼ for ((xᵢ, xⱼ), qᵢⱼ) ∈ q if qᵢⱼ != zero(T))

    (x, Q, c)
end

function qubo_normal_form(model::MOI.ModelLike)
    qubo_normal_form(Float64, model)
end

@doc raw"""
    ising_normal_form(model::MOI.ModelLike)
    ising_normal_form(T::Type, model::MOI.ModelLike)
    ising_normal_form(x::Dict{VI, Maybe{Int}}, Q::Dict{Tuple{Int, Int}, T}, c::T) where {T}

Returns a quadruple ``(s, h, J, c)`` where:
* `s::Dict{MOI.VariableIndex, Union{Int, Nothing}}` maps each of the model's variables to an integer index, to be used when interacting with ``h`` and ``J``.
* `h::Dict{Int, T}` is a sparse vector for the linear terms of the Ising Model.
* `J::Dict{Tuple{Int, Int}, T}` is a sparse representation of the quadratic magnetic interactions.
* `c::T` is the constant term associated with the problem.
"""
function ising_normal_form end

function ising_normal_form(x::Dict{VI,Maybe{Int}}, Q::Dict{Tuple{Int,Int},T}, c::T) where {T}
    h = Dict{Int,T}()
    J = Dict{Tuple{Int,Int},T}()

    for ((i, j), a) ∈ Q
        if i == j
            α = a / 2

            h[i] = get(h, i, 0) + α

            c += α
        else
            β = a / 4

            J[i, j] = β

            h[i] = get(h, i, 0) + β
            h[j] = get(h, j, 0) + β

            c += β
        end
    end

    (x, h, J, c)
end

function ising_normal_form(T::Type, model::MOI.ModelLike)
    x, Q, c = qubo_normal_form(T, model)

    ising_normal_form(x, Q, c)
end

function ising_normal_form(model::MOI.ModelLike)
    ising_normal_form(Float64, model)
end