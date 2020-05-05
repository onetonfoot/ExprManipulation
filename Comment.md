During refactoring to use ExprTool.jl I was playing around with another idea to handle the AST maniulation.

Here's a snippet

```julia
julia> type_match
:(::Type{_}) #underscore indicates a capture field
julia> type_match |> show_sexpr
(:(::), (:curly, :Type, Capture(:t_expr)))
```

The main benefits I can see are

- Capture - predicate functions can be used to perform validation and show warning
- MExpr - each can be unit tested easily and reused
- Readablity/Explict - I defined show methods so the matcher should be self documenting for example type_match looks like

* Currently under 200 loc and no dependencies.

In my fork the match expr code is in `match_expr.jl` and I've refactored `build_model`, `get` to use it.
Thoughts on this direction? If no objections I'll carry on.

I could refactor it into another package, thinking to call it ExprMatch.jl or MatchExpr.jl.

Started to look at little bit at the code generation using this I'm feeling something like

```julia
new_expr = transfrom(match_expr, old_expr) do key, expr
    #...
    return transformed_expr
end
```

Key is the symbol key is the symbol in the Capture(:key) and expr is the matched expr. The transform funciton
will only work if the `match_expr == old_expr` preventing errors

You can see more in the README in ExprManiuplation.jl
