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
    s, c = sincos(rect.orientation)
    x, y = pos .- rect.origin
    u = (c*x + s*y, c*y - s*x)
    a = (rect.edge_x, rect.edge_y)
    edge_distance = abs.(u) .- a
    outside_distance = norm(max(z,0) for z in edge_distance)
    inside_distance = min(maximum(edge_distance), 0)
    return inside_distance + outside_distance
end

# HACK: Only works for orthogonally centered rectangles!
# Don't use otherwise
function slide!(microbe::SurfyMicrobe{2}, rectangle::Rectangle, model; ε=1e-3)
    if ~microbe.is_stuck
        stick!(microbe, rectangle, model)
        # model.slidingdirection[microbe.id] = slidedirection(microbe, rectangle, model)
        model.slidingdirection[microbe.id] = rand(abmrng(model), (-1,1))
        return microbe
    end
    s = model.slidingdirection[microbe.id]
    Δt = model.timestep
    x, y = microbe.pos
    rx, ry = rectangle.origin
    Ax, Ay = rectangle.edge_x, rectangle.edge_y
    if (x < (1+ε)*(rx-Ax) || x > (1-ε)*(rx+Ax)) && (ry-Ay < y < ry+Ay)
        # stuck on left / right side, orient along y
        microbe.vel = SVector(0, s)
    else
        # stuck on top / bottom side, orient along x
        microbe.vel = SVector(s, 0)
    end
    Δt = model.timestep
    # move_agent!(microbe, model, microbe.speed*Δt)
    walk!(microbe, microbe.vel .* microbe.speed .* Δt, model)
    microbe.is_stuck = sdf(microbe.pos, rectangle) <= 0
    # return microbe # type stability
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

function rectangles_intersect(A::Rectangle, B::Rectangle)
    cA = A.origin
    cB = B.origin
    θA = A.orientation
    scA = sincos(-θA)
    θB = B.orientation
    scB = sincos(-θB)
    axA = (A.edge_x, A.edge_y)
    axB = (B.edge_x, B.edge_y)
    offsets = [(-1,-1), (-1,+1), (+1,-1), (+1,+1)]
    vtxA = map(offsets) do offset
        x0, y0 = offset .* axA
        s, c = scA
        x = c*x0 + s*y0
        y = c*y0 - s*x0
        SVector{2}(x + cA[1], y + cA[2])
    end
    vtxB = map(offsets) do offset
        x0, y0 = offset .* axB
        s, c = scB
        x = c*x0 + s*y0
        y = c*y0 - s*x0
        SVector{2}(x + cB[1], y + cB[2])
    end
    xs_A = first.(vtxA)
    ys_A = last.(vtxA)
    xs_B = first.(vtxB)
    ys_B = last.(vtxB)
    leftX_A, rightX_A = extrema(xs_A)
    leftX_B, rightX_B = extrema(xs_B)
    bottomY_A, topY_A = extrema(ys_A)
    bottomY_B, topY_B = extrema(ys_B)
    x_within = any(leftX_A .<= xs_B .<= rightX_A)
    y_within = any(bottomY_A .<= ys_B .<= topY_A)
    println(x_within)
    println(y_within)
    if ((bottomY_A <= topY_B <= topY_A) && x_within) ||
        ((bottomY_A <= bottomY_B <= topY_A) && x_within) ||
        ((leftX_A <= leftX_B <= rightX_A) && y_within) ||
        ((leftX_A <= rightX_B <= rightX_A) && y_within)
        return true
    else
        return false
    end
end

@inline radius(r::Rectangle) = max(r.edge_x, r.edge_y)
@inline MicrobeAgents._pos(r::Rectangle) = r.origin
@inline MicrobeAgents.distance(a::Rectangle, b, model) = distance(b, a, model)
@inline function MicrobeAgents.distance(a, b::Rectangle, model)
    p = MicrobeAgents._pos(a)
    sdf(p, b)
end
