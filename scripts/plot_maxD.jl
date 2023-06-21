##
using DrWatson
using CSV, DataFrames
using Plots
Plots.default(
    thickness_scaling = 1.5, frame = :border, grid = false,
    guidefontsize = 12, tickfontsize = 12,
    bgcolorlegend = :transparent, fgcolorlegend = :transparent,
    legendfontsize = 8, legendtitlefontsize = 8,
    titlefontsize = 10,
)

##
function plot_optimalrunlength(df)
    plot(xlab="R", ylab="optimal τ", palette=:Dark2)
    dim = df.dim[1]
    sort!(df, [:R])
    gdf = groupby(df, [:interaction, :Drot])
    for g in gdf
        Dᵣ = g.Drot[1]
        inter = g.interaction[1]
        plot!(g.R, g.τ, lw=2, m=:c, ms=6, msw=0, lab="$(inter), Dᵣ=$(Dᵣ)")
    end
    plot!(title="$(dim)d")
end

function plot_maxdiffusivity(df)
    plot(xlab="R", ylab="max D", palette=:Dark2)
    dim = df.dim[1]
    sort!(df, [:R])
    gdf = groupby(df, [:interaction, :Drot])
    for g in gdf
        Dᵣ = g.Drot[1]
        inter = g.interaction[1]
        plot!(g.R, g.D, lw=2, m=:c, ms=6, msw=0, lab="$(inter), Dᵣ=$(Dᵣ)")
    end
    plot!(title="$(dim)d")
end

##
type = "cylinders"
fname = datadir("proc", type, "diffusivitymaxima.csv")
df = CSV.read(fname, DataFrame)

##
for dim in [2,3]
    df_flt = subset(df, [:dim => d -> d.==dim])

    plot_optimalrunlength(df_flt)
    savefig(plotsdir("optimal-runlength_dim=$(dim).pdf"))

    plot_maxdiffusivity(df_flt)
    savefig(plotsdir("max-diffusivity_dim=$(dim).pdf"))
end
