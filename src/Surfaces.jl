module Surfaces

using JLD2, DelimitedFiles
using DrWatson: parse_savename
using LinearAlgebra, StatsBase, Distributions, Random
using DataFrames
using Rotations, CoordinateTransformations
using Agents, MicrobeAgents
using DataFrames

export SurfyMicrobe
@agent SurfyMicrobe{D} ContinuousAgent{D,Float64} where {D} AbstractMicrobe{D} begin
    speed::Float64
    speed_surface::Float64
    motility::AbstractMotility = RunTumble()
    turn_rate::Float64 = 1.0
    turn_rate_surface::Float64 = turn_rate
    escape_probability::Float64 = 1.0
    is_stuck::Bool = false
    rotational_diffusivity::Float64 = 0.0
    radius::Float64 = 0.0
    state::Float64 = 0.0
end

include("utils.jl")
include("bodies.jl")
include("slit.jl")
include("cylinders.jl")
include("microbe.jl")
include("model.jl")

# postprocessing
include("theory.jl")

# plotting submodule
include("SurfacesPlots/SurfacesPlots.jl")

end # module
