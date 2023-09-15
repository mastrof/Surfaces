using DrWatson
using DelimitedFiles
using CairoMakie, Surfaces.SurfacesPlots
set_theme!(SurfacesTheme)

##
allfilenames = filter(s -> contains(s, "bound"), readdir(datadir("proc", "collision_times")))

## plot histograms at constant R
#let R = 0.25, Drot = 0.0, motilepattern = "RunReverse"
for R in [0.1, 0.15, 0.2, 0.25],
    Drot in [0.0, 1.0],
    motilepattern in "Run".*["Tumble", "Reverse", "ReverseFlick"]
    filenames = filter(s ->
        contains(s, "R=$(R)_") && contains(s, "$(motilepattern)_") &&
        contains(s, "Drot=$(Drot)") && contains(s, "slide"),
        allfilenames
    )
    fig = Figure(; resolution=(600,900))
    for (i,fname) in enumerate(filenames)
        ax = Axis(fig[i,1:3])
        times = readdlm(datadir("proc", "collision_times", fname); skipstart=1)[:,1]
        λ = parse_savename(fname)[2]["λ"]
        hist!(ax, times;
            bins = 50, alpha = 0.65, normalization = :pdf,
            label = "λ = $(λ)"
        )
        τ = mean(times)
        vlines!(ax, [τ];
            label = "tₛ ≈ $(round(τ, sigdigits=3))", linewidth = 4, linestyle = :dash
        )
        lines!(ax, range(extrema(times)...; length=500), t -> exp(-t*λ/2)*λ/2;
            color = SurfacesPlots._COLORSCHEME[2],
            label = "λ/2 exp(-λt/2)",
            alpha = 0.7
        )
        axislegend(ax)
        if i == 3
            ax.xlabel = "time on surface"
        end
    end
    Label(fig[0,2]; text="R = $(R), Dᵣ = $(Drot), $motilepattern", fontsize=28)
    fig
    param = @strdict R Drot motilepattern
    
    Makie.current_backend() == CairoMakie ? save(
        plotsdir("collision_times", savename("bound", param, "svg")),
        fig
    ) : fig
end
