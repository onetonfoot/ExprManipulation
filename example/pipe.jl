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

splat_underscores = SplatCapture(:underscore) do args
    any(args .== :_)
end

match_underscores = MExpr(Capture(:call), splat_underscores)

output_expr = transform(match_pipe, input_expr) do key, expr
    @show expr
    expr
end;



transform_fn(key, expr) = transform_fn(Val(key), expr)
transform_fn(key::Symbol, expr) = transform_fn(Val(key), expr)
transform_fn(key::Val{:call}, expr) = :->

show_sexpr(input_fn_expr)
show_sexpr(target_fn_expr)


function transform_fn(key::Val{:underscore}, expr) 
    expr[1], :3
end


transform(transform_fn, match_underscores, input_fn_expr)

target_expr

match_underscores


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