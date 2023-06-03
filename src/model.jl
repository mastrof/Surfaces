export initializemodel_singlecylinder

function initializemodel_singlecylinder(
    dim, L, R,
    MicrobeType, motilepattern,
    U, λ, Drot,
    Us, λs, μ,
    interaction;
    n = 2000, Δt = 0.01,
    rng = Random.Xoshiro()
)
    extent = ntuple(_ -> L, dim)
    space = ContinuousSpace(extent, periodic=true)

    cylinder = Cylinder(extent./2, L, R)

    model = UnremovableABM(MicrobeType{dim}, space, Δt; rng)
    for _ in 1:n
        pos = ntuple(i -> i == 1 ? L/2 : 0.0, dim)
        add_agent!(pos, model;
            rotational_diffusivity = Drot,
            speed = U,
            turn_rate = λ,
            speed_surface = Us,
            turn_rate_surface = λs,
            escape_probability = μ,
            is_stuck = false,
            vel = rand_vel(abmrng(model), dim),
            motility = init_motility(motilepattern, U)
        )
    end

    surfaces!(model, cylinder, interaction)

    return model
end


function init_motility(motilepattern, U)
    if motilepattern == :RunTumble
        return RunTumble(speed = [U])
    elseif motilepattern == :RunReverse || motilepattern == :RunReverseFlick
        return motilepattern(speed_forward=[U], speed_backward=[U])
    else
        throw(ArgumentError("Invalid motile pattern $(motilepattern)"))
    end
end
