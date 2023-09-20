export draw_trajectories!

function draw_trajectories!(fig, ax, x, y, R; kwargs...)
    xmin, xmax = extrema(x)
    ymin, ymax = extrema(y)
    xmin, ymin = floor.(Int, (xmin, ymin))
    xmax, ymax = ceil.(Int, (xmax, ymax))

    xsc = (xmin:xmax) .+ 0.5
    ysc = (ymin:ymax) .+ 0.5
    for cyl in cylinder_array(xsc, ysc, R)
        mesh!(ax, cyl, color=:black)
    end

    for j in axes(x, 2)
        lines!(ax, view(x, :, j), view(y, :, j); kwargs...)
    end

    xlims!(ax, (xmin, xmax))
    ylims!(ax, (ymin, ymax))
    return fig
end
