import Base: ==

abstract type AbstractCapture end

(==)(capture::AbstractCapture, expr) = capture.fn(expr)
(==)(expr, capture::AbstractCapture) = capture.fn(expr)

# Takes a single arg and returns a boolean
struct Capture{K} <: AbstractCapture
    fn::Function
    key::Symbol

    function Capture(fn::Function, key::Symbol) 
        function inner_fn(expr)
            bool = fn(expr)
            @assert bool isa Bool "The precidate function should always return a Bool"
            bool
        end
        new{key}(inner_fn, key)
    end
end

Capture(key::Symbol) = Capture(x->true, key)

# Takes array of args and returns a boolean
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