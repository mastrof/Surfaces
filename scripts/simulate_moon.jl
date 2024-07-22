using Distributed
@everywhere using DrWatson
@everywhere @quickactivate :Surfaces
@everywhere begin
    using JLD2
    using DelimitedFiles
    using Agents
    using MicrobeAgents
    using BubbleBath
    using Random
    using Plots
end

@everywhere function runsim(params)
    @unpack dim, L, Rin, Rout, Δx, motilepattern, U, λ, Drot = params
    Δt = 0.005
    re = Regex("landscape.*L=$(L).*Rin=$(Rin).*Rout=$(Rout).*dx=$(Δx)")
    files = readdir(datadir("sims", "moons"); join=true)
    filter!(x -> contains(x, re), files)
    wmfile = first(files)
    println(wmfile)
    walkmap = BitMatrix(readdlm(wmfile))
    extent = ntuple(_ -> L, dim)
    space = ContinuousSpace(extent; periodic=true, spacing=Δx)
    model = StandardABM(Microbe{dim}, space, Δt)
    pathfinder!(model, walkmap)
    available_positions = findall(walkmap)
    for _ in 1:2000
        ix, iy = rand(available_positions).I
        pos = (x[ix], y[iy])
        add_agent!(pos, model;
            motility=Surfaces.init_motility(motilepattern, U),
            speed=U,
            turn_rate=λ,
            rotational_diffusivity=Drot,
        )
    end
    adata = [:pos]
    when(model, s) = s % 20 == 0
    nsteps = round(Int, 1000/(λ*model.timestep))
    adf, = run!(model, nsteps; adata, when)
    @strdict adf
end

@everywhere function produce_data(config)
    savedir = haskey(ENV, "SCRATCH") ? joinpath(ENV["SCRATCH"], "Surfaces") : datadir()
    data = produce_or_load(
        runsim, joinpath(savedir, "sims", "moons"), config;
        prefix="traj", suffix="jld2",
        tag=false, loadfile=false
    )
    data = nothing
    GC.gc()
    return nothing
end

dim = [2]
L = [50]
Δx = L ./ 2000
Rout = [1.0]
Rin = [0.8]
motilepattern = [:RunTumble]
U = [1.0]
λ = exp10.(range(-1, 1; length=10))
Drot = [0.1]

allparams = @strdict dim L Δx Rout Rin motilepattern U λ Drot
dicts = dict_list(allparams)
pmap(produce_data, dicts)
