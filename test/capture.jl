using ExprManipulation: Capture, SplatCapture
using Test


@testset "Constructors" begin
    @test Capture(:x) isa Capture{1}
    @test Capture{2}(:x) isa Capture{2}
    @test Capture(:x) do expr
        expr == :(x + 1)
    end isa Capture{1}

    @test SplatCapture(:x) isa SplatCapture
    @test SplatCapture(:x) do expr
        expr == :(x + 1)
    end isa SplatCapture

    
end



