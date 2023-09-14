export SurfacesPlots

module SurfacesPlots

using Surfaces
using StaticArrays
using GLMakie
using Colors, ColorSchemes

export SurfacesTheme
export cylinder, cylinder_array


palette(colors::Symbol, n::Int) = get(colorscheme[colors], range(0,1,length=n))
_COLORSCHEME = colorschemes[:Dark2_8]
_MARKERS = [
    :circle, :rect, :diamond,
    :utriangle, :dtriangle, :rtriangle, :ltriangle,
    :hexagon, :pentagon, :cross, :xcross,
    :star4, :star5, :star6, :star8
]

SurfacesTheme = Theme(
    #== global properties ==#
    fontsize = 32,
    palette = (
        color = _COLORSCHEME,
        marker = _MARKERS,
        linestyle = :solid,
    ),
    fonts = (
        regular = "Arial",
        bold = "Arial Bold",
        italic = "/usr/share/fonts/TTF/ariali.ttf"
    ),
    Axis = (
        # grid
        xgridvisible = false,
        ygridvisible = false,
        # ticks
        xticksize = -10,
        yticksize = -10,
        xminorticksivisible = false,
        yminorticksvisible = false,
        xticksmirrored = true,
        yticksmirrored = true,
        # title
        titlefont = :bold,
        titlesize = 24,
    ),
    Legend = (
        framevisible = false,
        titlefont = :regular,
        titlesize = 28,
        labelsize = 28,
    ),
    Colorbar = (
        tickvisible = false,
    ),
    Label = (
        font = :bold,
        fontsize = 32,
        halign = :center,
        padding = (0, 5, 5, 0)
    ),

    #== plot-specific properties ==#
    Lines = (
        linewidth = 4,
        cycle = Cycle([:color])
    ),
    Scatter = (
        markersize = 16,
        cycle = Cycle([:color, :marker], covary=true)
    ),
    Scatterlines = (
        linewidth = 4,
        markersize = 16,
        cycle = Cycle([:color, :marker], covary=true)
    )
)
set_theme!(SurfacesTheme)


cylinder(origin::Union{<:NTuple{2},<:SVector{2}}, radius) =
    Circle(Point2f(origin), radius*1f0)

function cylinder_array(xs, ys, radius)
    (cylinder((x,y),radius) for (x,y) in Iterators.product(xs,ys))
end

include("trajectories.jl")


end # module
