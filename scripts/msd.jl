## Libraries
using Distributed
@everywhere using DrWatson
@everywhere @quickactivate :Surfaces
@everywhere begin
    using JLD2, DelimitedFiles
    using MeanSquaredDisplacement
    using MicrobeAgents: vectorize_adf_measurement, unfold
end

## Functions to evaluate MSD
@everywhere function get_emsd(traj::AbstractMatrix{<:NTuple{2}}, lags)
    x = first.(traj)
    y = last.(traj)
    emx = emsd(x, lags)
    x = nothing
    emy = emsd(y, lags)
    y = nothing
    [emx emy]
end

@everywhere function get_emsd(traj::AbstractMatrix{<:NTuple{3}}, lags)
    x = first.(traj)
    y = map(s -> s[2], traj)
    z = last.(traj)
    emx = emsd(x, lags)
    x = nothing
    emy = emsd(y, lags)
    y = nothing
    emz = emsd(z, lags)
    z = nothing
    [emx emy emz]
end

@everywhere function get_emsd(fname::AbstractString)
    params = parse_savename(fname)[2]
    fout = datadir("proc", savename("emsd", params))
    isfile(fout) && return nothing
    simdata = jldopen(datadir("sims", fname), "r")
    df = simdata["adf"]
    close(simdata)
    traj = unfold(vectorize_adf_measurement(df, :pos), params["L"])
    df = nothing
    lags = 1:10:(size(traj,1)-1)
    eMSD = get_emsd(traj, lags)
    traj = nothing
    Δt = 0.01
    t = lags .* Δt
    writedlm(fout, [t eMSD])
    GC.gc()
    return nothing
end

## Analysis
filenames = filter(s -> endswith(s, "jld2"), readdir(datadir("sims")))
pmap(get_emsd, filenames)
