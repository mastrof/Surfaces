## Libraries
using Distributed
@everywhere using DrWatson
@everywhere @quickactivate "Surfaces"
@everywhere begin
    using Surfaces
    using JLD2, DelimitedFiles
    using MeanSquaredDisplacement
    using MicrobeAgents: vectorize_adf_measurement, unfold
end

## Functions to evaluate MSD
@everywhere function get_emsd(traj::AbstractMatrix{<:NTuple{2}})
    x = first.(traj)
    y = last.(traj)
    emx = emsd(x)
    emy = emsd(y)
    [emx emy]
end

@everywhere function get_emsd(traj::AbstractMatrix{<:NTuple{3}})
    x = first.(traj)
    y = map(s -> s[2], traj)
    z = last.(traj)
    emx = emsd(x)
    emy = emsd(y)
    emz = emsd(z)
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
    eMSD = get_emsd(traj)
    Δt = 0.01
    t = (axes(eMSD,1).-1) .* Δt
    writedlm(fout, [t eMSD])
end

## Analysis
filenames = readdir(datadir("sims"))
pmap(get_emsd, filenames)
