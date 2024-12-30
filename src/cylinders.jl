export Cylinder, slide!, stick!

"""
    Cylinder(origin, height, radius)
Representation of a cylinder with given `radius` and `height`
whose center of mass is fixed at `origin`.
"""
struct Cylinder{D} <: AbstractBody
    origin::SVector{D,Float64}
    height::Float64
    radius::Float64

    Cylinder(origin::SVector{D,<:Real}, height::Real, radius::Real) where {D} = 
        new{D}(Float64.(origin), Float64(height), Float64(radius))
end


function slide!(microbe::SurfyMicrobe{2}, cylinder::Cylinder{2}, model)
    if ~microbe.is_stuck
        stick!(microbe, cylinder, model)
        model.slidingdirection[microbe.id] = slidedirection(microbe, cylinder, model)
        return microbe # type stability
    end
    s = model.slidingdirection[microbe.id]
    Δt = model.timestep
    R = microbe.radius + cylinder.radius
    ω = s * microbe.speed_surface / R
    d = distancevector(cylinder, microbe, model)
    θ = atan(d[2], d[1]) + ω*Δt
    δ = SVector(R*cos(θ), R*sin(θ))
    new_pos = normalize_position(MicrobeAgents._pos(cylinder) .+ δ, model)
    move_agent!(microbe, new_pos, model)
end

function slide!(microbe::SurfyMicrobe{3}, cylinder::Cylinder{3}, model)
    if ~microbe.is_stuck
        stick!(microbe, cylinder, model)
        model.slidingdirection[microbe.id] = slidedirection(microbe, cylinder, model)
        return microbe # type stability
    end
    s = model.slidingdirection[microbe.id]
    Δt = model.timestep
    R = microbe.radius + cylinder.radius
    Uxy = sqrt(microbe.vel[1]^2 + microbe.vel[2]^2) * microbe.speed_surface
    ω = s * Uxy / R
    d = distancevector(cylinder, microbe, model)
    θ = atan(d[2], d[1]) + ω*Δt
    Uz = microbe.vel[3] * microbe.speed_surface * Δt
    δ = SVector(R*cos(θ), R*sin(θ), Uz)
    p = SVector(cylinder.origin[1], cylinder.origin[2], microbe.pos[3])
    new_pos = normalize_position(p.+ δ, model)
    move_agent!(microbe, new_pos, model)
end


"""
    slidedirection(microbe, cylinder, model)
Determines the sense in which `microbe` slides along `cylinder`
based on its velocity at impact.
Used in `slide!`.
"""
function slidedirection(microbe::AbstractMicrobe{2}, cylinder::Cylinder{2}, model)
    # rotation_between only works with 3d vectors
    d = distancevector(cylinder, microbe, model)
    u = [d[1], d[2], 0.0]
    M = rotation_between(u, [1.0, 0.0, 0.0])
    Uy = M[2,1] * microbe.vel[1] + M[2,2] * microbe.vel[2]
    Uy ≥ 0 ? +1 : -1
end
function slidedirection(microbe::AbstractMicrobe{3}, cylinder::Cylinder{3}, model)
    d = collect(distancevector(cylinder, microbe, model))
    M = rotation_between(d, [1.0, 0.0, 0.0])
    Uy = M[2,1] * microbe.vel[1] + M[2,2] * microbe.vel[2]
    Uy ≥ 0 ? +1 : -1
end


function stick!(microbe::SurfyMicrobe{D}, cylinder::Cylinder{D}, model) where {D}
    R = microbe.radius + cylinder.radius
    R² = R*R
    d = distancevector(microbe, cylinder, model)
    d² = sum(abs2.(d))
    c = d² - R²
    if c < 0
        # step microbe backward to the cylinder surface
        Δt = model.timestep
        s = @. -microbe.vel * microbe.speed * Δt
        a = sum(abs2.(s))
        b = -2 * dot(d, s)
        ε = -b / 2a * (1 - sqrt(1 - 4a*c/b^2))
        walk!(microbe, ε.*s, model)
    end
    microbe.is_stuck = contact(microbe, cylinder, model)
    # if escape prob > 0 microbe may escape immediately
    if microbe.escape_probability > 0
        if rand(abmrng(model)) < microbe.escape_probability
            # try escape until a valid direction is found
            while microbe.is_stuck
                try_turn!(microbe, model)
            end
        end
    end
    microbe
end


@inline radius(c::Cylinder) = c.radius
@inline MicrobeAgents._pos(c::Cylinder{2}) = c.origin
@inline MicrobeAgents.distance(a::Cylinder{3}, b, model) = distance(b, a, model)
@inline function MicrobeAgents.distance(a, b::Cylinder{3}, model)
    p = MicrobeAgents._pos(a)
    pxy = SVector(p[1], p[2], 0.0)
    q = b.origin
    qxy = SVector(q[1], q[2], 0.0)
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
