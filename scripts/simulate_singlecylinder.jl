## Libraries
using Distributed
@everywhere using DrWatson
@everywhere @quickactivate :Surfaces
@everywhere begin
    using JLD2
    using MicrobeAgents
end

## Routines for data production
function runsim(params)
    @unpack dim, L, R, motilepattern, U, λ, Drot, interaction = params
    model = initializemodel_singlecylinder(
        dim, L, R,
        SurfyMicrobe, motilepattern,
        U, λ, Drot,
        U, λ, 1.0, # match with bulk parameters
        interaction == :stick ? stick! : slide!
    )
    adata = [:pos, :is_stuck]
    nsteps = round(Int, 100)
    adf, = run!(model, nsteps; adata)
    @strdict adf
end

function produce_data(config)
    data = produce_or_load(
        runsim, datadir("sims"), config;
        prefix="singlecylinder", suffix="jld2",
        tag=false, loadfile=false
    )
    data = nothing
    GC.gc()
    return nothing
end

## Setup parameters and run
dim = [2, 3]
L = [1.0]
R = [0.125, 0.25, 0.375]
motilepattern = [:RunTumble]
interaction = [:stick, :slide]
U = [1.0]
λ = [0.1, 0.25, 1.0, 2.5, 10.0]
Drot = [0.0, 1.0]

allparams = @strdict dim L R motilepattern interaction U λ Drot
dicts = dict_list(allparams)
pmap(produce_data, dicts)
