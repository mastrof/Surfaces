using DrWatson
using DataFrames
using JLD2, DelimitedFiles, CSV
using LsqFit

function free_volume!(df, type)
    if type == "cylinders" || type == "cylindersesc"
        free_volume_cylinders!(df)
    elseif type == "randomcylinders"
        free_volume_randomcylinders!(df)
    elseif type == "rectangles"
        free_volume_rectangles!(df)
    elseif type == "randomrectangles"
        free_volume_randomrectangles!(df)
    end
end
function free_volume_cylinders!(df)
    transform!(df,
        [:L, :R] => ByRow((L,R) -> 1 - π*(R/L)^2) => :φ
    )
end
function free_volume_randomcylinders!(df)
    nothing # for random cylinders φ is already evaluated
end
function free_volume_rectangles!(df)
    transform!(df,
        [:L, :Ax, :Ay] => ByRow((L,Ax,Ay) -> 1 - 4*Ax*Ay/L^2) => :φ
    )
end
function free_volume_randomrectangles!(df)
    transform!(df,
        [:L,:Ax,:Ay,:N] => ByRow((L,Ax,Ay,N) -> 1 - 4*Ax*Ay*N/L^2) => :φ
    )
end


function specific_surface!(df, type)
    if type == "cylinders" || type == "cylindersesc"
        specific_surface_cylinders!(df)
    elseif type == "randomcylinders"
        specific_surface_randomcylinders!(df)
    elseif type == "rectangles"
        specific_surface_rectangles!(df)
    elseif type == "randomrectangles"
        specific_surface_randomrectangles!(df)
    end
end
function specific_surface_cylinders!(df)
    transform!(df,
        [:L, :R] => ByRow((L,R) -> 2π*R/L^2) => :S
    )
end
function specific_surface_randomcylinders!(df)
    #TODO: how to evaluate S???
    nothing
end
function specific_surface_rectangles!(df)
    transform!(df,
        [:L, :Ax, :Ay] => ByRow((L,Ax,Ay) -> 4*(Ax+Ay)/L^2) => :S
    )
end
function specific_surface_randomrectangles!(df)
    transform!(df,
        [:L,:Ax,:Ay,:N] => ByRow((L,Ax,Ay,N) -> 4(Ax+Ay)*N/L^2) => :S
    )
end

function correlation!(df)
    transform!(df,
        [:motilepattern] => ByRow(m -> correlation(m)) => :α,
        [:motilepattern] => ByRow(_ -> -0.5) => :β # SM below eq S13
    )
end
function correlation(motility)
    if motility == "RunTumble"
        return 0.0
    elseif motility == "RunReverse"
        return -1.0
    elseif motility == "RunReverseFlick"
        return -0.5
    end
end

function optimal_parameters!(df, type)
    insertcols!(df,
        :τ_sim => zeros(Float64, nrow(df)),
        :D_sim => zeros(Float64, nrow(df))
    )
    sort!(df, :λ)
    gdf = if type == "cylinders"
        groupby(df, [:interaction, :Drot, :motilepattern, :L, :R])
    elseif type == "cylindersesc"
        groupby(df, [:interaction, :Drot, :motilepattern, :L, :R, :μ])
    elseif type == "randomcylinders"
        groupby(df, [:interaction, :Drot, :motilepattern])
    elseif type == "rectangles"
        groupby(df, [:interaction, :Drot, :motilepattern, :L, :Ax, :Ay])
    elseif type == "randomrectangles"
        groupby(df, [:interaction, :Drot, :motilepattern, :L, :Ax, :Ay, :N])
    end
    model(x, p) = @. p[2]*(x-p[1])^2 + p[3]
    for g in gdf
        # find index of max diffusivity
        Dmax, j = findmax(g.D)
        # fit parabola to neighborhood of maximum in log-lin scale
        try
            τs = @. log(1 / g.λ[j-2:j+2])
            Ds = g.D[j-2:j+2]
            p = curve_fit(model, τs, Ds, [τs[3], -1.0, Dmax]).param
            τ_sim = p[1]
            D_sim = model(τ_sim, p)
            g.τ_sim .= exp(τ_sim)
            g.D_sim .= D_sim
        catch _
            g.τ_sim .= NaN
            g.D_sim .= NaN
        end
    end
end

for type in ["cylinders", "rectangles", "randomrectangles", "cylindersesc"]
    df = CSV.read(
        datadir("proc", type, "diffusioncoefficient.csv"),
        DataFrame
    )
    free_volume!(df, type) # φ
    specific_surface!(df, type) # S
    correlation!(df) # α, β
    # dimensional factor for Cauchy formula
    transform!(df,
        :dim => ByRow(d -> d == 2 ? π : (d == 3 ? 4.0 : NaN)) => :σ
    )
    # Cauchy formula
    transform!(df,
        [:φ, :S, :U, :σ] => ByRow((φ,S,U,σ) -> σ*φ/(U*S)) => :T
    )
    # scaling parameters
    if type == "cylindersesc"
        eta = 2
        transform!(df,
            [:T, :μ] => ByRow((T,μ) -> T/(eta*(1-μ))) => :a,
            [:α, :Drot, :β, :T] => ByRow((α,Dr,β,T) -> (1-α)/(Dr+(1-β)/T)) => :b
        )
    else
        eta = 2
        transform!(df,
            :T => ByRow(T -> T/eta) => :a,
            [:α, :Drot, :β, :T] => ByRow((α,Dr,β,T) -> (1-α)/(Dr+(1-β)/T)) => :b
        )
    end
    transform!(df,
        [:a, :b] => ByRow((a,b) -> (a+b) / sqrt(a*b)) => :c
    )
    # microstructure coefficient
    transform!(df,
        [:φ, :dim] => ByRow((φ,d) -> 1 - (1-φ)/(d-1)) => :K
    )
    # diffusivity maximum
    transform!(df,
        [:a,:b,:c,:K,:α,:dim] => ByRow(
            (a,b,c,K,α,d) -> sqrt(a*b) * K / ((2+c) * (1-α)*d)
        ) => :D_opt
    )
    # optimal run time
    transform!(df,
        [:a, :b] => ByRow((a,b) -> sqrt(a*b)) => :τ_opt
    )
    # dimensionless mean run time
    transform!(df,
        [:λ, :τ_opt] => ByRow((λ,τ_opt) -> 1 / (τ_opt*λ)) => :ξ
    )
    # modified diffusivity ratio
    transform!(df,
        [:Dx, :Dy] => ByRow((Dx,Dy) -> (Dx+Dy)/2) => :D
    )
    transform!(df,
        :ξ => ByRow(ξ -> 4*ξ / (1+ξ)^2) => :modDiffR
    )
    # optimal run time and diffusivity maximum from simulations
    optimal_parameters!(df, type) # τ_sim, D_sim
    transform!(df,
        [:λ, :τ_sim] => ByRow((λ,τ_sim) -> 1 / (τ_sim*λ)) => :ξ_sim,
        [:c, :D, :D_sim] => ByRow((c,D,D_sim) -> 4 / (2-c+(2+c)*D_sim/D)) => :modDiffR_sim
    )
    fout = datadir("proc", type, "scaling.csv")
    CSV.write(fout, df)
end
