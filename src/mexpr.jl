import Base: ==, match
using Base.Meta: show_sexpr

struct MExpr
    head::Union{Symbol,AbstractCapture,AbstractTransform}
    args::Array{Any}

    function MExpr(head::Union{Symbol,AbstractCapture,AbstractTransform}, args::Array)
        seen_capture = false
        for (idx, arg) in enumerate(args)
            if arg isa SplatCapture && idx != length(args)
                throw(ArgumentError("SplatCapture can only be used as final argument in MExpr"))
            end
        end
        new(head, args)
    end
end

MExpr(head) = MExpr(head, [])
MExpr(head, arg) = MExpr(head, [arg])
MExpr(head, arg, vargs...) = MExpr(head, [arg, vargs...])
match_capture = MExpr(:call, :Capture, :_)

poparg!(m_expr::MExpr, array::Array) = popfirst!(array) 
poparg!(capture::Capture{N}, array::Array) where N =  length(array) < N ? nothing : [popfirst!(array) for i in 1:N]
function poparg!(capture::SplatCapture, array::Array)
    values = []
    for i in 1:length(array)
        push!(values, popfirst!(array))
    end
    values
end

(==)(match_expr::MExpr, expr::Expr) = (==)(expr, match_expr)
(==)(match_expr::MExpr, x) = false
(==)(x, match_expr::MExpr) = false

function (==)(expr::Expr, match_expr::MExpr) 

    if match_expr.head != expr.head
        return false
    end

    total_n = 0
    n_args = length(expr.args)
    expr = deepcopy(expr)
    match_expr = deepcopy(match_expr)

    # TODO add support for :_
    while !isempty(expr.args) && !isempty(match_expr.args)
        match_arg = popfirst!(match_expr.args)
        match_arg = match_arg isa AbstractTransform ? match_arg.capture :  match_arg
        if isnothing(match_arg)
            # TODO better error message
            error("Transform has no associated capture so can't be used yet")
        end
        if match_arg isa Capture
            args = poparg!(match_arg, expr.args)
            if isnothing(args)
                return false
            elseif all(match_arg.fn.(args))
                total_n += length(args)
            else
                return false
            end
        elseif match_arg isa SplatCapture
            arg = poparg!(match_arg, expr.args)
            if match_arg != arg
                return false
            end
            total_n += length(arg)
        elseif match_arg == popfirst!(expr.args)
            total_n += 1
        else
            return false
        end
    end
    total_n == n_args
end

Base.match(capture::Capture{1}, expr::Array) = Dict(capture.val => expr[1])
Base.match(capture::Capture{N}, expr::Array) where N = Dict(capture.val => expr)
Base.match(capture::SplatCapture, expr::Array) = Dict(capture.val => expr)
Base.match(transform::AbstractTransform, expr) = match(transform.capture, expr)

function Base.match(match_expr::MExpr, expr::Expr) 

    values = []

    if match_expr != expr
        return nothing
    end

    if match_expr.head isa Union{AbstractCapture,AbstractTransform}
        push!(values, match(match_expr.head, [expr.head]))
    end
        
    # don't think this has to be a deepcopy just a copy but need to define copy for MExpr
    expr = deepcopy(expr)
    match_expr = deepcopy(match_expr)

    while !isempty(expr.args) && !isempty(match_expr.args)
        match_arg = popfirst!(match_expr.args)
        if match_arg isa Union{AbstractCapture,AbstractTransform,MExpr}
            match_arg = match_arg isa AbstractTransform ? match_arg.capture :  match_arg
            result = match(match_arg, poparg!(match_arg, expr.args))
            push!(values, result)
        else
            popfirst!(expr.args)
        end
    end
    return merge(values...)
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

function create_expr(match_expr::MExpr, replace_capture)
    head = match_expr.head
    expr =  Expr(head isa Symbol ? head : :_)
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