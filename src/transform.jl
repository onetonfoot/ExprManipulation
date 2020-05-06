import Base: ==

abstract type AbstractTransform end

(==)(transfrom::AbstractTransform, expr) = transfrom.capture == expr
(==)(expr , transfrom::AbstractTransform) = transfrom.capture == expr

struct Transform <: AbstractTransform
    fn::Function
    capture::Union{Capture,SplatCapture}
end

Transform(fn::Function, key::Symbol) = Transform(fn, Capture(key))

struct STransform <: AbstractTransform
    fn::Function
    capture::Union{Capture,SplatCapture}
end
