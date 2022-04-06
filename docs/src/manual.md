# Manual

The annealers and samplers defined via the `AbstractSampler{T}` interface only support models given in a QUBO form, as explained below.

## QUBO
An optimization problem is in its QUBO form if it is written as
```math
\begin{array}{rl}
    \min & \mathbf{x}^{\intercal} \mathbf{Q}\, \mathbf{x} \\
    \text{s.t.} & \mathbf{x} \in \mathbb{B}^{n}
\end{array}
```
where ``\mathbf{Q} \in \mathbb{R}^{n}`` is a symmetric matrix.