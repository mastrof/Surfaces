## Libraries
using Distributed
@everywhere using DrWatson
@everywhere @quickactivate :Surfaces
@everywhere begin
    using JLD2
    using MicrobeAgents
    using Distributions
    using Random
end

## Routines for data production
function runsim(params)
    @unpack dim, L, Ax, Ay, N, motilepattern, U, λ, Drot, interaction = params
    Δt = 1 / (200*λ)
    model = initializemodel_randomrectangles(
        dim, L, Ax, Ay, N,
        SurfyMicrobe, motilepattern,
        U, λ, Drot,
        U, λ, 0.0, # match with bulk parameters
        interaction == :stick ? stick! : slide!;
        Δt
    )
    adata = [:pos]
    when(model,s) = s % 20 == 0
    nsteps = round(Int, 2000/(λ*model.timestep))
    adf, = run!(model, nsteps; adata, when)
    @strdict adf
end

@everywhere function produce_data(config)
    savedir = haskey(ENV, "SCRATCH") ? joinpath(ENV["SCRATCH"], "Surfaces") : datadir()
    data = produce_or_load(
        runsim, joinpath(savedir, "sims", "randomrectangles"), config;
        prefix="traj", suffix="jld2",
        tag=false, loadfile=false
    )
    data = nothing
    GC.gc()
    return nothing
end

## Setup parameters and run
dim = [2]
L = [50]
Ax = [0.05]
Ay = [0.5]
N = [851]
motilepattern = [:RunTumble, :RunReverse]
interaction = [:stick]
U = [1.0]
λ = exp10.(range(-1, 1; length=10))
Drot = [0.1]

allparams = @strdict dim L Ax Ay N motilepattern interaction U λ Drot
dicts = dict_list(allparams)

pmap(produce_data, dicts)
