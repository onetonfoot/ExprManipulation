@testset "transform" begin

    expr = :(x + 1 - 2 + 4^100)
    @test transform(expr) do expr
        expr
    end == expr

    @test transform(expr) do expr
        expr isa Number ? 1 : expr
    end == :(x + 1 - 1 + 1^1)
end