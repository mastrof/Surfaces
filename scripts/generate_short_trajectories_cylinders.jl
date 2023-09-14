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
    @unpack dim, L, R, motilepattern, U, λ, Drot, interaction = params
    model = initializemodel_cylinders(
        dim, L, R,
        SurfyMicrobe, motilepattern,
        U, λ, Drot,
        U, λ, 1.0, # match with bulk parameters
        interaction == :stick ? stick! : slide!;
        n = 10
    )
    adata = [:pos]
    nsteps = 500
    adf, = run!(model, nsteps; adata)
    @strdict adf
end

@everywhere function produce_data(config)
    savedir = haskey(ENV, "SCRATCH") ?
        joinpath(ENV["SCRATCH"], "Surfaces") :
        datadir()
    data = produce_or_load(
        runsim, joinpath(savedir, "sims", "short_trajectories"), config;
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
R = [0.1, 0.15, 0.2, 0.25]
motilepattern = [:RunTumble, :RunReverse, :RunReverseFlick]
interaction = [:stick, :slide]
U = [1.0]
λ = [0.1, 1.0, 10.0]
Drot = [0.0, 1.0]

allparams = @strdict dim L R motilepattern interaction U λ Drot
dicts = dict_list(allparams)
pmap(produce_data, dicts)
