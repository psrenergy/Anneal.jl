# -*- :: Identity Sampler :: -*-
Anneal.@anew begin end;

function identity_sample(sampler::Optimizer{T}) where {T}
    s = Vector{Int}(undef, sampler.n)

    for (xᵢ, i) in BQPIO.variable_map(sampler)
        if isnothing(i)
            continue
        end

        sᵢ = MOI.get(sampler, MOI.VariablePrimalStart(), xᵢ)

        s[i] = isnothing(sᵢ) ? 0 : convert(Int, sᵢ > zero(T))
    end

    return (s, 1, Anneal.energy(sampler, s))
end

# -*- :: Identity Sampler :: -*-
function Anneal.sample(sampler::Optimizer{T}) where T
    t₀ = time()
    samples = [identity_sample(sampler)]
    t₁ = time()
    δt = t₁ - t₀

    metadata = Dict{String, Any}(
        "time" => Dict{String, Any}(
            "total" => δt
        )
    )

    BQPIO.SampleSet{Int, T}(
        samples,
        sampler,
        metadata,
    )
end 