using DrWatson
using DynamicalBilliards
using DelimitedFiles

##
function setup_billiard(r, n)
    bd = billiard_sinai(; r=r, setting="periodic")
    ps = map(_ -> randominside(bd), 1:n)
    return ps, bd
end

##
N = 1000
ncollisions = 50000
Rs = [0.1, 0.15, 0.2, 0.25]
collision_times = [Float64[] for _ in Rs]
for (i,R) in enumerate(Rs)
    ps, bd = setup_billiard(R, N)
    collision_times[i] = vcat([evolve!(p, bd, ncollisions)[1][2:end] for p in ps]...)
    writedlm(datadir("sims", "sinai", "collisiontimes_R=$R.csv"),
        collision_times[i]
    )
end
