using ExprManipulation
using Test

@testset "transform" begin
    @testset "identify transform" begin
        expr_nt = :(NamedTuple{}()) 
        match_nt = MExpr(:call, 
            Capture((==)(Expr(:curly, :NamedTuple)), :expr)
        )
        new_expr = transform(match_nt, expr_nt) do key, expr
            expr
        end
        @test new_expr == expr_nt
    end
end