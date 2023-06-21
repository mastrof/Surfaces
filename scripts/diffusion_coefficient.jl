##
using DrWatson
using DataFrames
using JLD2, DelimitedFiles, CSV
using LsqFit

function init_dataframe(filename)
    dict = parse_savename(filename)[2]
    k = keys(dict)
    v = map(T -> T[], typeof.(values(dict)))
    DataFrame(
        (k .=> v)...,
        "Dx" => Float64[], "βx" => Float64[],
        "Dy" => Float64[], "βy" => Float64[],
        "Dz" => Float64[], "βz" => Float64[]
    )
end

function diffcoeff2d(data; t₀=0, t₁=Inf)
    t, mx, my = eachcol(data)
    i₀ = findfirst(t .≥ t₀)
    i₁ = findlast(t .≤ t₁)
    s = i₀:i₁
    lt = log.(@view t[s])
    lmx = log.(@view mx[s])
    lmy = log.(@view my[s])
    model(t,p) = @. p[1] + p[2]*t
    Dx, βx = makefit(model, lt, lmx, [1e-2, 1])
    Dy, βy = makefit(model, lt, lmy, [1e-2, 1])
    Dz, βz = NaN, NaN
    @strdict Dx βx Dy βy Dz βz
end

function diffcoeff3d(data; t₀=0, t₁=Inf)
    t, mx, my, mz = eachcol(data)
    i₀ = findfirst(t .≥ t₀)
    i₁ = findlast(t .≤ t₁)
    s = i₀:i₁
    lt = log.(@view t[s])
    lmx = log.(@view mx[s])
    lmy = log.(@view my[s])
    lmz = log.(@view mz[s])
    model(t,p) = @. p[1] + p[2]*t
    Dx, βx = makefit(model, lt, lmx, [1e-2, 1])
    Dy, βy = makefit(model, lt, lmy, [1e-2, 1])
    Dz, βz = makefit(model, lt, lmz, [1e-2, 1])
    @strdict Dx βx Dy βy Dz βz
end

function makefit(model, x, y, p)
    fit = curve_fit(model, x, y, p)
    D = exp(fit.param[1])/2
    β = fit.param[2]
    return D, β
end

##
for type in ["slit", "cylinders"]
    filenames = filter(s -> startswith(s, "emsd"), readdir(datadir("proc", type)))
    isempty(filenames) && continue
    df = init_dataframe(first(filenames))
    for fname in filenames
        config = parse_savename(fname)[2]
        data = readdlm(datadir("proc", type, fname))
        t₀ = 10 / config["λ"]
        t₁ = 41t₀
        fitpars = config["dim"] == 2 ? diffcoeff2d(data; t₀, t₁) : diffcoeff3d(data; t₀, t₁)
        push!(df, Dict(config..., fitpars...))
    end
    fout = datadir("proc", type, "diffusioncoefficient.csv")
    CSV.write(fout, df)
end
