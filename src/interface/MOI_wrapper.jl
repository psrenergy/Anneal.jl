MOI.supports_constraint(
    ::AbstractSampler,
    ::MOI.AbstractFunction,
    ::MOI.AbstractSet,
) = false

MOI.supports_constraint(
    ::AbstractSampler,
    ::VI,
    ::MOI.ZeroOne,
) = true

MOI.get(sampler::AbstractSampler, ::MOI.RawSolver) = sampler