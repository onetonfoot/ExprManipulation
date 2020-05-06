using ExprManipulation
using Base.Meta: show_sexpr

input_expr = :(x |> f |> f(_, _))
target_expr = :(x |> x->f(x) |> x->f(x, x))
input_fn_expr = :(f(_, _))
target_fn_expr = :(x->f(x, x))

splat_pipe = SplatCapture(:pipe) do args
    fn = args[1] 
    fn == :|> || fn == :.|>
end

match_pipe = MExpr(:call, splat_pipe)

replace_underscore(expr::Expr, symbol::Symbol) = Expr(expr.head, map(args->replace_underscore(args, symbol), expr.args))
replace_underscore(expr, symbol::Symbol) = expr == :_ ? symbol : expr

# Maybe remove capture and just have a default transform of identity
call = Capture(x->x == :call, :call) |> Transform(expr->:->)
fn = SplatCapture(:fn) |> Transform() do expr

    fn = expr[1]
    args = expr[2:end]
    args = replace_underscore.(args, Ref(:x))
    Expr(:call, args...)
end


m_expr = MExpr{:val}(call, fn) 


m_expr == input_fn_expr

match(m_expr, input_fn_expr)

transform(m_expr, input_fn_expr)

Expr(:call, :x) == Expr(:call, Capture(:x))


:(_[1]) |> show_sexpr
:(Dict(_ => 10)) |> show_sexpr

show_sexpr(input_fn_expr)


show_sexpr(target_fn_expr)





transform(transform_fn, match_underscores, input_fn_expr)



@testset "Scalars" begin
    @test @pipe(x |> f) == 10^2
    @test @pipe(f(x) |> f) == 10^4
    @test @pipe(x |> f |> g(_, _)) == 10^2 + 10^2
    @test @pipe(x |> f |> g(x, _)) == 110
end

@testset "Arrays" begin
    @test @pipe(x |> [_ _ ; _ _]) == [10 10; 10 10]
    @test @pipe(x |> [_,_]) == [10,10]
end

@testset "Other stuff" begin
    @test @pipe(x |> [_,_] |> [_...,_...] ) == [10,10,10,10]
    @test @pipe([5,10] |> _[1] * _[2]) == 50
    @test @pipe([1,2,3] .|> f)  == [f(1),f(2),f(3)]
    @test @pipe([:a,:b,:c] |> Dict(k => v for (k, v) in enumerate(_))) == Dict(1 => :a, 2 => :b, 3 => :c)
end