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
    xscale = :log10
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
    ylab = L"\mathrm{f_{bulk}}"
    xlab = L"\mathrm{U \tau \, / \, W}"
    plot(palette=cmap, xlab=xlab, ylab=ylab, xscale=:log10,
        leg=:topright, legendtitle="R",
        title="$(mot) $(dim)d, $(interaction)", titlefontsize=10
    )
    for g in gdf
        τ = 1 ./ g.λ
        f_bulk = g.f_bulk
        R = g.R[1]
        plot!(τ, f_bulk, m=:c, ms=6, msw=0, lab=R)
    end
    plot!()
end

##
type = "cylinders"
fname = datadir("proc", type, "timefractions.csv")
df = CSV.read(fname, DataFrame)
sort!(df, [:λ, :R, :dim])

##
for dim in [2], interaction in ["stick", "slide"], Drot in [0.1],
    mot in ["RunTumble", "RunReverse", "RunReverseFlick"]
    τ = range(0.1, 15, length=500)
    plt = makeplot_cylinders(df, dim, interaction, mot)
    #D = @. bulk_diffusivity(τ, Drot, dim, mot)
    #plot!(τ, D, lc=:green, lw=2, alpha=0.5, lab=false)
    plot!(plt, ylims=(-0.05, 1.05))
    config = @strdict type dim interaction mot
    savefig(plt, plotsdir(savename("fbulk", config, "png")))
    savefig(plt, plotsdir(savename("fbulk", config, "pdf")))
end
