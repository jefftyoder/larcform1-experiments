# Prepare environment
using Pkg; Pkg.activate("./postprocessing")
using Plots, LaTeXStrings, Measures
import AtmosphericProfilesLibrary as APL

# Set plotting backend
gr()

FT = Float32

const γ = FT(8E-3) # K/m
const z_600hpa = FT(3937.0)
const z_300hpa = FT(8457.61398053927)
const P_0 = FT(101300.0)
const T_0 = FT(273.0)                # K  (Surface temperature)
const T_300hpa = FT(T_0 - γ*(z_300hpa))          # K (Temperature at 300 hPa       # Atmospheric lapse rate
const α = FT(0.2340468909276249)    # Rγ/g
const g = FT(9.81)
const R = FT(287.0) # J/kg/K
hPa = FT(100.0)

#ps = [1013, 600, 300, 200].*hPa
#zs = [0.0, 3936.83, 8457.61, 23206.87]
ps = (200:1:1013).*hPa

z = APL.Larcform1_z(FT)
T = APL.Larcform1_T(FT)
p = APL.Larcform1_p(FT)
RH = APL.Larcform1_RH(FT)

θ(z) = T.(p.(z))*(P_0/p.(z)).^α

zs = z.(ps)

fig_T_p = plot(T.(zs), reverse(p.(zs))./hPa, 
            xlabel="Temperature (K)", ylabel="Pressure (hPa)", 
            title="Larcform1 Temperature Profile", label=false)

fig_T_z = plot(T.(zs), zs,
            size = (600, 1000),
            xlabel = "Temperature (K)", ylabel = "Height " * "(m)", 
            title = "Larcform1\n Temperature Profile", label = false,
            legend = false, framestyle = :axes, grid = false, color = :red,
            minorticks = 4, linewidth = 2, tick_direction = :in, thickness_scaling = 1.6)

    #tickfont=font(14)


fig_T_and_θ_of_z = plot(T.(zs),  zs,
        size = (600, 1000),
        xlabel = "Temperature (K)", ylabel = "Height " * "(m)", 
        title = "Larcform1 IC", label = "Air Temperature",
        legend = true, framestyle = :axes, grid = false, color = :red,
        minorticks = 4, linewidth = 2, tick_direction = :in, thickness_scaling = 1.6)

plot!(fig_T_and_θ_of_z, θ.(zs), zs,
            label = "Potential Temperature", color = :blue, linewidth = 2)


fig_θ_of_z = plot(θ.(zs),  zs,
        size = (600, 1000),
        xlabel = "Potential Temperature (K)", ylabel = "Height " * "(m)", 
        title = "Larcform1 Initial Conditions", label = "Potential Temperature",
        legend = false, framestyle = :axes, grid = false, color = :red,
        minorticks = 4, linewidth = 2, tick_direction = :in, thickness_scaling = 1.6)

plot(fig_θ_of_z, fig_T_z, layout = (1, 2), size = (1200, 1000), titlefontsize = 12, 
    titlefontcolor = :black, titlefontfamily = "Computer Modern", titlefontweight = "bold", 
    titlepad = 10)


plot(RH.(zs), zs, 
    size = (600, 1000),
    xlabel = "Relative Humidity", ylabel = "Height " * "(m)", 
    title = "Larcform1 Initial Conditions", label = false,
    legend = false, framestyle = :axes, grid = false, color = :blue,
    minorticks = 4, linewidth = 2, tick_direction = :in, thickness_scaling = 1.6)



    #twinx()