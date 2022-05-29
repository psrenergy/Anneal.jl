# -*- :: Simulated Annealer :: -*-
Anneal.@anew begin
    NumberOfReads("num_reads")::Int = 1_000
    NumberOfSweeps("num_sweeps")::Int = 1_000
end

# -*- :: Python D-Wave Simulated Annealing :: -*-
const neal = PythonCall.pynew() # initially NULL

function __init__()
    PythonCall.pycopy!(neal, pyimport("neal"))
end

function Anneal.sample(annealer::Optimizer{T}) where {T}
    sampler = neal.SimulatedAnnealingSampler()

    t₀ = time()
    records = sampler.sample_qubo(
        annealer.Q;
        num_reads=MOI.get(annealer, MOI.RawOptimizerAttribute("num_reads")),
        num_sweeps=MOI.get(annealer, MOI.RawOptimizerAttribute("num_sweeps")),
    ).record
    samples = [(pyconvert.(Int, s), pyconvert(Int, n), pyconvert(Float64, e + annealer.c)) for (s, e, n) in records]
    t₁ = time()

    δt = t₁ - t₀

    return (samples, δt)
end