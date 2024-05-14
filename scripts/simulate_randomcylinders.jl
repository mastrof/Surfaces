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
@everywhere function runsim(params)
    @unpack dim, L, pdf_R, φ, motilepattern, U, λ, Drot, interaction = params
    Δt = 1 / (500*λ)
    model = initializemodel_randomcylinders(
        dim, L, pdf_R, φ,
        SurfyMicrobe, motilepattern,
        U, λ, Drot,
        U, λ, 1.0, # match with bulk parameters
        interaction == :stick ? stick! : slide!;
        rng = Xoshiro(1)
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
        runsim, joinpath(savedir, "sims", "randomcylinders"), config;
        prefix="traj", suffix="jld2",
        tag=false, loadfile=false
    )
    data = nothing
    GC.gc()
    return nothing
end

## Setup parameters and run
dim = [2]
L = [2e3]
pdf_R = [Uniform(0.1, 1.9)]
φ = [0.35]
motilepattern = [:RunTumble]
interaction = [:stick]
U = [1.0]
λ = exp10.(range(log10(1/50), log10(1/0.1), length=15))
Drot = [0.1]

allparams = @strdict dim L pdf_R φ motilepattern interaction U λ Drot
dicts = dict_list(allparams)
pmap(produce_data, dicts)
