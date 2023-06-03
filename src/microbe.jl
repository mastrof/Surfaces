function MicrobeAgents.microbe_step!(microbe::SurfyMicrobe, model)
    Δt = model.timestep
    # perform normal stepping in the bulk
    if ~microbe.is_stuck
        move_agent!(microbe, model, microbe.speed*Δt)
        MicrobeAgents.rotational_diffusion!(microbe, model)
    end
    # check if interactions with any body are occuring
    for (j, body) in enumerate(model.bodies)
        model.surface!(microbe, body, model)
        if microbe.is_stuck
            model.stuck_to[microbe.id] = j
            break # can only interact with one body at a time
        end
    end
    # state update and reorientation
    affect!(microbe, model)
    ω = turnrate(microbe, model)
    if rand(abmrng(model)) < ω*Δt
        try_turn!(microbe, model)
    end
end

function MicrobeAgents.turnrate(microbe::SurfyMicrobe, model)
    if microbe.is_stuck
        return microbe.turn_rate_surface
    else
        return microbe.turn_rate
    end
end

function try_turn!(microbe::SurfyMicrobe, model)
    MicrobeAgents.turn!(microbe, model)
    if microbe.is_stuck
        j = model.stuck_to[microbe.id]
        body = model.bodies[j]
        try_unstick!(microbe, body, model)
    end
    nothing
end

function try_unstick!(microbe::SurfyMicrobe, cylinder::Cylinder, model)
    d = distancevector(cylinder, microbe.pos, model)
    if dot(d, microbe.vel) ≥ 0.0
        microbe.is_stuck = false
        model.stuck_to[microbe.id] = 0
    else
        model.slidingdirection[microbe.id] = slidedirection(microbe, cylinder, model)
    end
end
