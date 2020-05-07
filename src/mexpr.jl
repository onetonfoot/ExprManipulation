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
            error("Only one slurp allow per an expression")
        end
        new{head}(head, args)
    end
end

MExpr(head::Symbol)  =  MExpr(head, [])
MExpr(head, args...) where {K} = MExpr(head, collect(args))

(==)(match_expr::MExpr, expr::Expr) = (==)(expr, match_expr)
(==)(match_expr::MExpr, x) = false

Base.match(capture::Capture, arg) = capture.fn(arg) ? Dict(capture.key => arg) : nothing
# Base.match(capture::SplatCapture, args::Array) = capture.fn(args) ? Dict(capture.val => args) : nothing


haschildren(expr::Union{Expr,MExpr}) = !isempty(expr.args)
haschildren(x) = false
children(expr::Union{Expr,MExpr}) = expr.args
children(x) = []


# https://stackoverflow.com/questions/55606017/postorder-traversal-of-an-n-ary-tree
# https://www.geeksforgeeks.org/iterative-postorder-traversal-of-n-ary-tree/?ref=leftbar-rightbar
function postorder(root::MExpr)
    stack = Any[root]
    last_child =  nothing

    while !isempty(stack)
        root = stack[end]
        # node has no child, or one child has been visted, the process and pop it
        if !haschildren(root) || (!isnothing(last_child) &&  last_child in children(root))
            println(root)
            pop!(stack)
            last_child = root
        else
            append!(stack, reverse(root.args))
        end
    end
end

function preorder(root::MExpr)
    stack = Any[root]
    last_child =  nothing

    while !isempty(stack)
        root = pop!(stack)
        println(root)
        # node has no child, or one child has been visted, the process and pop it
        if !haschildren(root) || (!isnothing(last_child) &&  last_child in children(root))
            # LOGIC HERE
            last_child = root
        else
            append!(stack, reverse(root.args))
        end
    end
end

function Base.match(match_expr::MExpr, expr::Expr) 

    values = []

    if match_expr.head != expr.head
        return nothing
    end

    total = 0

    e_idx = 1
    m_idx = 1

    while m_idx <= length(match_expr.args) && e_idx <= length(expr.args)
        arg = expr.args[e_idx]
        m_arg = match_expr.args[m_idx]
        @show m_arg
        @show arg
        if m_arg isa Capture
            matches = match(m_arg, arg)
            if isnothing(matches)
                return nothing
            end
            push!(values, matches)
        # TODO add elseif for slurp
        # elseif m_arg isa Slurp
        #     #
        #     # length(expr.args) - total
        #     args = []
        #     s_idx = e_idx
        #     # while 

        end
        total += 1
        m_idx += 1
        e_idx += 1
    end

    if total != length(expr.args)
        nothing
    else
        merge(values...)
    end
end

function transform(m_expr::MExpr, expr::Expr)

    # don't think this has to be a deepcopy just a copy but need to define copy for structs in package first
    expr = deepcopy(expr)
    m_expr = deepcopy(m_expr)

    @assert m_expr == expr "MExpr != Expr so transformation can't be applied"
    head = m_expr.head isa AbstractTransform ? m_expr.head.fn(expr.head) : expr.head
    args = []

    while !isempty(expr.args) && !isempty(m_expr.args)
        match_arg = popfirst!(m_expr.args)
        if match_arg isa Transform
            arg = poparg!(match_arg.capture, expr.args)
            push!(args, match_arg.fn.(arg)...)
        elseif match_arg isa STransform
            result = match(match_arg, poparg!(match_arg, expr.args))
            push!(args, result...)
        elseif match_arg isa AbstractCapture
            arg = poparg!(match_arg, expr.args)
            push!(args, arg...)
        elseif match_arg isa MExpr
            arg = transform(match_arg, popfirst!(expr.args))
            push!(args, arg)
        else
            push!(args, popfirst!(expr.args))
        end
    end
    # TODO support SplatTransform for head
    Expr(head, args...)
end


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