module IdentitySampler

import BQPIO
import Anneal
import MathOptInterface
const MOI = MathOptInterface
const VI = MOI.VariableIndex

Anneal.@anew Optimizer begin
    domain = :bool
    name = "Identity Sampler"
    version = v"1.0.0"
end

Anneal.@check(Optimizer)

end # module