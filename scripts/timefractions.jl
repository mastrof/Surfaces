using DrWatson
using DelimitedFiles
using DataFrames
using CSV
using StatsBase

##
function init_dataframe(filename)
    dict = parse_savename(filename)[2]
    k = keys(dict)
    v = map(T -> T[], typeof.(values(dict)))
    DataFrame(
        (k .=> v)...,
        "t_bulk" => Float64[],
        "t_bound" => Float64[],
        "f_bulk" => Float64[],
        "f_bound" => Float64[]
    )
end

##
allfilenames_free = filter(
    s -> contains(s, "free"),
    readdir(datadir("proc", "cylinders"); join=true)
)
allfilenames_bound = filter(
    s -> contains(s, "bound"),
    readdir(datadir("proc", "cylinders"); join=true)
)

fnames = zip(allfilenames_free, allfilenames_bound)

##
df = init_dataframe(allfilenames_free[1])
for fname in fnames
    fname_free, fname_bound = fname
    times_free = readdlm(fname_free; skipstart=1)
    times_bound = readdlm(fname_bound; skipstart=1)
    totbulk = sum(times_free)
    t_bulk = mean(times_free)
    totbound = sum(times_bound)
    t_bound = mean(times_bound)
    f_bulk = @. totbulk / (totbulk + totbound)
    f_bound = @. totbound / (totbulk + totbound)
    config = parse_savename(fname_free)[2]
    newdf = DataFrame(
        config...,
        (@strdict t_bulk t_bound f_bulk f_bound)...
    )
    append!(df, newdf)
end
fout = datadir("proc", "cylinders", "timefractions.csv")
CSV.write(fout, df)
