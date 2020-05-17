# ExprManipulation

[![Build Status](https://travis-ci.com/onetonfoot/ExprManipulation.jl.svg?branch=master)](https://travis-ci.com/onetonfoot/ExprManipulation.jl)
[![Coverage Status](https://coveralls.io/repos/github/onetonfoot/ExprManipulation.jl/badge.svg?branch=master)](https://coveralls.io/github/onetonfoot/ExprManipulation.jl?branch=master)

ExprManipulation provides tools for manipulating expressions based on the Expr syntax.

# Intro

The API is small there are only 4 constructs `MExpr`, `Capture`, `Slurp` and `transform`.

## Equality

```julia
using ExprManipulation
using Base.Meta: show_sexpr

expr = :(x + 1)
show_sexpr(expr)
# (:call, :+, :x, 1)
```

A MExpr can be used to test equality

```julia
m_expr = MExpr(:call, :+, Capture(:x), Capture(:n))
m_expr == expr
#true
```

## Match

You can extract the the captured arguments with `match`, if the expressions aren't equal `match` will return nothing

```julia
match(m_expr, expr)
#(x = :x, n = 1)
```

`Slurp` allows you to capture a variable number of arguments. It can be used anywhere in the expressions args but only a single `Slurp` per an `MExpr`.

```julia
m_expr = MExpr(:tuple, Capture(:first_number), Slurp(:args), Capture(:last_number))
match(m_expr, :(1,2,3,4,5))
# (first_number = 1, args = Any[2, 3, 4], last_number = 5)
```

Both `Capture` and `Slurp` can take a function to test equality.

```julia
head = Capture(:head) do arg
    arg in (:vect, :tuple)
end

slurp_numbers = Slurp(:numbers) do args::Array
    all(map(x -> x isa Number, args))
end

vec_or_tuple = MExpr(head, slurp_numbers)

match(vec_or_tuple, :((1,2,3)))
# (head = :tuple, numbers = [1, 2, 3])

match(vec_or_tuple, :((1,"2",3)))
# nothing
```

## Transform

Transform can be used to create a new expression, it applies a function to each node in the Expr tree starting from the leaves. For example to replace all the numbers with 1.

```julia
transform(input_expr) do node
    node isa Number ? 1 : node
end
# :(1 + (1 ^ 1) * 1)
```

# Examples

For more in-depth examples see the examples folder.

# Related Packages

Other packages you may find usefull for handling Exprs

- ExprTools
- MacroTools
- MLStyle
