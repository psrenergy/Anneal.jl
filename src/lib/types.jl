const Boolean = MOI.ZeroOne

@doc raw"""
```math
s \in \left\lbrace{}{-1, 1}\right\rbrace{}
```
""" struct Spin <: MOI.AbstractSet end

function show(io::IO, ::Spin)
    print(io, "{-1, 1}")
end