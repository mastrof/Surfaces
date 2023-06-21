##
using DrWatson
using CSV, DataFrames
using LsqFit

##
function diffusivity_maximum(df)
    _, i = findmax(df.Dx)
    τs = 1 ./ df[i-2:i+2, :λ]
    Ds = df[i-2:i+2, :Dx]
    fit = curve_fit(model, τs, Ds, ones(3))
    p = fit.param
    τ = 10^(-p[2] / 2p[3])
    Dx = model(τ, p)
    return τ, Dx
end

##
model(τ, p) = @. p[1] + p[2]*log10(τ) + p[3]*log10(τ)^2

##
type = "cylinders"
fname = datadir("proc", type, "diffusioncoefficient_fixslope.csv")
df = CSV.read(fname, DataFrame)
sort!(df, [:λ, :R, :Drot, :dim, :Dx])

##
gdf = groupby(df, [:R, :Drot, :dim, :interaction])
df_maxima = DataFrame(
    R=Float64[], Drot=Float64[], dim=Int[], interaction=String[],
    τ=Float64[], Dx=Float64[]
)
for g in gdf 
    τ, Dx = diffusivity_maximum(g)
    append!(df_maxima, 
        Dict(
            "R" => g.R[1],
            "Drot" => g.Drot[1],
            "dim" => g.dim[1],
            "interaction" => g.interaction[1],
            "τ" => τ,
            "Dx" => Dx
        )
    )
end

CSV.write(datadir("proc", type, "diffusivitymaxima.csv"), df_maxima)
