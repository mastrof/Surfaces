using DrWatson
using DelimitedFiles
using CairoMakie
using Surfaces.SurfacesPlots
set_theme!(SurfacesTheme)

##
filenames = readdir(datadir("sims", "sinai"))
Rs = sort(map(fname -> parse_savename(fname)[2]["R"], filenames))
collision_times = [
    readdlm(datadir("sims", "sinai", fname))[:,1]
    for fname in filenames
]

##
fig = Figure()
for (i,R) in enumerate(Rs)
    j = mod1(i, 2)
    k = ceil(Int, i/2)
    ax = Axis(fig[j, k])
    hist!(ax, collision_times[i];
        bins = 0:0.25:40, normalization = :pdf,
        alpha = 0.75,
        label = "R = $R"
    )
    τ = mean(collision_times[i])
    vlines!(ax, [τ];
        linewidth = 6, linestyle = :dash,
        label = "mean ≈ $(round(τ, sigdigits=3))"
    )
    axislegend(ax)
    if j == 2
        ax.xlabel = "time between collisions"
    end
    ylims!(ax, (1e-4, 7.5e-1))
    ax.yscale = log10
end
Label(fig[0,:]; text="Periodic Sinai Billiard (5e7 collisions / dataset)", fontsize=24)

if Makie.current_backend() == CairoMakie
    save(plotsdir("sinai", "collision_times.svg"), fig)
else
    fig
end
