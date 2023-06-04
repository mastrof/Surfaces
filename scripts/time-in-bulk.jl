## Libraries
using Distributed
@everywhere using DrWatson
@everywhere @quickactivate :Surfaces
@everywhere begin
    using JLD2, DelimitedFiles
    using StatsBase
end

## Fraction of time in the bulk
@everywhere function timeinbulk(fname::AbstractString)
    config = parse_savename(fname)[2]
    fout = datadir("proc", savename("timeinbulk", config))
    isfile(fout) && return nothing
    simdata = jldopen(datadir("sims", fname), "r")
    is_stuck = simdata["adf"].is_stuck
    close(simdata)
    s = mean(is_stuck)
    δs = std(is_stuck)
    is_stuck = nothing
    writedlm(fout, [s δs])
    GC.gc()
end

## Run analysis
filenames = filter(s -> endswith(s, "jld2"), readdir(datadir("sims")))
pmap(timeinbulk, filenames)
