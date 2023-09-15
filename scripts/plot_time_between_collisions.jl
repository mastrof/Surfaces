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
        contains(s, "Drot=$(Drot)") && contains(s, "slide"),
        allfilenames
    )
    fig = Figure(; resolution=(600,900))
    for (i,fname) in enumerate(filenames)
        ax = Axis(fig[i,1:3])
        times = readdlm(datadir("proc", "collision_times", fname); skipstart=1)[:,1]
        λ = parse_savename(fname)[2]["λ"]
        hist!(ax, times;
            bins = 0:20, alpha = 0.65, normalization = :pdf,
            label = "λ = $(λ)"
        )
        τ = mean(times)
        vlines!(ax, [τ];
            label = "mean ≈ $(round(τ, sigdigits=3))", linewidth = 4, linestyle = :dash
        )
        axislegend(ax)
        if i == 3
            ax.xlabel = "time between collisions"
        end
    end
    Label(fig[0,2]; text="R = $(R), Dᵣ = $(Drot), $motilepattern", fontsize=28)
    fig
    param = @strdict R Drot motilepattern
    
    Makie.current_backend() == CairoMakie ? save(
        plotsdir("collision_times", savename("free", param, "svg")),
        fig
    ) : fig
end
