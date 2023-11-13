##
using DrWatson
@quickactivate :Surfaces
using DataFrames
using CSV
using Measurements
using LaTeXStrings
using Plots; Plots.gr()
Plots.default(
    thickness_scaling = 1.5, frame = :border, grid = false,
    guidefontsize = 12, tickfontsize = 12,
    bgcolorlegend = :transparent, fgcolorlegend = :transparent,
    legendfontsize = 8, legendtitlefontsize = 10,
)

##
function makeplot_cylinders(df, dim, interaction, mot)
    flt = [
        :dim => d -> d .== dim,
        :interaction => inter -> inter .== interaction,
        :motilepattern => m -> m .== mot
    ]
    subdf = subset(df, flt)
    gdf = groupby(subdf, [:R])

    cmap = palette(:matter, length(gdf))
    ylab = L"\mathrm{D_{bulk} f_{bulk}}"
    xlab = L"\mathrm{U \tau \, / \, W}"
    plot(palette=cmap, xlab=xlab, ylab=ylab, xscale=:log10,
        leg=:topleft, legendtitle="R",
        title="$(mot) $(dim)d, $(interaction)", titlefontsize=10
    )
    for (i,g) in zip(1:length(gdf), gdf)
        τ = 1 ./ g.λ
        f_bulk = g.f_bulk
        Drot = g.Drot
        R = g.R[1]
        D = @. (g.Dx + g.Dy) / 2
        plot!(τ, D, m=:c, ms=6, msw=0, lab=R, c=i)
        D = @. bulk_diffusivity(τ, Drot, dim, mot)
        plot!(τ, D .* f_bulk, m=:d, ms=3, msw=0.5, ls=:dash, lw=1, c=i, lab=false)
    end
    plot!()
end

##
type = "cylinders"
fname = datadir("proc", type, "timefractions.csv")
fname_D = datadir("proc", type, "diffusioncoefficient_fixslope.csv")
df = CSV.read(fname, DataFrame)
df_D = CSV.read(fname_D, DataFrame)
sort!(df, [:λ, :R, :dim])
sort!(df_D, [:λ, :R, :dim])
df = hcat(df, df_D[:, [:Dx, :Dy]])

##
for dim in [2], interaction in ["stick"], Drot in [0.1],
    mot in ["RunTumble", "RunReverse", "RunReverseFlick"]
    τ = range(0.1, 15, length=500)
    plt = makeplot_cylinders(df, dim, interaction, mot)
    D = @. bulk_diffusivity(τ, Drot, dim, mot)
    plot!(τ, D, lc=:green, lw=2, alpha=0.5, lab=false)
    plot!(plt, ylims=(0.015, 0.55))
    config = @strdict type dim interaction mot
    savefig(plt, plotsdir(savename("Deff", config, "png")))
    savefig(plt, plotsdir(savename("Deff", config, "pdf")))
end
