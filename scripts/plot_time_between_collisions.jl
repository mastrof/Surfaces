using DrWatson
using DelimitedFiles
using CairoMakie, Surfaces.SurfacesPlots
set_theme!(SurfacesTheme)

##
allfilenames = filter(s -> contains(s, "free"), readdir(datadir("proc", "collision_times")))

## plot histograms at constant R
#let R = 0.15, Drot = 0.0, motilepattern = "RunTumble"
for R in [0.1, 0.15, 0.2, 0.25],
    Drot in [0.0, 1.0],
    motilepattern in "Run".*["Tumble", "Reverse", "ReverseFlick"]
    filenames = filter(s ->
        contains(s, "R=$(R)_") && contains(s, "$(motilepattern)_") &&
        contains(s, "Drot=$(Drot)"),
        allfilenames
    )
    fig = Figure(; resolution=(600,900))
    for (i,fname) in enumerate(filenames)
        ax = Axis(fig[i,1:3])
        times = readdlm(datadir("proc", "collision_times", fname); skipstart=1)[:,1]
        λ = parse_savename(fname)[2]["λ"]
        hist!(ax, times;
            bins = 0:25, normalization = :pdf, label = "λ = $(λ)",
            color = RGBAf(0., 0., 0., 0.3)
        )
        τ = mean(times)
        vlines!(ax, [τ];
            label = "mean ≈ $(round(τ, sigdigits=3))", linewidth = 4, linestyle = :dash
        )
        τ = median(times)
        vlines!(ax, [τ];
            label = "median ≈ $(round(τ, sigdigits=3))", linewidth = 4, linestyle = :dash
        )
        τ = (1-π*R^2) / (2*R)
        vlines!(ax, [τ];
            label = "Sinai ≈ $(round(τ, sigdigits=3))", linewidth = 4, linestyle = :dot
        )
        axislegend(ax)
        if i == 3
            ax.xlabel = "free path"
        end
        ylims!(ax, (1e-3, 7e-1))
        ax.yscale = log10
    end
    Label(fig[0,2]; text="R = $(R), Dᵣ = $(Drot), $motilepattern", fontsize=24)
    fig
    param = @strdict R Drot motilepattern

    fig
    save(plotsdir("collision_times", savename("free", param, "svg")), fig)
    save(plotsdir("collision_times", savename("free", param, "png")), fig)
end
