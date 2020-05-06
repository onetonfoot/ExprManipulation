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

        expr_math = :((1 + 2)^3)
        show_sexpr(expr_math)

        match_math = MExpr(:call, Capture(:power_op), MExpr(:call, Capture(:plus_op), :_, :_), Capture(:power_n))
        match_math == expr_math

        # Function guards
        transform_fn(key::Symbol, expr) = transform_fn(Val(key), expr)
        transform_fn(key::Val{:power_op}, expr) = :+
        transform_fn(key::Val{:plus_op}, expr) = :*
        transform_fn(key::Val{T}, expr) where T = expr
    end
end