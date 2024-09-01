export Cylinder, slide!, stick!

"""
    Rectangle(origin, edge_x, edge_y, orientation)
Representation of a rectangle with edges `edge_x` and `edge_y`
centered at `origin` with `orientation` with respect to the x axis.
Only two-dimensional.
"""
struct Rectangle <: AbstractBody
    origin::SVector{2,Float64}
    edge_x::Float64
    edge_y::Float64
    orientation::Float64

    Rectangle(origin::SVector{2,<:Real}, ax::Real, ay::Real, θ::Real=0) =
        new(Float64.(origin), Float64(ax), Float64(ay), Float64(θ))
end

"""
    sdf(pos, rect)
Signed distance function of the rectangle in two dimensions.
"""
function sdf(pos::SVector{2,<:Real}, rect::Rectangle)
    a = (rect.edge_x, rect.edge_y)
    edge_distance = abs.(pos .- rect.origin) .- a
    outside_distance = norm(max(z,0) for z in edge_distance)
    inside_distance = min(maximum(edge_distance), 0)
    return inside_distance + outside_distance
end

function stick!(microbe::SurfyMicrobe{2}, rectangle::Rectangle, model)
    pos = microbe.pos
    dist = sdf(pos, rectangle)
    if dist < 0
        # find closest intersection and step microbe
        Δt = model.timestep
        s = @. microbe.vel * microbe.speed * Δt
        pos_old = pos .- s
        dist_old = sdf(pos_old, rectangle)
        ε = -(dist_old - dist) / (microbe.speed * Δt)
        walk!(microbe, ε.*s, model)
    end
    microbe.is_stuck = dist <= 0
    microbe
end


@inline MicrobeAgents._pos(c::Rectangle) = c.origin
@inline MicrobeAgents.distance(a::Rectangle, b, model) = distance(b, a, model)
@inline function MicrobeAgents.distance(a, b::Rectangle, model)
    p = MicrobeAgents._pos(a)
    edges = SVector{2}(rect.edge_x, rect.edge_y)
    u = distance
    edge_distance = distance(p,)
    distance(pxy, qxy, model)
end
@inline MicrobeAgents.distancevector(a::Cylinder{3}, b, model) = .-distancevector(b, a, model)
@inline function MicrobeAgents.distancevector(a, b::Cylinder{3}, model)
    p = MicrobeAgents._pos(a)
    pxy = SVector(p[1], p[2], 0.0)
    q = b.origin
    qxy = SVector(q[1], q[2], 0.0)
    distancevector(pxy, qxy, model)
end
