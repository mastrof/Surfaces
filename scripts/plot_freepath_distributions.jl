using DrWatson
using DelimitedFiles
using DataFrames
using JLD2
using StatsBase
using Plots
using LaTeXStrings

##
function init_dataframe(filename)
    dict = parse_savename(filename)[2]
    k = keys(dict)
    v = map(T -> T[], typeof.(values(dict)))
    DataFrame(
        (k .=> v)...,
        "times" => Vector{Float64}[],
    )
end

##
type = "cylinders"
dim = 2
fnames = filter(
    s -> contains(s, "free_"),
    readdir(datadir("proc", type); join=true)
)

##
df = init_dataframe(fnames[1])
for fname in fnames
    times = vec(readdlm(fname; skipstart=1))
    config = parse_savename(fname)[2]
    newdf = DataFrame(
        config...,
        "times" => [times]
    )
    append!(df, newdf)
end
#fout = datadir("proc", "cylinders", "freepath.jld2")

##
#let interaction = "stick", mot = "RunTumble", R = 0.25
for interaction in ["stick"], mot in ["RunTumble", "RunReverse", "RunReverseFlick"],
    R in [0.1, 0.25]
    flt = [
        :interaction => inter -> inter .== interaction,
        :motilepattern => m -> m .== mot,
        :R => r -> r .== R,
    ]
    subdf = subset(df, flt)
    sort!(subdf, :λ; rev=true)
    gdf = groupby(subdf, [:λ])[1:2:end]

    cmap = palette(:coolwarm, length(gdf))
    plot(palette=cmap, legendtitle=L"\mathrm{U\tau \, / \, W}",
        legend=:best, legend_columns=2,
        xlab=L"\mathrm{length \; of \; free \; path}",
        ylab=L"\mathrm{\log \; pdf}",
        title="$(mot) $(dim)d, $(interaction), R=$(R)", titlefontsize=10
    )
    for g in gdf
        bins = R == 0.25 ? (0.01:0.05:3.5) : (0.01:0.05:7.0)
        h = normalize(fit(Histogram, g.times[1], bins); mode=:pdf)
        x = midpoints(h.edges[1])
        y = h.weights
        y[y .== 0] .= NaN
        y .= log10.(y)
        plot!(x, y,
            lw=1, m=:c, ms=2, msw=0, alpha=0.8, fillalpha=0.8,
            lab=round(1/g.λ[1], sigdigits=2)
        )
    end
    plot!(
        ylims = R==0.25 ? (-4.5, 1) : (-3.5, 1)
    )
    config = @strdict type dim interaction mot R
    savefig(plotsdir(savename("freepath", config, "png")))
    savefig(plotsdir(savename("freepath", config, "pdf")))
end
