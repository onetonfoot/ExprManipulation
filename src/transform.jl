# TODO consider defining preoder transformation even though this could lead to infinite recursion
"""
Apply transformation function to each node in the expression starting from leave nodes and working back up
"""
function transform(fn::Function, expr)
    parent = expr
    kids = children(expr)
    if isempty(kids)
        fn(parent)
    else
        kids = map(child->transform(fn, child), kids)
        fn(Expr(expr.head, kids...))
    end
end