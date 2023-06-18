struct Slit <: AbstractBody
    bottom::Float64
    top::Float64
end

function slide!(microbe::SurfyMicrobe{D}, slit::Slit, model) where {D}
    if ~microbe.is_stuck
        stick!(microbe, slit, model)
        if microbe.is_stuck
            # extract new velocity on surface
            microbe.vel = (rand_vel(D-1)..., 0.0)
        end
        return microbe
    end
    Δt = model.timestep
    move_agent!(microbe, model, microbe.speed_surface*Δt)
end


function stick!(microbe::SurfyMicrobe{D}, slit::Slit, model) where {D}
    d_top = microbe.pos[D] - slit.top
    d_bottom = slit.bottom - microbe.pos[D]
    if d_top > 0
        d = d_top
        τ = d / (microbe.speed * microbe.vel[D])
        s = @. -microbe.vel * microbe.speed * τ
        # step back
        walk!(microbe, s, model)
    elseif d_bottom > 0
        d = d_bottom
        τ = d / (microbe.speed * microbe.vel[D])
        s = @. microbe.vel * microbe.speed * τ
        # step back
        walk!(microbe, s, model)
    end
    microbe.is_stuck = contact(microbe, slit, model)
    microbe
end

@inline function contact(a::AbstractMicrobe{D}, b::Slit, model) where {D}
    a.pos[D] ≈ b.top || a.pos[D] ≈ b.bottom
end
@inline contact(a::Slit, b::AbstractMicrobe{D}, model) where {D} = contact(b, a, model)
