##
using DrWatson
using DataFrames
using JLD2, DelimitedFiles, CSV
using LsqFit
using Measurements

function init_dataframe(filename)
    dict = parse_savename(filename)[2]
    k = keys(dict)
    v = map(T -> T[], typeof.(values(dict)))
    DataFrame(
        (k .=> v)...,
        "Dx" => Float64[],
        "Dy" => Float64[],
        "Dz" => Float64[],
        "deltaDx" => Float64[],
        "deltaDy" => Float64[],
        "deltaDz" => Float64[]
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
    model(t,p) = @. p[1] + t
    Dx, deltaDx = makefit(model, lt, lmx, [1e-2])
    Dy, deltaDy = makefit(model, lt, lmy, [1e-2])
    Dz, deltaDz = NaN, NaN
    @strdict Dx Dy Dz deltaDx deltaDy deltaDz
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
    model(t,p) = @. p[1] + t
    Dx, deltaDx = makefit(model, lt, lmx, [1e-2])
    Dy, deltaDy = makefit(model, lt, lmy, [1e-2])
    Dz, deltaDz = makefit(model, lt, lmz, [1e-2])
    @strdict Dx Dy Dz deltaDx deltaDy deltaDz
end


function makefit(model, x, y, p)
    fit = curve_fit(model, x, y, p)
    q = fit.param[1]
    dq = stderror(fit)[1]
    D = exp(q ± dq) / 2
    return Measurements.value(D), Measurements.uncertainty(D)
end

##
for type in ["cylinders"]
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
    fout = datadir("proc", type, "diffusioncoefficient_fixslope.csv")
    CSV.write(fout, df)
end
