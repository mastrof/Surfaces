export Sphere, stick!

"""
    Sphere(origin, radius)
Representation of a sphere with given `radius` centered at `origin`
"""
struct Sphere <: AbstractBody
    origin::SVector{3,Float64}
    radius::Float64

    Sphere(origin::SVector{3,<:Real}, radius::Real) =
        new(Float64.(origin), Float64(radius))
end

function stick!(microbe::SurfyMicrobe{3}, sphere::Sphere, model)
    R = microbe.radius + sphere.radius
    R² = R*R
    d = distancevector(microbe, sphere, model)
    d² = sum(abs2.(d))
    c = d² - R²
    if c < 0
        # step microbe backward to the sphere surface
        Δt = model.timestep
        s = @. -microbe.vel * microbe.speed * Δt
        a = sum(abs2.(s))
        b = -2 * dot(d, s)
        ε = -b / 2a * (1 - sqrt(1 - 4a*c/b^2))
        walk!(microbe, ε.*s, model)
    end
    microbe.is_stuck = contact(microbe, sphere, model)
    # if escape probability > 0 microbe may escape immediately
    if microbe.escape_probability > 0
        if rand(abmrng(model)) < microbe.escape_probability
            # try escape until a direction
            # away from surface is found
            while microbe.is_stuck
                try_turn!(microbe, model)
            end
        end
    end
    microbe
end


@inline radius(c::Sphere) = c.radius
@inline MicrobeAgents._pos(c::Sphere) = c.origin
@inline MicrobeAgents.distance(a::Sphere, b, model) = distance(b, a, model)
@inline function MicrobeAgents.distance(a, b::Sphere, model)
    p = MicrobeAgents._pos(a)
    q = b.origin
    distance(p, q, model)
end
@inline MicrobeAgents.distancevector(a::Sphere, b, model) = .-distancevector(b, a, model)
@inline function MicrobeAgents.distancevector(a, b::Sphere, model)
    p = MicrobeAgents._pos(a)
    q = b.origin
    distancevector(p, q, model)
end
