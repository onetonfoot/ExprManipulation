import Base: ==
using Base.Meta: show_sexpr

struct MExpr
    head::Symbol
    args::Array{Any}

    function MExpr(head::Symbol, args::Array)
        seen_capture = false
        for (idx, arg) in enumerate(args)
            if arg isa SplatCapture && idx != length(args)
                throw(ArgumentError("SplatCapture can only be used as final argument in MExpr"))
            end
        end
        new(head, args)
    end
end


MExpr(head::Symbol) = MExpr(head, [])
MExpr(head, arg) = MExpr(head, [arg])
MExpr(head, arg, vargs...) = MExpr(head, [arg, vargs...])

match_capture = MExpr(:call, :Capture, :_)

function MExpr(expr::Expr) 
    args = map(expr.args) do arg
        if arg == match_capture
            eval(arg)
        elseif arg isa Expr
            MExpr(arg)
        else
            arg
        end
    end
    MExpr(expr.head, args)
end

function f(l::Array, i::Int, j::Int) 
    if j <= length(l)
        l[i:j]
    else
        nothing
    end
end


# TODO add support for matching Capture for head
function (==)(expr::Expr, match_expr::MExpr) 
    if expr.head != match_expr.head 
        return false
    end

    m_idx = 1
    e_idx = 1
    total_n = 0
    while e_idx <= length(expr.args) && m_idx <= length(match_expr.args)
        match_arg = match_expr.args[m_idx]
        arg = expr.args[e_idx]
        if match_arg == :_
            m_idx += 1
            e_idx += 1
            total_n += 1
            continue
        elseif match_arg isa Capture
            n = match_arg.n
            l = f(expr.args, e_idx, e_idx + n - 1)
            if isnothing(l)
                return false
            end
            result = match_arg.fn.(l)

            if length(result) == n && all(result)
                total_n += n
                m_idx += 1
                e_idx += n
            else
                return false
            end
        elseif match_arg isa SplatCapture
            return true
        elseif match_arg == arg
            m_idx += 1
            e_idx += 1
            total_n += 1
        else 
            return false
        end
    end

    if total_n != length(expr.args)
        return false
    end

    return true
end

(==)(match_expr::MExpr, expr::Expr) = (==)(expr, match_expr)
(==)(match_expr::MExpr, x) = false
(==)(x, match_expr::MExpr) = false

function (match_expr::MExpr)(expr::Expr) 
    @assert match_expr == expr "The $match_expr != $expr so can't be used to extract variables"
    values = []

    foreach(zip(expr.args, match_expr.args)) do (arg, match_arg) 
        if match_arg isa Capture
            push!(values, Dict(match_arg.val => arg))
        elseif match_arg isa MExpr
            push!(values, match_arg(arg))
        end
    end
    filter!(!isnothing, values)
    # TODO should warn if duplicate keys exist!
    merge(values...)
end

function create_expr(match_expr::MExpr, replace_capture)
    expr =  Expr(match_expr.head)
    for arg in match_expr.args
        arg = if arg isa Capture && replace_capture
            :_
        elseif arg isa MExpr
            create_expr(arg, replace_capture)
        else
            arg
        end
        push!(expr.args, arg)
    end
    expr
end

Base.show(io::IO, expr::MExpr) = show(create_expr(expr, true))
Meta.show_sexpr(expr::MExpr) = show_sexpr(create_expr(expr, false))
