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
function makeDplot_cylinders(df, dim, interaction, Drot)
    flt = [
        :dim => d -> d .== dim,
        :interaction => inter -> inter .== interaction,
        :Drot => Dr -> Dr .== Drot,
    ]
    subdf = subset(df, flt)
    gdf = groupby(subdf, [:R])

    cmap = palette(:matter, length(gdf))
    plot(palette=cmap, xlab="τ", ylab="D", xscale=:log10,
        leg=:topleft, legendtitle="R",
        title="$(dim)d, $(interaction), Dᵣ=$(Drot)", titlefontsize=10
    )
    for g in gdf
        τ = 1 ./ g.λ
        plot!(τ, g.Dx, m=:c, ms=6, msw=0, lab=g.R[1])
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
