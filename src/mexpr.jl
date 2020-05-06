import Base: ==, match
using Base.Meta: show_sexpr

struct MExpr
    head::Union{Symbol,AbstractCapture,AbstractTransform}
    args::Array{Any}

    function MExpr(head::Union{Symbol,Capture}, args::Array)
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
# Is this guy needed?
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

    if match_expr != expr
        return nothing
    end
    values = []
    # don't think this has to be a deepcopy just a copy but need to define copy for MExpr
    expr = deepcopy(expr)
    match_expr = deepcopy(match_expr)

    while !isempty(expr.args) && !isempty(match_expr.args)
        match_arg = popfirst!(match_expr.args)
        if match_arg isa Union{AbstractCapture,AbstractTransform,MExpr}
            result = match(match_arg, poparg!(match_arg, expr.args))
            push!(values, result)
        else
            popfirst!(expr.args)
        end
    end
    return merge(values...)
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