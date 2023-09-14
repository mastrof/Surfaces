export AbstractBody
abstract type AbstractBody end

function surfaces!(model::ABM, body::AbstractBody, interaction)
    surfaces!(model, [body], interaction)
end
function surfaces!(model::ABM, bodies::AbstractVector{<:AbstractBody}, interaction)
    abmproperties(model)[:bodies] = bodies
    abmproperties(model)[:stuck_to] = zeros(Int, nagents(model))
    abmproperties(model)[:surface!] = interaction
    #== used only for slide! interaction ==#
    abmproperties(model)[:slidingdirection] = fill(+1, nagents(model))
end

@inline contact(a, b, model)  = distance(a, b, model) ≲ radius(a) + radius(b)
@inline ≲(x, y) = x ≤ y || isapprox(x, y; atol=1e-10) # \lesssim
@inline radius(a::SVector{D,<:Real}) where {D} = 0.0
@inline radius(a::AbstractMicrobe) = a.radius
