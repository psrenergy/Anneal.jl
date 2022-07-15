function BQPIO.StandardBQPModel{T}(model::MOI.ModelLike) where {T}
    if !isqubolike(model)
        # Throws default massage (ToQUBO.jl advertisement 😎)
        throw(QUBOError(nothing))
    end

    x = Dict{VI,Int}(xᵢ => i for (i, xᵢ) in enumerate(MOI.get(model, MOI.ListOfVariableIndices())))
    L = Dict{Int,T}()
    Q = Dict{Tuple{Int,Int},T}()
    c = zero(T)

    F = MOI.get(model, MOI.ObjectiveFunctionType())
    f = MOI.get(model, MOI.ObjectiveFunction{F}())

    if F <: VI
        Q[f, f] = one(T)
    elseif F <: SAF
        for a in f.terms
            cᵢ = a.coefficient
            xᵢ = a.variable

            i = x[xᵢ]

            L[i] = get(L, i, zero(T)) + cᵢ
        end

        c += f.constant
    elseif F <: SQF
        for a in f.affine_terms
            cᵢ = a.coefficient
            xᵢ = a.variable

            i = x[xᵢ]

            L[i] = get(L, i, zero(T)) + cᵢ
        end

        for a in f.quadratic_terms
            cᵢⱼ = a.coefficient
            xᵢ = a.variable_1
            xⱼ = a.variable_2

            i = x[xᵢ]
            j = x[xⱼ]

            if i > j
                # Not sure if this even happens.
                i, j = j, i
            end

            if i == j
                # MOI assumes 
                #   SQF := ½ x Q x + ax + b
                # ∴ the main diagonal is doubled
                L[i] = get(L, i, zero(T)) + cᵢⱼ / 2
            else
                Q[i, j] = get(Q, (i, j), zero(T)) + cᵢⱼ
            end            
        end

        c += f.constant
    end

    if MOI.get(model, MOI.ObjectiveSense()) === MOI.MAX_SENSE
        L = Dict{Int,T}(k => -Lₖ for (k, Lₖ) in L)
        Q = Dict{Tuple{Int,Int},T}(k => -Qₖ for (k, Qₖ) in Q)
        c = -c
    end

    BQPIO.StandardBQPModel{VI,Int,T,BQPIO.BoolDomain}(
        L,
        Q,
        x;
        offset=c,
    )
end

abstract type Sampler{T} <: AbstractSampler{T} end

function BQPIO.backend(::X) where X <: Sampler
    error("'BQPIO.backend' not implemented for '$X'")
end

function BQPIO.backend!(::X, ::BQPIO.AbstractBQPModel) where X <: Sampler
    error("'BQPIO.backend!' not implemented for '$X'")
end

# ~*~ :: MathOptInterface :: ~*~ #
function MOI.empty!(sampler::Sampler)
    empty!(BQPIO.backend(sampler))
end

function MOI.is_empty(sampler::Sampler)
    isempty(BQPIO.backend(sampler))
end

function MOI.optimize!(sampler::Sampler)
    Anneal.sample!(sampler)
end

function MOI.optimize!(sampler::Sampler, model::ModelLike)
    MOI.copy_to!(sampler, model)
    MOI.optimize!(sampler)
end

function Base.show(io::IO, sampler::Sampler)
    print(
        io,
        """
        $(MOI.get(sampler, ::MOI.SolverName())) Binary Quadratic Sampler

        with backend:
        """
    )
    print(io, BQPIO.backend(sampler))
end

function MOI.copy_to!(sampler::Sampler{T}, model::ModelLike) where T
    copy!(
        BQPIO.backend(sampler),
        BQPIO.StandardBQPModel{T}(model),
    )
end