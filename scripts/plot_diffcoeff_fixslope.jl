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
    legendfontsize = 8, legendtitlefontsize = 10
)

##
function makeDplot_cylinders(df, dim, interaction, mot)
    flt = [
        :dim => d -> d .== dim,
        :interaction => inter -> inter .== interaction,
        :motilepattern => m -> m .== mot
    ]
    subdf = subset(df, flt)
    gdf = groupby(subdf, [:R])

    cmap = palette(:matter, length(gdf))
    ylab = L"\mathrm{D_{\parallel} \, / \, (U W)}"
    xlab = L"\mathrm{U \tau \, / \, W}"
    plot(palette=cmap, xlab=xlab, ylab=ylab, xscale=:log10,
        leg=:topleft, legendtitle="R",
        title="$(mot) $(dim)d, $(interaction)", titlefontsize=10
    )
    for g in gdf
        τ = 1 ./ g.λ
        Dx = g.Dx .± g.deltaDx
        Dy = g.Dy .± g.deltaDy
        D = (Dx .+ Dy)/2
        R = g.R[1]
        plot!(τ, D, m=:c, ms=6, msw=0, lab=R)
    end
    plot!()
end

##
type = "cylinders"
fname = datadir("proc", type, "diffusioncoefficient_fixslope.csv")
df = CSV.read(fname, DataFrame)
sort!(df, [:λ, :R, :dim])

##
for dim in [2], interaction in ["stick", "slide"], Drot in [0.1],
    mot in ["RunTumble", "RunReverse", "RunReverseFlick"]
    τ = range(0.1, 15, length=500)
    plt = makeDplot_cylinders(df, dim, interaction, mot)
    D = @. bulk_diffusivity(τ, Drot, dim, mot)
    plot!(τ, D, lc=:green, lw=2, alpha=0.5, lab=false)
    plot!(plt, ylims=(0.01, 0.35))
    config = @strdict type dim interaction mot
    savefig(plt, plotsdir(savename("D", config, "png")))
    savefig(plt, plotsdir(savename("D", config, "pdf")))
end
