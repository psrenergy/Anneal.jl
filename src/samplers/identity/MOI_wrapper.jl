# -*- :: -*- Attributes -*- :: -*-

# -*- SolverName (get) -*-
function MOI.get(::Optimizer, ::MOI.SolverName)
    return "Identity Sampler"
end

# -*- SolverVersion (get) -*-
function MOI.get(::Optimizer, ::MOI.SolverVersion)
    return v"1.0.0"
end