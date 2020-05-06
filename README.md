# ExprManipulation

ExprManipulation proves tools to match and transform expression.

## Motivation

Often expr manipulation code ends up

with the pyramid of doom.

this package tries to provide a framework for expression manipulation that should result in easier to
maintain code.

- Robust - Each component of a MExpr's can be unit easily unit tested
- Reusable - Capture and Transform can be reused in different MExpr's
- Readablity - your MExprs should follow the s-expr syntax

# Equality

MExpr can be used to test equality

# Match

You can extract the matches using `match`

# Transform

# Expresion Matching

## SCapture

Splat capure can only be used at the end of a expression.

<!-- Just like splat in Julia SplatCapture will always match. If no elements are present it will return a empty array -->

# Expression Transformations

Transformation can only be applied if the MExpr == Expr.

## Transform

## STransform

# Examples

For more in depth examples see the examples folder

# Related Packages

Other packages you may find usefull for handling Expr's

- ExprTools
- MacroTools
- MLStyle
