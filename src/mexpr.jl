import Base: ==, match
using Base.Meta: show_sexpr

struct MExpr{K} 
    head::Symbol
    args::Array{Any}

    function MExpr(head::Symbol, args::Array)
        seen_slurp = false
        n_slurps = 0
        # TODO convert exprssions inside to MExpr
        for arg in args
            if arg isa Slurp
                n_slurps += 1
            end
        end
        if n_slurps > 1
            throw(ArgumentError("Only one Slurp allow per an expression found $n_slurps"))
        end
        new{head}(head, args)
    end
end

MExpr(head::Symbol)  =  MExpr(head, [])
MExpr(head, args...) = MExpr(head, collect(args))


haschildren(expr::Union{Expr,MExpr}) = !isempty(expr.args)
haschildren(x) = false
children(expr::Union{Expr,MExpr}) = expr.args
children(x) = []

# TODO enable debug logging
function getcaptures(m_expr, expr)

    matched = fill(false, length(expr.args) + 1)
    matched[1]  = m_expr.head == expr.head

    e_i = 1
    m_i = 1
    has_slurp = false
    matches = []
    m_children = []
    e_children = []

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

function preorder(root::MExpr)
    que = Any[root]
    last_child =  nothing

    while !isempty(que)
        root = pop!(que)
        # node has no child, or one child has been visted, the process and pop it
        if !haschildren(root) || (!isnothing(last_child) &&  last_child in children(root))
            # LOGIC HERE
            last_child = root
        else
            append!(que, reverse(root.args))
        end
    end
end

# function transform(m_expr::MExpr, expr::Expr)

#     # don't think this has to be a deepcopy just a copy but need to define copy for structs in package first
#     expr = deepcopy(expr)
#     m_expr = deepcopy(m_expr)

#     @assert m_expr == expr "MExpr != Expr so transformation can't be applied"
#     head = m_expr.head isa AbstractTransform ? m_expr.head.fn(expr.head) : expr.head
#     args = []

#     while !isempty(expr.args) && !isempty(m_expr.args)
#         match_arg = popfirst!(m_expr.args)
#         if match_arg isa Transform
#             arg = poparg!(match_arg.capture, expr.args)
#             push!(args, match_arg.fn.(arg)...)
#         elseif match_arg isa STransform
#             result = match(match_arg, poparg!(match_arg, expr.args))
#             push!(args, result...)
#         elseif match_arg isa AbstractCapture
#             arg = poparg!(match_arg, expr.args)
#             push!(args, arg...)
#         elseif match_arg isa MExpr
#             arg = transform(match_arg, popfirst!(expr.args))
#             push!(args, arg)
#         else
#             push!(args, popfirst!(expr.args))
#         end
#     end
#     # TODO support SplatTransform for head
#     Expr(head, args...)
# end


# function create_expr(match_expr::MExpr, replace_capture)
#     head = match_expr.head
#     expr =  Expr(head isa Symbol ? head : :_)
#     for arg in match_expr.args
#         arg = if arg isa Capture && replace_capture
#             :_
#         elseif arg isa MExpr
#             create_expr(arg, replace_capture)
#         else
#             arg
#         end
#         push!(expr.args, arg)
#     end
#     expr
# end

# Base.show(io::IO, expr::MExpr) = show(create_expr(expr, true))
# Meta.show_sexpr(expr::MExpr) = show_sexpr(create_expr(expr, false))