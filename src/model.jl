export initializemodel_cylinders, initializemodel_randomcylinders, initializemodel_slit

function initializemodel_cylinders(
    dim, L, R,
    MicrobeType, motilepattern,
    U, λ, Drot,
    Us, λs, μ,
    interaction;
    n = 2000, Δt = 0.01,
    rng = Random.Xoshiro()
)
    extent = SVector{dim}(L for _ in 1:dim)
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
            vel = random_velocity(abmrng(model), dim),
            motility = init_motility(motilepattern, U)
        )
    end

    surfaces!(model, cylinder, interaction)

    return model
end

function initializemodel_randomcylinders(
    dim, L, pdf_R, packing_fraction,
    MicrobeType, motilepattern,
    U, λ, Drot,
    Us, λs, μ,
    interaction;
    n = 2000, Δt = 0.01,
    rng = Random.Xoshiro()
)
    extent = SVector{dim}(L for _ in 1:dim)
    space = ContinuousSpace(extent, periodic=true)

    bodies = bubblebath(pdf_R, packing_fraction, Tuple(extent); rng)
    cylinders = [Cylinder(SVector(b.pos), L, b.radius) for b in bodies]

    model = UnremovableABM(MicrobeType{dim}, space, Δt; rng)
    for _ in 1:n
        pos = Tuple(rand(rng, dim) .* extent)
        while any([norm(pos .- b.pos) .< b.radius for b in bodies])
            pos = Tuple(rand(rng, dim) .* extent)
        end
        add_agent!(pos, model;
            rotational_diffusivity = Drot,
            speed = U,
            turn_rate = λ,
            speed_surface = Us,
            escape_probability = μ,
            is_stuck = false,
            vel = random_velocity(abmrng(model), dim),
            motility = init_motility(motilepattern, U),
        )
    end

    surfaces!(model, cylinders, interaction)
    @info "Initializing neighbor list..."
    cutoff_radius = 60 * U * Δt
    abmproperties(model)[:neighborlist] = map(_ -> Int[], allids(model))
    update_neighbors!(model, cutoff_radius)
    @info "Neighbor list initialized"
    # add neighbor list updater to model
    model → (model) -> update_neighbors!(model, cutoff_radius, abmproperties(model)[:t] % 50 == 0)

    return model
end

function update_neighbors!(model, cutoff, condition)
    condition && update_neighbors!(model, cutoff)
    nothing
end
function update_neighbors!(model, cutoff)
    neighbors = abmproperties(model)[:neighborlist]
    bodies = abmproperties(model)[:bodies]
    for id in allids(model)
        neighbors[id] = [
            j for j in eachindex(bodies)
            if distance(model[id], bodies[j], model) - radius(bodies[j]) < cutoff
        ]
    end
    nothing
end

# overload because of implementation bug
function MicrobeAgents.neighborlist(
    model::ABM, y::AbstractVector{<:Cylinder}, cutoff
)
    microbes = MicrobeAgents.make_position_vector(model)
    MicrobeAgents.neighborlist(microbes, MicrobeAgents.make_position_vector(y), abmspace(model), cutoff)
end
# need overload for neighborlist
function MicrobeAgents.make_position_vector(cylinders::AbstractVector{<:Cylinder})
    MicrobeAgents._pos.(cylinders)
end


function initializemodel_slit(
    dim, L,
    MicrobeType, motilepattern,
    U, λ, Drot,
    Us, λs, μ,
    interaction;
    n = 2000, Δt = 0.01,
    rng = Random.Xoshiro()
)
    extent = SVector{dim}(2+L for _ in 1:dim)
    space = ContinuousSpace(extent, periodic=true)

    slit = Slit(1.0, 1.0+L)
    
    model = UnremovableABM(MicrobeType{dim}, space, Δt; rng)
    for _ in 1:n
        pos = ntuple(i -> i==dim ? 1+L/2 : L/2, dim)
        add_agent!(pos, model;
            rotational_diffusivity = Drot,
            speed = U,
            turn_rate = λ,
            speed_surface = Us,
            turn_rate_surface = λs,
            escape_probability = μ,
            is_stuck = false,
            vel = random_velocity(abmrng(model), dim),
            motility = init_motility(motilepattern, U)
        )
    end

    surfaces!(model, slit, interaction)

    return model
end


function init_motility(motilepattern, U)
    if motilepattern == :RunTumble
        return RunTumble(speed = [U])
    elseif motilepattern == :RunReverse
        return RunReverse(speed_forward = [U], speed_backward = [U])
    elseif motilepattern == :RunReverseFlick
        return RunReverseFlick(speed_forward = [U], speed_backward = [U])
    else
        throw(ArgumentError("Invalid motile pattern $(motilepattern)"))
    end
end
