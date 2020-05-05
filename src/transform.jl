# TODO use holy trait to enforce function signature (key::Symbol, expr) 
function transform(fn::Function, match_expr::MExpr, expr::Expr)
    @assert match_expr == expr "$match_expr != $expr therefore cannot apply transform"
    args = map(zip(match_expr.args, expr.args)) do (match_arg, arg)
        if match_arg isa Capture && match_arg.fn(arg)
            fn(match_arg.val, arg)
        else
            arg
        end
    end
    Expr(expr.head, args...)
end