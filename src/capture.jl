import Base: ==

abstract type AbstractCapture end

"""
* fn(arg::Any) - a function which should return a bool indicating if the variable should be captured
* key          - the key which the arg will be mapped if extracted with `match`
"""
struct Capture <: AbstractCapture
    fn::Function
    key::Symbol
    
    function Capture(fn::Function, key::Symbol) 
        function inner_fn(expr)
            bool = fn(expr)
            @assert bool isa Bool "The precidate function should always return a Bool"
            bool
        end
        new(inner_fn, key)
    end
end

Capture(key::Symbol) = Capture(x->true, key)

"""
* fn(args::Array) - a function which should return a bool indicating if the variable should be captured
* key             - the key which the args will be matched if extracted with `match`
"""
struct Slurp{K} <: AbstractCapture
    fn::Function
    key::Symbol

    function Slurp(fn::Function, key::Symbol) 
        function inner_fn(expr)
            bool = fn(expr)
            @assert bool isa Bool "The precidate function should always return a Bool"
            bool
        end
        new{key}(inner_fn, key)
    end
end

Slurp(key::Symbol) = Slurp(x->true, key)

Base.show(io::IO, capture::Capture) =  print("Capture(:", capture.key, ")")
Base.show(io::IO, capture::Slurp) =  print("Slurp(:", capture.key, ")")

(==)(capture::AbstractCapture, expr) = capture.fn(expr)
(==)(expr, capture::AbstractCapture) = capture.fn(expr)
(==)(x::Slurp, y::Capture) = false
(==)(x::Capture, y::Slurp) = false