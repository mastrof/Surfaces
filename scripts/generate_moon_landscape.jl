using Distributed
@everywhere using DrWatson
@everywhere @quickactivate :Surfaces
@everywhere begin
    using BubbleBath
    using DelimitedFiles
    using SharedArrays
    using Random
end

rng = Xoshiro(1)

L = 50
dx = L/2000
x = range(0, L; step=dx)
y = range(0, L; step=dx)
Rout = 1.0
Rin = 0.8
φ = 0.3

spheres = bubblebath([Rout], φ, (L, L); rng)
shifts = [sincos(rand(rng)*2π) for _ in spheres]
centers = [s.pos for s in spheres]
wm = SharedArray(ones(Int, length(x), length(y)))
@sync @distributed for CI in CartesianIndices(wm)
    ix, iy = CI.I
    p = (x[ix], y[iy])
    for i in eachindex(centers)
        center = centers[i]
        shift = shifts[i]
        d1 = sum(abs2.(p .- center)) - Rout^2
        d2 = sum(abs2.(p .- (center .+ shift))) - Rin^2
        d = max(d1, -d2)
        w = d <= 0 ? 0 : 1
        wm[CI] = min(wm[CI], w)
    end
end

packing = 1 - sum(wm) / length(wm)
fname = savename("landscape", (@strdict L dx Rout Rin packing), "dat")
writedlm(datadir("sims", "moons", fname), Bool.(wm))
