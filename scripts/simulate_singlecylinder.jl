## Libraries
using DrWatson
@quickactivate :Surfaces
using JLD2
using MicrobeAgents
using Base.Threads

## Setup parameters
dim = [2, 3]
L = [1.0]
R = [0.125]
motilepattern = [:RunTumble]
interaction = [:stick, :slide]
U = [1.0]
λ = [0.1, 0.25, 1.0, 2.5, 10.0]
Drot = [0.0, 1.0]

allparams = @strdict dim L R motilepattern interaction U λ Drot
dicts = dict_list(allparams)

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

@threads for config in dicts
    produce_or_load(
        runsim, datadir("sims"), config;
        prefix="singlecylinder", suffix="jld2",
        tag=false, loadfile=false
    )
end
