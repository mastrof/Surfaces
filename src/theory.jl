export bulk_diffusivity

function bulk_diffusivity(τ, Drot, dim, motility)
    if motility == "RunTumble"
        bulk_diffusivity_runtumble(τ, Drot, dim)
    elseif motility == "RunReverse"
        bulk_diffusivity_runreverse(τ, Drot, dim)
    elseif motility == "RunReverseFlick"
        bulk_diffusivity_runreverseflick(τ, Drot, dim)
    else
        throw(ArgumentError("Invalid argument motility=$motility"))
    end
end

function bulk_diffusivity_runtumble(τ, Drot, dim)
    (1/dim) / (1/τ + (dim-1)*Drot)
end

function bulk_diffusivity_runreverse(τ, Drot, dim)
    (1/dim) / (2/τ + (dim-1)*Drot)
end

function bulk_diffusivity_runreverseflick(τ, Drot, dim)
    (1/2dim) * (1/τ + 2*(dim-1)*Drot) / (1/τ + (dim-1)*Drot)^2
end
