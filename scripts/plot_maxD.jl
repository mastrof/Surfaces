##
using DrWatson
using CSV, DataFrames
using LaTeXStrings
using Plots; Plots.pyplot()
Plots.default(
    thickness_scaling = 1.5, frame = :border, grid = false,
    guidefontsize = 12, tickfontsize = 12,
    bgcolorlegend = :transparent, fgcolorlegend = :transparent,
    legendfontsize = 8, legendtitlefontsize = 8,
    titlefontsize = 10,
)

##
function plot_optimalrunlength(df)
    ylab = L"\mathrm{optimal\,\, \tau \, / \, T_s}"
    xlab = L"\mathrm{\varphi}"
    plot(xlab=xlab, ylab=ylab, palette=:Dark2)
    Dᵣ = df.Drot[1]
    sort!(df, [:R])
    gdf = groupby(df, [:interaction, :dim])
    for g in gdf
        dim = g.dim[1]
        φ = @. π * g.R^2
        inter = g.interaction[1]
        plot!(φ, g.τ, lw=2, m=:c, ms=6, msw=0, lab="$(dim)d, $(inter)")
    end
    plot!(title="DᵣTₛ=$(Dᵣ)")
end

function plot_maxdiffusivity(df)
    ylab = L"\mathrm{max\,\, D_\parallel \, / \, (U^2 T_s)}"
    xlab = L"\mathrm{\varphi}"
    plot(xlab=xlab, ylab=ylab, palette=:Dark2)
    Dᵣ = df.Drot[1]
    sort!(df, [:R])
    gdf = groupby(df, [:interaction, :dim])
    for g in gdf
        dim = g.dim[1]
        φ = @. π * g.R^2
        inter = g.interaction[1]
        plot!(φ, g.D, lw=2, m=:c, ms=6, msw=0, lab="$(dim)d, $(inter)")
    end
    plot!(title="DᵣTₛ=$(Dᵣ)")
end

##
type = "cylinders"
fname = datadir("proc", type, "diffusivitymaxima.csv")
df = CSV.read(fname, DataFrame)

##
for Drot in [0,1]
    df_flt = subset(df, [:Drot => Dᵣ -> Dᵣ.==Drot])

    plot_optimalrunlength(df_flt)
    savefig(plotsdir("optimal-runlength_Drot=$(Drot).pdf"))

    plot_maxdiffusivity(df_flt)
    savefig(plotsdir("max-diffusivity_Drot=$(Drot).pdf"))
end
