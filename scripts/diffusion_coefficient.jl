##
using DrWatson
using DataFrames
using JLD2, DelimitedFiles, CSV
using LsqFit

function diffcoeff(data; t₀=0)
    t, mx, my, = eachcol(data)
    i₀ = findfirst(t .≥ t₀)
    lt = log.(t[i₀:end])
    lmx = log.(mx[i₀:end])
    lmy = log.(my[i₀:end])
    lmxy = @. (lmx+lmy)/2
    model(t,p) = @. p[1] + p[2]*t
    fit = curve_fit(model, lt, lmxy, [1e-2, 1])
    D = exp(fit.param[1])/2
    return D
end

##
filenames = filter(s -> startswith(s, "emsd"), readdir(datadir("proc")))
df = DataFrame(
    dim=Int[], λ=Float64[], Dxy=Float64[], #δDxy=Float64[],
    interaction=String[], Drot=Float64[], R=Float64[],
    L=Float64[], U=Float64[], motilepattern=String[]
)
for fname in filenames
    config = parse_savename(fname)[2]
    data = readdlm(datadir("proc", fname))
    t₀ = 5.0
    Dxy = diffcoeff(data; t₀)
    push!(df, (
        dim=config["dim"], λ=config["λ"], Dxy=Dxy, #δDxy=δDxy,
        interaction=config["interaction"], Drot=config["Drot"],
        R=config["R"], L=config["L"], U=config["U"],
        motilepattern=config["motilepattern"]
    ))
end
fout = datadir("proc", "diffusioncoefficient.csv")
CSV.write(fout, df)
