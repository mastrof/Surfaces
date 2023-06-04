##
using DrWatson
@quickactivate :Surfaces
using JLD2, DelimitedFiles, CSV
using DataFrames

##
function initialize_dataframe(filename)
    config = parse_savename(filename)[2]
    df = DataFrame(config)
    s, δs = readdlm(filename)
    df[!,:s] = [s]
    df[!,:δs] = [δs]
    return df
end

##
filenames = filter(s -> startswith(s, "timeinbulk"), readdir(datadir("proc")))
df = initialize_dataframe(datadir("proc", filenames[1]))
for filename in filenames[2:end]
    config = parse_savename(filename)[2]
    s, δs = readdlm(datadir("proc", filename))
    dfnew = DataFrame(Dict(config..., "s" => s, "δs" => δs))
    append!(df, dfnew)
end
fout = datadir("proc", "df_timeinbulk.csv")
CSV.write(fout, df)
