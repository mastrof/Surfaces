##
using DrWatson
@quickactivate :Surfaces
using DataFrames
using CSV
using LaTeXStrings
using Plots; Plots.gr()
Plots.default(
    thickness_scaling = 1.5, frame = :border, grid = false,
    guidefontsize = 12, tickfontsize = 12,
    bgcolorlegend = :transparent, fgcolorlegend = :transparent,
    legendfontsize = 8, legendtitlefontsize = 10
)

## Load data
type = "cylinders"
fname = datadir("proc", type, "diffusioncoefficient_fixslope.csv")
df = CSV.read(fname, DataFrame)
sort!(df, [:λ, :R, :Drot, :dim, :motilepattern])

## Rescaling
#let mot = "RunReverse", dim = 2, Drot = 0.1, interaction = "slide"
for mot in ["RunTumble", "RunReverse", "RunReverseFlick"],
    dim in [2], Drot in [0.1], interaction in ["slide", "stick"]
    config = @strdict type dim interaction Drot mot
    flt = [
        :dim => d -> d .== dim,
        :motilepattern => m -> m .== mot,
        :Drot => Dr -> Dr .== Drot,
        :interaction => inter -> inter .== interaction,
    ]
    subdf = subset(df, flt)
    gdf = groupby(subdf, [:R])

    cmap = palette(:matter, length(gdf))
    ylab = L"\mathrm{ D_\parallel \, / \, D_{bulk}}"
    xlab = L"\mathrm{ U\tau \, / W}"
    plot(palette=cmap, xscale=:log10, leg=:topright, legendtitle="R/W",
        xlab=xlab, ylab=ylab, xlims=(9e-2, 11), ylims=(0, 1.1),
        title="$(mot) $(dim)d, $(interaction), DᵣW/U=$(Drot)", titlefontsize=10
    )
    for k in 1:gdf.ngroups
        D = @. (gdf[k].Dx + gdf[k].Dy) / 2
        τ = @. 1 / gdf[k].λ
        τᵣ = 1 / (2*Drot)
        Db = @. bulk_diffusivity(τ, Drot, dim, mot)
        R = gdf[k].R[1]
        #τl = (1 - π*R^2) / (2*R)
        #τe = @. τ*τᵣ / (τ + τᵣ)
        y = @. D / Db
        plot!(τ, y, m=:c, ms=6, msw=0, c=cmap[k], lab=R)
    end
    #vline!([1], ls=:dash, lc=:green, lab=false)
    #hline!([0.5], ls=:dash, lc=:green, lab=false)
    savefig(plotsdir(savename("Deff", config, "pdf")))
    savefig(plotsdir(savename("Deff", config, "png")))
    plot!()
end
