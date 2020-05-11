import Base: ==, match
using Base.Meta: show_sexpr

struct MExpr
    head::Union{Symbol,Capture}
    args::Array{Any}

    function MExpr(head::Union{Symbol,Capture}, args::Array)
        seen_slurp = false
        n_slurps = 0
        for arg in args
            if arg isa Slurp
                n_slurps += 1
            end
        end
        if n_slurps > 1
            throw(ArgumentError("Only one Slurp allowed per an MExpr found $n_slurps"))
        end
        new(head, args)
    end
end

MExpr(head::Union{Symbol,Capture})  =  MExpr(head, [])
MExpr(head, args...) = MExpr(head, collect(args))

haschildren(expr::Union{Expr,MExpr}) = !isempty(expr.args)
haschildren(x) = false
children(expr::Union{Expr,MExpr}) = expr.args
children(x) = []

function getcaptures(m_expr, expr)

    matched = fill(false, length(expr.args) + 1)
    matched[1]  = m_expr.head == expr.head


    e_i = 1
    m_i = 1
    has_slurp = false
    matches = m_expr.head isa Capture ? Any[m_expr.head.key => expr.head]  : []
    m_children = []
    e_children = []

    # TODO clean up
    while length(expr.args) >= e_i && length(m_expr.args) >= m_i
        arg = expr.args[e_i]
        m_arg = m_expr.args[m_i]
        if m_arg isa Slurp
            has_slurp = true
            # Find number of captures left
            n = length(m_expr.args[(e_i + 1):end])
            n_ele = length(expr.args[e_i:end])
            # Get Slurp Index
            j = e_i + n_ele - n - 1
            args = expr.args[e_i:j]
            bool = m_arg.fn(args)
            matched[(e_i + 1):(j + 1)] .= bool
            if bool
                push!(matches, m_arg.key => args)
            end
            e_i += length(e_i:j)
            m_i += 1
        elseif m_arg isa Capture
            bool = m_arg == arg
            matched[e_i + 1] = bool
            if bool
                push!(matches, m_arg.key => arg)
            end
            e_i += 1
            m_i += 1
        elseif m_arg isa MExpr
            bool = if arg isa Expr
                push!(m_children, m_arg)
                push!(e_children, arg)
                true
            else
                false
            end
            matched[e_i + 1] = bool
            e_i += 1
            m_i += 1
        else
            matched[e_i + 1] = arg == m_arg
            e_i += 1
            m_i += 1
        end
    end

    all_matched = all(matched)
    # TO FEW CAPTURES
    if length(m_expr.args) < length(expr.args) && !has_slurp 
        all_matched = false
    # TO MANY CAPTURES
    elseif length(m_expr.args) > length(expr.args)
        all_matched = false
    end

    (matches, (m_children, e_children), all_matched)
end

function Base.match(m_expr::MExpr, expr::Expr)
    que = Any[(m_expr, expr)]
    last_child =  nothing
    values = []
    while !isempty(que)
        root = pop!(que)
        m_expr, expr = root
        (matches, children, all_matched) = getcaptures(m_expr, expr)
        append!(values, matches)
        if !all_matched
            return nothing
        end

        (m_children, e_children) = children
        for (m_child, child) in zip(m_children, e_children)
            push!(que,  (m_child, child))
        end
    end
    return Dict(values...)
end


Base.match(m_expr::MExpr, x) = nothing

(==)(m_expr::MExpr, expr::Expr) = !isnothing(match(m_expr, expr))
(==)(expr::Expr, m_expr::MExpr) = m_expr == expr

# TODO define nice show methods