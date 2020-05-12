using ExprManipulation
using Base.Meta

function create_expr(lexprs, rexpr)
    idx = 1
    idx_exprs = []
    varnames = []
    n = length(lexprs)
    x = gensym()
    
    for arg in lexprs
        if match_slurp == arg
            j = (n - idx)
            push!(idx_exprs, :($x[$idx:end - $j]))
            idx = -j
            push!(varnames, match(match_slurp, arg)[:var])
        else
            if idx < 0
                push!(idx_exprs, :($x[end $idx]))
            elseif idx == 0
                push!(idx_exprs, :($x[end]))
            else
                push!(idx_exprs, :($x[$idx]))
            end
            push!(varnames, arg)
        end
        idx += 1
    end

    expr = Expr(:block)
    push!(expr.args, Expr(:(=), x, rexpr))

    for (var, idx) in zip(varnames, idx_exprs)
        push!(expr.args, Expr(:(=), var, idx))
    end

    expr
end

match_slurp = MExpr(:..., Capture(:var))
match_assign = MExpr(:(=), MExpr(:tuple, Slurp(:lexprs)), Capture(:rexpr))

macro slurp(expr)
    matches = match(match_assign, expr)
    if isnothing(matches)
        error("Unsupported expression $expr")
    end
    esc(create_expr(matches[:lexprs], matches[:rexpr]))
end

expr = :((a, b..., c) = [1,2,3,4])

matches = match(match_assign, expr)
create_expr(matches[:lexprs], matches[:rexpr]) 

@slurp a, b..., c = [1,2,3,4,5]
@show a b c

@slurp a, b... = [1,2,3,4,5]
@show a b