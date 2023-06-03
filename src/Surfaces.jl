module Surfaces

using JLD2, DelimitedFiles
using DrWatson: parse_savename
using LinearAlgebra, StatsBase, Distributions, Random
using DataFrames
using Rotations, CoordinateTransformations
using Agents, MicrobeAgents

export SurfyMicrobe
mutable struct SurfyMicrobe{D} <: AbstractMicrobe{D}
    id::Int
    pos::NTuple{D,Float64}
    motility::AbstractMotility
    vel::NTuple{D,Float64}
    speed::Float64
    speed_surface::Float64
    turn_rate::Float64
    turn_rate_surface::Float64
    escape_probability::Float64
    is_stuck::Bool
    rotational_diffusivity::Float64
    radius::Float64
    state::Float64

    SurfyMicrobe{D}(
        id::Int = rand(1:typemax(Int32)),
        pos::NTuple{D,<:Real} = ntuple(zero,D);
        motility::AbstractMotility = RunTumble(),
        vel::NTuple{D,<:Real} = rand_vel(D),
        speed::Real = rand_speed(motility),
        speed_surface::Real = 0.0,
        turn_rate::Real = 1.0,
        turn_rate_surface::Real = turn_rate,
        escape_probability::Real = 1.0,
        is_stuck::Bool = false,
        rotational_diffusivity::Real = 0.0,
        radius::Real = 0.0,
        state::Real = 0.0
    ) where {D} = new{D}(id,
        Float64.(pos), motility, Float64.(vel), Float64(speed), Float64(speed_surface),
        Float64(turn_rate), Float64(turn_rate_surface), Float64(escape_probability),
        is_stuck, Float64(rotational_diffusivity), Float64(radius), Float64(state)
    )
end


include("bodies.jl")
include("cylinders.jl")
include("microbe.jl")
include("model.jl")

end # module
