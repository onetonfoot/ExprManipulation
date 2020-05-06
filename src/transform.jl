import Base: ==

abstract type AbstractTransform end

(==)(transfrom::AbstractTransform, expr) = transfrom.capture == expr
(==)(expr , transfrom::AbstractTransform) = transfrom.capture == expr

struct Transform <: AbstractTransform
    fn::Function
    capture::Union{AbstractCapture,Nothing}
end

Transform(fn::Function, key::Symbol) = Transform(fn, Capture(key))
Transform(fn::Function) = Transform(fn, nothing)
(transform::Transform)(capture::AbstractCapture) = Transform(transform.fn, capture)

struct STransform <: AbstractTransform
    fn::Function
    capture::Union{AbstractCapture,Nothing}
end