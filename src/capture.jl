import Base: ==

abstract type AbstractCapture end

(==)(capture::AbstractCapture, expr) = capture.fn(expr)
(==)(expr, capture::AbstractCapture) = capture.fn(expr)

struct Capture{N} <: AbstractCapture
    fn::Function
    val::Symbol
    n::Int

    function Capture{N}(fn::Function, val::Symbol) where {N} 

        if !(N isa Integer) || N < 1
            throw(ArgumentError("Capture{N}(...) N must be a integer greater than 0 was given $N"))
        end

        function inner_fn(expr)
            bool = fn(expr)
            @assert bool isa Bool "The precidate function should always return a Bool"
            bool
        end
        new{N}(inner_fn, val, N)
    end
end

Capture(fn::Function, val::Symbol) = Capture{1}(fn, val)
Capture(val::Symbol) = Capture{1}(x->true, val)
Capture{N}(val::Symbol) where N = Capture{N}(x->true, val)

Base.show(io::IO, capture::Capture{1})  = print(io, "Capture(:", capture.val, ")")
Base.show(io::IO, capture::Capture{N}) where N = print(io, "Capture", "{", Int(N), "}", "(:", capture.val, ")")

struct SplatCapture <: AbstractCapture
    fn::Function
    val::Symbol
    SplatCapture(fn::Function, val::Symbol) = new(fn, val)
end

SplatCapture(val::Symbol) = SplatCapture(x->true, val)