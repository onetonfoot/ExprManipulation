using ExprManipulation
using Base.Meta: show_sexpr

match_assign = MExpr(:(=), Capture(:lexpr), Capture(:rexpr))
match_tuple  = MExpr(:tuple, Slurp(x -> x isa Array{Symbol} ,:keys))

function create_expr(lexpr, rexpr)  
    @assert match_tuple == lexpr "Unsupported left hand expresion $lexpr"
    tmp = gensym()
    expr = Expr(:block, :($tmp = $rexpr))
    args = [:($key = unpack($tmp, Val{$(Expr(:quote, key))}())) for key in lexpr.args ]
    append!(expr.args, args)
    expr
end

create_expr(lexpr::Symbol, rexpr) = :($lexpr = unpack($rexpr, Val{$(Expr(:quote, lexpr))}()))

unpack(x, ::Val{k}) where {k} = getproperty(x, k)
unpack(x::AbstractDict{Symbol}, ::Val{k}) where {k} =  x[k]
unpack(x::AbstractDict{<:AbstractString}, ::Val{k}) where {k} = x[string(k)]

function unpack(expr)
    matches = match(match_assign, expr)
    !isnothing(matches) ? create_expr(matches.lexpr, matches.rexpr) : error("Unsuppored expression $expr")
end

macro unpack(input_expr)
    esc(unpack(input_expr))
end

struct Data
    a
    b
    c
    d
    e
    f
end

data = Data(1, 2, 3 ,4, 5, 6)
dict = Dict(:y=>2, "z"=>3)

@unpack a, b, f = data
@unpack d = data
@unpack y, z = dict