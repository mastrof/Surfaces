##
using DrWatson
using DataFrames
using CSV
using Plots
Plots.default(
    thickness_scaling = 1.5, frame = :border, grid = false,
    guidefontsize = 12, tickfontsize = 12,
    bgcolorlegend = :transparent, fgcolorlegend = :transparent,
    legendfontsize = 8, legendtitlefontsize = 8
)

##
type = "cylinders"
fname = datadir("proc", type, "diffusioncoefficient_fixslope.csv")
df = CSV.read(fname, DataFrame)
sort!(df, [:λ, :R, :Drot, :dim])

##
flt = [
    :dim => d -> d .== 2,
    :interaction => inter -> inter .== "stick",
    :Drot => Dr -> Dr .== 0
]
subdf = subset(df, flt)
gdf = groupby(subdf, [:R])

cmap = palette(:plasma, length(gdf))
plot(palette=cmap, xlab="τ", ylab="Dₓ", xscale=:log10, leg=:topleft, legtitle="R")
for (i,g) in enumerate(gdf)
    τ = 1 ./ g.λ
    plot!(τ, g.Dx, m=:c, ms=6, msw=0, mc=i, lab=g.R[1])
end
plot!()

##
flt = [
    :dim => d -> d .== 2,
    :interaction => inter -> inter .== "slide",
    :Drot => Dr -> Dr .== 0
]
subdf = subset(df, flt)
gdf = groupby(subdf, [:R])

cmap = palette(:plasma, length(gdf))
plot(palette=cmap, xlab="τ", ylab="Dₓ", xscale=:log10, leg=:topleft, legtitle="R")
for (i,g) in enumerate(gdf)
    τ = 1 ./ g.λ
    plot!(τ, g.Dx, m=:c, ms=6, msw=0, mc=i, lab=g.R[1])
end
plot!()


##
flt = [
    :dim => d -> d .== 2,
    :interaction => inter -> inter .== "slide",
    :Drot => Dr -> Dr .== 1
]
subdf = subset(df, flt)
gdf = groupby(subdf, [:R])

cmap = palette(:plasma, length(gdf))
plot(palette=cmap, xlab="τ", ylab="Dₓ", xscale=:log10, leg=:topleft, legtitle="R")
for (i,g) in enumerate(gdf)
    τ = 1 ./ g.λ
    plot!(τ, g.Dx, m=:c, ms=6, msw=0, mc=i, lab=g.R[1])
end
plot!()


##
flt = [
    :dim => d -> d .== 2,
    :interaction => inter -> inter .== "stick",
    :Drot => Dr -> Dr .== 1
]
subdf = subset(df, flt)
gdf = groupby(subdf, [:R])

cmap = palette(:plasma, length(gdf))
plot(palette=cmap, xlab="τ", ylab="Dₓ", xscale=:log10, leg=:topleft, legtitle="R")
for (i,g) in enumerate(gdf)
    τ = 1 ./ g.λ
    plot!(τ, g.Dx, m=:c, ms=6, msw=0, mc=i, lab=g.R[1])
end
plot!()

##
flt = [
    :dim => d -> d .== 3,
    :interaction => inter -> inter .== "stick",
    :Drot => Dr -> Dr .== 0
]
subdf = subset(df, flt)
gdf = groupby(subdf, [:R])

cmap = palette(:plasma, length(gdf))
plot(palette=cmap, xlab="τ", ylab="Dₓ", xscale=:log10, leg=:topleft, legtitle="R")
for (i,g) in enumerate(gdf)
    τ = 1 ./ g.λ
    plot!(τ, g.Dx, m=:c, ms=6, msw=0, mc=i, lab=g.R[1])
end
plot!()

##
flt = [
    :dim => d -> d .== 3,
    :interaction => inter -> inter .== "slide",
    :Drot => Dr -> Dr .== 0
]
subdf = subset(df, flt)
gdf = groupby(subdf, [:R])

cmap = palette(:plasma, length(gdf))
plot(palette=cmap, xlab="τ", ylab="Dₓ", xscale=:log10, leg=:topleft, legtitle="R")
for (i,g) in enumerate(gdf)
    τ = 1 ./ g.λ
    plot!(τ, g.Dx, m=:c, ms=6, msw=0, mc=i, lab=g.R[1])
end
plot!()


##
flt = [
    :dim => d -> d .== 3,
    :interaction => inter -> inter .== "slide",
    :Drot => Dr -> Dr .== 1
]
subdf = subset(df, flt)
gdf = groupby(subdf, [:R])

cmap = palette(:plasma, length(gdf))
plot(palette=cmap, xlab="τ", ylab="Dₓ", xscale=:log10, leg=:topleft, legtitle="R")
for (i,g) in enumerate(gdf)
    τ = 1 ./ g.λ
    plot!(τ, g.Dx, m=:c, ms=6, msw=0, mc=i, lab=g.R[1])
end
plot!()


##
flt = [
    :dim => d -> d .== 3,
    :interaction => inter -> inter .== "stick",
    :Drot => Dr -> Dr .== 1
]
subdf = subset(df, flt)
gdf = groupby(subdf, [:R])

cmap = palette(:plasma, length(gdf))
plot(palette=cmap, xlab="τ", ylab="Dₓ", xscale=:log10, leg=:topleft, legtitle="R")
for (i,g) in enumerate(gdf)
    τ = 1 ./ g.λ
    plot!(τ, g.Dx, m=:c, ms=6, msw=0, mc=i, lab=g.R[1])
end
plot!()
