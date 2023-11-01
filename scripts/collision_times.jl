using DrWatson
@quickactivate :Surfaces
using JLD2, CSV
using MicrobeAgents: vectorize_adf_measurement
using DataFrames

##
function free_path(s::AbstractVector{Bool}; Δt=0.01)
    ls = length(s)
    iter = zip(view(s, 1:ls-1), view(s, 2:ls))
    start = Int[0]
    stop = Int[]
    for (i,(a,b)) in enumerate(iter)
        if b && !a
            push!(stop, i)
        elseif !b && a
            push!(start, i)
        end
    end
    if length(start) == length(stop)
        return (stop .- start) .* Δt
    else
        return (stop .- start[1:end-1]) .* Δt
    end
end

function bound_path(s::AbstractVector{Bool}; Δt=0.01)
    ls = length(s)
    iter = zip(view(s, 1:ls-1), view(s, 2:ls))
    start = Int[]
    stop = Int[]
    for (i,(a,b)) in enumerate(iter)
        if b && !a
            push!(start, i)
        elseif !b && a
            push!(stop, i)
        end
    end
    if length(start) == length(stop)
        return (stop .- start) .* Δt
    else
        return (stop .- start[1:end-1]) .* Δt
    end
end

##
filenames = readdir(datadir("sims", "cylinders"); join=true)
Threads.@threads for fname in filenames
    param = parse_savename(fname)[2]
    f = jldopen(fname)
    adf = f["adf"]
    close(f)
    s = vectorize_adf_measurement(adf, :is_stuck)
    time_between_collisions = vcat(map(free_path, eachcol(s))...)
    time_on_surface = vcat(map(bound_path, eachcol(s))...)
    fout_collisions = replace(fname, "sims" => "proc", "traj" => "free", "jld2" => "csv")
    CSV.write(fout_collisions, time_between_collisions |> Tables.table)
    fout_surface = replace(fname, "sims" => "proc", "traj" => "bound", "jld2" => "csv")
    CSV.write(fout_surface, time_on_surface |> Tables.table)
end
