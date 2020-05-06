struct Transform
    fn::Function
    capture::Union{Capture,SplatCapture}
end

struct STrasform
    fn::Function
    capture::Union{Capture,SplatCapture}
end


function transform2(mexpr::MExpr, expr::Expr)

end


# TODO use holy trait to enforce function signature (key::Symbol, expr) 
function transform(fn::Function, match_expr::MExpr, expr::Expr)
    @assert match_expr == expr "$match_expr != $expr therefore cannot apply transform"

    args = []
    m_idx = 1
    e_idx = 1

    head = if match_expr.head isa Capture
        fn(match_expr.head.val, expr.head)
    else
        expr.head
    end

    while e_idx <= length(expr.args) && m_idx <= length(match_expr.args)
        # I don't think I need this && seen the == 
        match_arg = match_expr.args[m_idx]
        arg = expr.args[e_idx]
        if match_arg isa Capture && match_arg.fn(arg)
            n = match_arg.n
            if n <= 1
                new_expr = fn(match_arg.val, arg)
                push!(args, new_expr)
                e_idx += 1
                m_idx += 1
            else
                idx = e_idx:(e_idx + n - 1)
                new_expr = fn(match_arg.val, expr.args[])
                push!(args, new_expr)
                e_idx += n
                m_idx += 1
            end
        elseif match_arg isa SplatCapture
            push!(args, fn(match_arg.val, expr.args[e_idx:end]))
            break
        elseif match_arg isa MExpr
            push!(args, transform(fn, match_arg, arg))
            m_idx += 1
            e_idx += 1
        else
            push!(args, arg)
            m_idx += 1
            e_idx += 1
        end
    end

    Expr(head, args...)
end
