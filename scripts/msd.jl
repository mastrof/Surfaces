## Libraries
using Distributed
@everywhere using DrWatson
@everywhere @quickactivate :Surfaces
@everywhere begin
    using JLD2, DelimitedFiles
    using MeanSquaredDisplacement
    using MicrobeAgents: vectorize_adf_measurement, unfold
    using StaticArrays: SVector
end

## Functions to evaluate MSD
@everywhere function get_emsd(traj::AbstractMatrix{<:SVector{2}}, lags)
    x = first.(traj)
    emx = emsd(x, lags)
    x = nothing
    GC.gc()
    y = last.(traj)
    emy = emsd(y, lags)
    y = nothing
    GC.gc()
    [emx emy]
end

@everywhere function get_emsd(traj::AbstractMatrix{<:SVector{3}}, lags)
    x = first.(traj)
    emx = emsd(x, lags)
    x = nothing
    GC.gc()
    y = map(s -> s[2], traj)
    emy = emsd(y, lags)
    y = nothing
    GC.gc()
    z = last.(traj)
    emz = emsd(z, lags)
    z = nothing
    GC.gc()
    [emx emy emz]
end

@everywhere function get_emsd(fname::AbstractString, type::AbstractString)
    params = parse_savename(fname)[2]
    savedir = haskey(ENV, "SCRATCH") ? joinpath(ENV["SCRATCH"], "Surfaces") : datadir()
    fout = joinpath(savedir, "proc", type, savename("emsd", params))
    isfile(fout) && return nothing
    simdata = jldopen(joinpath(savedir, "sims", type, fname), "r")
    df = simdata["adf"]
    close(simdata)
    periodicity = type == "cylinders" ? params["L"] : params["L"]+2
    traj = unfold(vectorize_adf_measurement(df, :pos), periodicity)
    df = nothing
    lags = 1:1:(size(traj,1)-1)
    eMSD = get_emsd(traj, lags)
    traj = nothing
    GC.gc()
    #Δt = 20 * 0.005
    Δt = 5 * 0.01
    #λ = params["λ"]
    #Δt = 20 / (200*λ)
    t = lags .* Δt
    writedlm(fout, [t eMSD])
    return nothing
end

## Analysis
savedir = haskey(ENV, "SCRATCH") ? joinpath(ENV["SCRATCH"], "Surfaces") : datadir()
trajfiles(type) = filter(
    s -> startswith(s, "traj") && endswith(s, "jld2"),
    readdir(joinpath(savedir, "sims", type))
)
#@everywhere get_emsd(fname) = get_emsd(fname, "slit")
#pmap(get_emsd, trajfiles("slit"))
@everywhere get_emsd(fname) = get_emsd(fname, "cylinders")
pmap(get_emsd, trajfiles("cylinders"))
