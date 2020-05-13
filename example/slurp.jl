using ExprManipulation

match_slurp = MExpr(:..., Capture(:var))
match_assign = MExpr(:(=), MExpr(:tuple, Slurp(:lexprs)), Capture(:rexpr))

function create_expr(lexprs, rexpr)
    i = 1
    n = length(lexprs)
    x = gensym()

    expr = Expr(:block)
    push!(expr.args, Expr(:(=), x, rexpr))
    
    for var in lexprs
        if match_slurp == var
            j = (n - i)
            idx =  :($x[$i:end - $j])
            var = match(match_slurp, var)[:var]
            push!(expr.args, Expr(:(=), var, idx))
            i = -j
        elseif var isa Symbol
            if i < 0
                push!(expr.args, Expr(:(=), var, :($x[end $i])))
            elseif i == 0
                push!(expr.args, Expr(:(=), var, :($x[end])))
            else
                push!(expr.args, Expr(:(=), var, :($x[$i])))
            end
        else
            error("Unsupported expr on left hand side $var")
        end
        i += 1
    end
    expr
end

macro slurp(expr)
    matches = match(match_assign, expr)
    if isnothing(matches)
        error("Unsupported expression $expr")
    end
    esc(create_expr(matches[:lexprs], matches[:rexpr]))
end

@slurp a, b..., c = [1,2,3,4,5]
@show a b c

@slurp a, b... = [1,2,3,4,5]
@show a b

@macroexpand @slurp a, b..., c = [1,2,3,4,5]