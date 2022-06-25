@testset "Error Messages" begin
    io = IOBuffer()

    error_msg = "Error Message!"

    showerror(io, Anneal.QUBOError(error_msg))

    @test String(take!(io)) == error_msg

    showerror(io, Anneal.QUBOError())

    @test occursin("ToQUBO.jl", String(take!(io)))
end