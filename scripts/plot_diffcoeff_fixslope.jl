##
using DrWatson
using DataFrames
using CSV
using LaTeXStrings
using Plots; Plots.pyplot()
Plots.default(
    thickness_scaling = 1.5, frame = :border, grid = false,
    guidefontsize = 12, tickfontsize = 12,
    bgcolorlegend = :transparent, fgcolorlegend = :transparent,
    legendfontsize = 8, legendtitlefontsize = 10
)

##
function makeDplot_cylinders(df, dim, interaction, Drot)
    flt = [
        :dim => d -> d .== dim,
        :interaction => inter -> inter .== interaction,
        :Drot => Dr -> Dr .== Drot,
    ]
    subdf = subset(df, flt)
    gdf = groupby(subdf, [:R])

    cmap = palette(:matter, length(gdf))
    ylab = L"\mathrm{D_{\parallel} \, / \, (U^2 T_s)}"
    xlab = L"\mathrm{\tau \, / \, T_s}"
    plot(palette=cmap, xlab=xlab, ylab=ylab, xscale=:log10,
        leg=:topleft, legendtitle="φ",
        title="$(dim)d, $(interaction), DᵣTₛ=$(Drot)", titlefontsize=10
    )
    for g in gdf
        τ = 1 ./ g.λ
        D = (g.Dx + g.Dy)/2
        φ = round(π*g.R[1]^2; sigdigits=2)
        plot!(τ, D, m=:c, ms=6, msw=0, lab=φ)
    end
    plot!()
end

##
type = "cylinders"
fname = datadir("proc", type, "diffusioncoefficient_fixslope.csv")
df = CSV.read(fname, DataFrame)
sort!(df, [:λ, :R, :Drot, :dim])

##
for dim in [2,3], interaction in ["stick", "slide"], Drot in [0,1]
    plt = makeDplot_cylinders(df, dim, interaction, Drot)
    if Drot == 0
        plot!(plt, ylims=(0.01, 0.45))
    else
        plot!(plt, ylims=(0.01, 0.175))
    end
    config = @strdict type dim interaction Drot
    savefig(plt, plotsdir(savename("D", config, "png")))
    savefig(plt, plotsdir(savename("D", config, "pdf")))
end
