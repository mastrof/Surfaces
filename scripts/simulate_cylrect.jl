## Libraries
using Distributed
@everywhere using DrWatson
@everywhere @quickactivate :Surfaces
@everywhere begin
    using JLD2
    using MicrobeAgents
end

## Routines for data production
@everywhere function runsim(params)
    @unpack dim, L, motilepattern, U, λ, Drot, interaction = params
    model = initializemodel_cylrect(
        dim, L,
        SurfyMicrobe, motilepattern,
        U, λ, Drot,
        U, λ, 0.0, # match with bulk parameters
        interaction == :stick ? stick! : slide!;
    )
    adata = [:pos]
    when(model,s) = s % 20 == 0
    nsteps = round(Int, 1000/(λ*model.timestep))
    adf, = run!(model, nsteps; adata, when)
    @strdict adf
end

@everywhere function produce_data(config)
    savedir = haskey(ENV, "SCRATCH") ? joinpath(ENV["SCRATCH"], "Surfaces") : datadir()
    data = produce_or_load(
        runsim, joinpath(savedir, "sims", "cylrect"), config;
        prefix="traj", suffix="jld2",
        tag=false, loadfile=false
    )
    data = nothing
    GC.gc()
    return nothing
end

## Setup parameters and run
dim = [2]
L = [1.0]
motilepattern = [:RunTumble]
interaction = [:stick]
U = [1.0]
λ = exp10.(range(-1, 1, length=15))
Drot = [0.1]

allparams = @strdict dim L motilepattern interaction U λ Drot
dicts = dict_list(allparams)
pmap(produce_data, dicts)
