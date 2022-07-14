

function MOI.empty!(::AbstractSampler, backend::BQPIO.AbstractBQPModel)
    empty!(backend)
end

function MOI.empty!(::X, ::Nothing) where X <: AbstractSampler
    error("'MOI.empty!(::$X)' is not implemented")
end