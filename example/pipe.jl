using ExprManipulation
using Base.Meta: show_sexpr




x = 10
f(x) = x^2
g(x,y) = x + y


match_pipe = MExpr(:call, Capture(x->x == :|> || x == :.|>, :pipe), Capture(:args))


expr = :(x |> f |> f(_, _))
show_sexpr(expr)



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