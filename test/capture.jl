using ExprManipulation: getcaptures

@testset "getcaptures" begin
    # NORMAL ARGS
    expr = :([1,2,3,4])
    m_expr = MExpr(:vect, 1, 2, 3, 4)
    (matches, children, all_matched) = getcaptures(m_expr, expr)
    @test all_matched

    # TOO MANY CAPUTES
    expr = :([1])
    m_expr = MExpr(:vect, Capture(:x), Capture(:y))
    (matches, children, all_matched) = getcaptures(m_expr, expr)
    @test !all_matched

    # TOO FEW CAPUTES
    expr = :([1,2,3])
    m_expr = MExpr(:vect, Capture(:x), Capture(:y))
    (matches, children, all_matched) = getcaptures(m_expr, expr)
    @test !all_matched

    # SLURP START
    expr = :([1,2,3,4])
    m_expr = MExpr(:vect, Slurp(:elements))
    (matches, children, all_matched) = getcaptures(m_expr, expr)
    @test all_matched

    # SLURP END
    expr = :([1,2,3,4])
    m_expr = MExpr(:vect, Capture(:x), Slurp(:elements))
    (matches, children, all_matched) = getcaptures(m_expr, expr)
    @test all_matched 

    # SLURP MIDDLE
    expr = :([1,2,3,4])
    m_expr = MExpr(:vect, Capture(:x), Slurp(:elements), Capture(:y))
    (matched, children, all_matched) = getcaptures(m_expr, expr)
    @test all_matched

    # NESTED
    expr = :((x + 1)^2)
    m_expr = MExpr(:call, :^, MExpr(:call, :+, Slurp(:args)), Capture(:power_n))
    (matched, (m_children, e_children), all_matched) =  getcaptures(m_expr, expr)
    @test length(m_children) == length(e_children)
end