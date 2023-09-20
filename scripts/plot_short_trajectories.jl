using DrWatson
using Surfaces
using DataFrames
using LaTeXStrings
using GLMakie, Surfaces.SurfacesPlots
set_theme!(SurfacesTheme)

##
datasets = collect_results(datadir("sims", "short_trajectories")) |> unpack_dataframe
sort!(datasets, :R)

##
param = (
    λ = 1.0,
    Drot = 1.0,
    motilepattern = "RunReverse",
    interaction = "slide",
)
a = subset(datasets, [
        :λ => λ -> λ .== param[:λ],
        :Drot => Drot -> Drot .== param[:Drot],
        :motilepattern => m -> m .== param[:motilepattern],
        :interaction => inter -> inter .== param[:interaction],
])
transform!(a,
    :adf => ByRow(trajectorize) => :trajectory
)

##
x = map(row -> first.(row.trajectory)[:,1:4], eachrow(a))
y = map(row -> last.(row.trajectory)[:,1:4], eachrow(a))

##
fig = Figure(; resolution = (600,600))
axs = [Axis(fig[i,j]) for (i,j) in Iterators.product(1:2, 1:2)]
for i in eachindex(axs)
    draw_trajectories!(fig, axs[i], x[i], y[i], a[i,:R]; linewidth = 2)
    axs[i].title = "R = $(a[i,:R])"
    axs[i].xticksvisible = false
    axs[i].xticklabelsvisible = false
    axs[i].yticksvisible = false
    axs[i].yticklabelsvisible = false
end
Label(fig[0,:];
    text = "λ = $(param[:λ]), Drot = $(param[:Drot]), $(param[:motilepattern])",
    fontsize = 20
)

fig
save(plotsdir("short_trajectories", savename("traj", param, "png")), fig)
