export initializemodel_cylinders,
    initializemodel_rectangles,
    initializemodel_randomcylinders,
    initializemodel_randomrectangles,
    initializemodel_cylrect,
    initializemodel_slit

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

function initializemodel_rectangles(
    dim, L, Ax, Ay,
    MicrobeType, motilepattern,
    U, λ, Drot,
    Us, λs, μ,
    interaction;
    n = 2000, Δt = 0.01,
    rng = Random.Xoshiro()
)
    extent = SVector{dim}(L for _ in 1:dim)
    space = ContinuousSpace(extent, periodic=true)

    rectangle = Rectangle(extent./2, Ax, Ay)

    model = UnremovableABM(MicrobeType{dim}, space, Δt; rng)
    for _ in 1:n
        pos = ntuple(_ -> 0.0, dim)
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

    surfaces!(model, rectangle, interaction)

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

function initializemodel_randomrectangles(
    dim, L, Ax, Ay, N,
    MicrobeType, motilepattern,
    U, λ, Drot,
    Us, λs, μ,
    interaction;
    n = 2000, Δt = 0.01,
    rng = Random.Xoshiro()
)
    extent = SVector{dim}(L for _ in 1:dim)
    space = ContinuousSpace(extent, periodic=true)

    re = Regex("rectangles.*Ax=$(Ax).*Ay=$(Ay).*L=$(L).*N=$(N).*dat")
    files = readdir(datadir("sims", "randomrectangles"); join=true)
    filter!(x -> contains(x, re), files)
    landscape_file = first(files)
    rectangles = map(eachrow(readdlm(landscape_file))) do (x, y, θ)
        Rectangle(SVector{2}(x,y), Ax, Ay, θ)
    end

    model = UnremovableABM(MicrobeType{dim}, space, Δt; rng)
    for _ in 1:n
        pos = Tuple(rand(rng, dim) .* extent)
        while any([Surfaces.sdf(SVector(pos), rect) <= 0 for rect in rectangles])
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

    surfaces!(model, rectangles, interaction)
    @info "Initializing neighbor list..."
    cutoff_radius = 60 * U * Δt
    abmproperties(model)[:neighborlist] = map(_ -> Int[], allids(model))
    update_neighbors!(model, cutoff_radius)
    @info "Neighbor list initialized"
    # add neighbor list updater to model
    model → (model) -> update_neighbors!(model, cutoff_radius, abmproperties(model)[:t] % 50 == 0)

    return model
end

function initializemodel_cylrect(
    dim, L, #R, Ax, Ay,
    MicrobeType, motilepattern,
    U, λ, Drot,
    Us, λs, μ,
    interaction;
    n = 2000, Δt = 0.01,
    rng = Random.Xoshiro()
)
    extent = SVector{dim}(L for _ in 1:dim)
    space = ContinuousSpace(extent, periodic=true)

    p0 = extent ./ 2
    bodies = [
        # a large cylinder at the center
        Cylinder(p0, L, 0.15*L),
        # 4 rectangles diagonally around the center
        Rectangle(p0 .+ SVector(L,L).*0.23, 0.1*L, 0.1*L),
        Rectangle(p0 .+ SVector(-L,L).*0.23, 0.1*L, 0.1*L),
        Rectangle(p0 .+ SVector(-L,-L).*0.23, 0.1*L, 0.1*L),
        Rectangle(p0 .+ SVector(L,-L).*0.23, 0.1*L, 0.1*L),
        # 4 smaller cylinders orthogonally around the center
        Cylinder(p0 .+ SVector(0.37*L,0), L, 0.1*L),
        Cylinder(p0 .+ SVector(0,0.37*L), L, 0.1*L),
        Cylinder(p0 .+ SVector(-0.37*L,0), L, 0.1*L),
        Cylinder(p0 .+ SVector(0,-0.37*L), L, 0.1*L),
    ]
    # solid fraction: φ̅ = 0.3563495408493621


    model = UnremovableABM(MicrobeType{dim}, space, Δt; rng)
    d0 = [b isa Rectangle ? 0.0 : b.radius for b in bodies]
    for _ in 1:n
        pos = Tuple(rand(rng, dim) .* extent)
        while any([
            distance(SVector(pos), b, model) <= d
            for (b,d) in zip(bodies, d0)
        ])
            pos = Tuple(rand(rng, dim) .* extent)
        end
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

    surfaces!(model, bodies, interaction)

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
    model::ABM, y::AbstractVector{<:AbstractBody}, cutoff
)
    microbes = MicrobeAgents.make_position_vector(model)
    MicrobeAgents.neighborlist(microbes, MicrobeAgents.make_position_vector(y), abmspace(model), cutoff)
end
# need overload for neighborlist
function MicrobeAgents.make_position_vector(bodies::AbstractVector{<:AbstractBody})
    MicrobeAgents._pos.(bodies)
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
