using ExprManipulation: MExpr, Capture, SplatCapture
using Test
using Base.Meta: show_sexpr

@testset "Constructor" begin
    # TODO make sure head can only be Capture{1} or Symbol or Transform(Capture{1})
    MExpr(:call)
    MExpr(:call, Capture{2}(:x))
    MExpr(:call, SplatCapture(:x))
    MExpr(:call, Capture(:x), SplatCapture(:y))
    @test_throws ArgumentError MExpr(:call, SplatCapture(:y), Capture(:x))
end

# TODO: should probably refactor so tests for Equality and Match are Seperate
@testset "Equality" begin

    @testset "infix_match" begin
        infix_match = MExpr(:call, Capture(:op), Capture(:lexpr), Capture(:rexpr))
        expr1 = :(x + 10) 
        expr2 = :(x .~ Normal(μ, σ))
        @test infix_match == expr2
        @test infix_match == expr1
    end

    @testset "tilde_match" begin
        istilde = x->x == :.~ || x == :~
        tilde_match = MExpr(:call, 
            Capture(istilde,  :op), 
            Capture(:lexpr), 
            Capture(:rexpr)
        )

        @test tilde_match == :(x  ~ Normal(μ, 1))
        @test tilde_match == :(x  .~ Normal(μ, 1))
        @test tilde_match == :(x[:,1]  .~ Normal(μ, 1))
        @test tilde_match != :(x  + Normal(μ, 1))
    end

    @testset "type_match" begin
        type_match = MExpr(:(::), MExpr(:curly, :Type, Capture(:t_expr)))
        @test type_match == :(::Type{T})
        @test type_match == :(::Type{T <: Real})
    end

    @testset "head_match" begin
        match_expr = MExpr(Capture(:head))
        @test Expr(:call) == match_expr

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

        splat_capture = SplatCapture(:args) do args
            all(map(x->x isa String, args))
        end

        string_expr = :((*)("1", "2", "3"))
        number_expr = :((*)(1, 2, 3))

        @test MExpr(:call, :*, splat_capture) == string_expr
        @test MExpr(:call, :*, splat_capture) != number_expr
    end

    @testset "heavily nested" begin
        expr = :( (x^3 + 10)  / 2)
        show_sexpr(expr)
        m_expr = MExpr(:call, :/, MExpr(:call, :+, MExpr(:call, Capture(:power), :x, 3), 10), 2)
        m_expr == expr
    end
end


@testset "Match" begin


    @testset "infix_match" begin
        infix_match = MExpr(:call, Capture(:op), Capture(:lexpr), Capture(:rexpr))
        expr1 = :(x + 10) 
        expr2 = :(x .~ Normal(μ, σ))

        matches1 = match(infix_match, expr1)
        @test matches1[:lexpr] == :x
        @test matches1[:op] == :+
        @test matches1[:rexpr] == 10

        matches2 = match(infix_match, expr2)
        @test matches2[:lexpr] == :x
        @test matches2[:op] == :.~
        @test matches2[:rexpr] == :(Normal(μ, σ))
    end

    @testset "heavily nested" begin
        expr = :( (x^3 + 10)  / 2)
        m_expr = MExpr(:call, :/, MExpr(:call, :+, MExpr(:call, Capture(:op), :x, Capture(:n)), 10), 2)
        result = match(m_expr, expr)
        @test result[:op] == :^
        @test result[:n] == 3
    end

    @testset "SplatCapture" begin
        isnumber = x->x isa Number
        number_expr = :((*)(1, 2, 3))
        string_expr = :((*)("1", "2", "3"))
        m_expr = MExpr(:call, :*, SplatCapture(x->all(isnumber.(x)), :numbers))

        @test match(m_expr, number_expr)[:numbers] == [1,2,3]
        @test match(m_expr, string_expr) == nothing
    end
end

# TODO play around with Normal Expr Syntax once MExpr more robust
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