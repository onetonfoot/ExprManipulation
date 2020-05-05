using ExprManipulation: MExpr, Capture, SplatCapture
using Test
using Base.Meta: show_sexpr




@testset "Constructor" begin

    MExpr(:call)
    MExpr(:call, Capture{2}(:x))
    MExpr(:call, SplatCapture(:x))
    MExpr(:call, Capture(:x), SplatCapture(:y))
    @test_throws ArgumentError MExpr(:call, SplatCapture(:y), Capture(:x))


end

@testset "S-Expr Syntax" begin

    @testset "infix_match" begin
        infix_match = MExpr(:call, Capture(:op), Capture(:lexpr), Capture(:rexpr))

        expr1 = :(x + 10) 

        show_sexpr(expr1)

        @test infix_match == expr1
        matches1 = infix_match(expr1)
        @test matches1[:lexpr] == :x
        @test matches1[:op] == :+
        @test matches1[:rexpr] == 10

        expr2 = :(x .~ Normal(μ, σ))
        @test infix_match == expr2
        matches2 = infix_match(expr2)
        @test matches2[:lexpr] == :x
        @test matches2[:op] == :.~
        @test matches2[:rexpr] == :(Normal(μ, σ))
    end

    @testset "tilde_match" begin
        tilde_match = MExpr(:call, 
            Capture(x->x == :.~ || x == :~,  :op), 
            Capture(:lexpr), 
            Capture(:rexpr)
        )

        tilde_match == :(x  ~ Normal(μ, 1))
        tilde_match == :(x  .~ Normal(μ, 1))
        tilde_match == :(x[:,1]  .~ Normal(μ, 1))
    end

    @testset "type_match" begin
        type_match = MExpr(:(::), MExpr(:curly, :Type, Capture(:t_expr)))
        @test type_match == :(::Type{T})
        @test type_match(:(::Type{T}))[:t_expr] == :T
        @test type_match == :(::Type{T <: Real})
        @test type_match(:(::Type{T <: Real}))[:t_expr] == :(T <: Real)
    end

    @testset "Capture{N}" begin

        expr = :((*)(1, 2, 3, 4)) 
        @test expr == MExpr(:call, :*, Capture{4}(:x))
        @test expr != MExpr(:call, :*, Capture{2}(:x))
        @test expr != MExpr(:call, :*, Capture{5}(:x))
        @test expr == MExpr(:call, :*, Capture{2}(:x), Capture{2}(:y))
        @test expr == MExpr(:call, :*, Capture{1}(:x), Capture{3}(:y))
        @test expr != MExpr(:call, :*, Capture{1}(:x), Capture{5}(:y))
        @test expr != MExpr(:call, :*, Capture{1}(:x), Capture{1}(:y))
    end

    @testset "SplatCapture" begin
        expr = :((+)(1, 2, 3, 4)) 
        @test expr == MExpr(:call, SplatCapture(:x))
        @test expr == MExpr(:call, :+, Capture(:a), SplatCapture(:b))
        @test expr != MExpr(:call, :+, Capture{5}(:a), SplatCapture(:b))
    end
end

@testset "Expr Syntax" begin
    @testset "type_match" begin
        match_expr = :(::Type{Capture(:T)})  |> MExpr
        @test_skip match_expr(:(::Type{Number}))[:T] == :Number
        @test_skip match_expr(:(::Type{T <: Number}))[:T] == :(T <: Number)
    end
    # Remove block?
    # http://mikeinnes.github.io/MacroTools.jl/stable/utilities/#MacroTools.unblock
    # infix_match = :(Capture(:lexpr) = Capture(:rexpr)) |> MExpr
end