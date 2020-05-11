using ExprManipulation, Test

has_unscores(expr::Expr) = any(map(has_unscores, expr.args))
has_unscores(x) = x == :_ ? true : false

function add_fn(expr)
    symbol = gensym()
    new_expr = transform(x->x == :_ ? symbol : x, expr)
    :($symbol->$new_expr)
end

slurp = Slurp(:args) do args
    any(has_unscores.(args))
end

capture_pipe = Capture(:pipe) do expr
    expr in [:|> , :.|>]
end

match_underscores = MExpr(Capture(:head), slurp)
match_pipe = MExpr(:call, capture_pipe, Capture(:fn), Slurp(:args))

function pipe(expr)
    transform(expr) do expr
        matches = match(match_pipe, expr)
        if !isnothing(matches)
            fn = matches[:fn]
            args = matches[:args]
            pipe = matches[:pipe]
            args = map(arg->match_underscores == arg ? add_fn(arg) : arg, args)
            Expr(:call, pipe, fn, args...)
        else
            expr
        end
    end
end

macro pipe(expr)
    esc(pipe(expr))
end

@testset "Pipe" begin
    x = 10
    f(x) = x^2
    g(x, y) = x + y

    @test @pipe(x |> f) == 10^2
    @test @pipe(f(x) |> f) == 10^4
    @test @pipe(x |> f |> g(_, _)) == 10^2 + 10^2
    @test @pipe(x |> f |> g(x, _)) == 110

    @test @pipe(x |> [_ _ ; _ _]) == [10 10; 10 10]
    @test @pipe(x |> [_,_]) == [10,10]

    @test @pipe(x |> [_,_] |> [_...,_...] ) == [10,10,10,10]
    @test @pipe([5,10] |> _[1] * _[2]) == 50
    @test @pipe([1,2,3] |>  [_...]  .|> f)  == [f(1),f(2),f(3)]
    @test @pipe([:a,:b,:c] |> Dict(k => v for (k, v) in enumerate(_))) == Dict(1 => :a, 2 => :b, 3 => :c)
end