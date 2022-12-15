struct QUBOError <: Exception
    msg::Union{Nothing, String}

    function QUBOError(msg::Union{Nothing, String} = nothing)
        return new(msg)
    end
end

function Base.showerror(io::IO, e::QUBOError)
    if isnothing(e.msg)
        print(
            io,
            """
            The current model could not be converted to QUBO in a straightforward fashion.
            Consider using the ToQUBO.jl package for a sophisticated conversion framework:
                pkg> add ToQUBO # 😎
            """
        )
    else
        print(io, e.msg)
    end
end
