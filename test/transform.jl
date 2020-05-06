using ExprManipulation
using Test

@testset "transform" begin
    @testset "identify transform" begin
        simple_expr = :(x + 1)
        simple_match = MExpr(:call, :+, Capture(:x), SplatCapture(:args))
        @test transform(simple_match, simple_expr) == simple_expr

        nested_expr = :((x + 1)^3)
        nested_match = MExpr(:call, :^, MExpr(:call, SplatCapture(:args)), 3)
        @test transform(nested_match, nested_expr) == nested_expr
    end

    @testset "repalace +" begin
        plus_expr = :((x + 2)^2)
        plus_transform = Capture(x->x == :+,  :plus) |> Transform(expr->:*)
        m_expr = MExpr(:call, :^, MExpr(:call, plus_transform, SplatCapture(:args)), 2)
        @test transform(m_expr, plus_expr) == :((x * 2)^2)
    end
end