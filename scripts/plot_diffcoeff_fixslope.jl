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
function makeDplot_cylinders(df, dim, interaction, Drot, mot)
    flt = [
        :dim => d -> d .== dim,
        :interaction => inter -> inter .== interaction,
        :Drot => Dr -> Dr .== Drot,
        :motilepattern => m -> m .== mot
    ]
    subdf = subset(df, flt)
    gdf = groupby(subdf, [:R])

    cmap = palette(:matter, length(gdf))
    ylab = L"\mathrm{D_{\parallel} \, / \, (U W)}"
    xlab = L"\mathrm{U \tau \, / \, W}"
    plot(palette=cmap, xlab=xlab, ylab=ylab, xscale=:log10,
        leg=:topleft, legendtitle="R",
        title="$(mot) $(dim)d, $(interaction), DᵣW/U=$(Drot)", titlefontsize=10
    )
    τᵣ = 1 / (2*Drot)
    Dtheo(τ) = (Drot == 0 ? τ : (τ*τᵣ) / (τ + τᵣ)) / dim
    #plot!(range(0.1,5,length=500), Dtheo, lc=:green, lw=2, lab=false)
    for g in gdf
        τ = 1 ./ g.λ
        D = (g.Dx + g.Dy)/2
        R = g.R[1]
        plot!(τ, D, m=:c, ms=6, msw=0, lab=R)
    end
    plot!()
end

##
type = "cylinders"
fname = datadir("proc", type, "diffusioncoefficient_fixslope.csv")
df = CSV.read(fname, DataFrame)
sort!(df, [:λ, :R, :Drot, :dim])

##
for dim in [2,3], interaction in ["stick", "slide"], Drot in [0,1], mot in ["RunTumble"]
    τ = range(0.1, 15, length=500)
    plt = makeDplot_cylinders(df, dim, interaction, Drot, mot)
    if Drot == 0
        D = τ / dim
        plot!(τ, D, lc=:green, lw=2, alpha=0.5, lab=false)
        plot!(plt, ylims=(0.01, 0.45))
    else
        #τᵣ = 1 / (2*Drot)
        #D = @. τ * τᵣ / (dim * (τ + τᵣ))
        D = @. (1 / dim) * (1 / (1/τ + 2*Drot))
        plot!(τ, D, lc=:green, lw=2, alpha=0.5, lab=false)
        plot!(plt, ylims=(0.01, 0.175))
    end
    config = @strdict type dim interaction Drot mot
    savefig(plt, plotsdir(savename("D", config, "png")))
    savefig(plt, plotsdir(savename("D", config, "pdf")))
end

##
for dim in [2], interaction in ["stick", "slide"], Drot in [1], mot in ["RunReverse"]
    τ = range(0.1, 15, length=500)
    plt = makeDplot_cylinders(df, dim, interaction, Drot, mot)
    if Drot == 0
        plot!(plt, ylims=(0.01, 0.45))
    else
        #τᵣ = 1 / (2*Drot)
        #D = @. τ * τᵣ / (2 * dim * (τ + τᵣ))
        D = @. (1/dim) * (1 / (2/τ + 2*Drot))
        plot!(τ, D, lc=:green, lw=2, alpha=0.5, lab=false)
        plot!(plt, ylims=(0.01, 0.175))
    end
    config = @strdict type dim interaction Drot mot
    savefig(plt, plotsdir(savename("D", config, "png")))
    savefig(plt, plotsdir(savename("D", config, "pdf")))
end

##
for dim in [2], interaction in ["stick", "slide"], Drot in [1], mot in ["RunReverseFlick"]
    τ = range(0.1, 15, length=500)
    plt = makeDplot_cylinders(df, dim, interaction, Drot, mot)
    if Drot == 0
        plot!(plt, ylims=(0.01, 0.45))
    else
        τᵣ = 1 / (2*Drot)
        D = @. 1 / (2*dim) * (1/τ + 2/τᵣ) / (1/τ + 1/τᵣ)^2
        plot!(τ, D, lc=:green, lw=2, alpha=0.5, lab=false)
        plot!(plt, ylims=(0.01, 0.175))
    end
    config = @strdict type dim interaction Drot mot
    savefig(plt, plotsdir(savename("D", config, "png")))
    savefig(plt, plotsdir(savename("D", config, "pdf")))
end


