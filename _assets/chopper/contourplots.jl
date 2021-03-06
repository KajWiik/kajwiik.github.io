using PyPlot, JLD, StructArrays

meshgrid(x, y) = (repeat(x, outer=length(y)), repeat(y, inner=length(x)))

data = load("efficiencies-dense.jld")["data\n"]
R_start = 0.2
#R_step = 0.02
R_step = 0.001
#R_step = 0.4
R_stop = 0.5

focus_start = 0.0
#focus_step = 0.02
focus_step = 0.001
#focus_step = 0.2
focus_stop = 0.2

Rrange = R_start:R_step:R_stop
z₀range = focus_start:focus_step:focus_stop

z₀grid = repeat(reshape(z₀range, 1, :), length(Rrange), 1)
Rgrid = repeat(Rrange, 1, length(z₀range))

for band in (22, 37, 43, 86)
#for band in (43,)
#    z2ω₀ = zeros(length(z₀range), length(Rrange))
#    zgo = zeros(length(z₀range), length(Rrange))
    z2ω₀ = zeros(length(Rrange), length(z₀range))
    zgo = zeros(length(Rrange), length(z₀range))
    @show size(zgo) size(z₀grid) size(Rgrid) length(Rrange) length(z₀range)
    for (x, z₀) in enumerate(z₀range), (y, R) in enumerate(Rrange)
        z2ω₀[y, x] = data[(data.radius .== R) .& (data.focus .== z₀) .& (data.band .== band)].η2ω₀[1]
        zgo[y, x] = data[(data.radius .== R) .& (data.focus .== z₀) .& (data.band .== band)].η_go[1]
    end
    fig = figure("go", figsize = (7,7))
    cp = contour(z₀grid, Rgrid, zgo, colors="blue", linewidth=2.0, levels=range(0.0, step = 0.05, stop = 0.9))
    clabel(cp, inline=1, fontsize=10)
    xlabel("z₀")
    ylabel("R")
    PyPlot.title("Efficiency, geometrical optics, $band GHz")
    tight_layout()
    savefig("eff_go_$band.svg")
    savefig("eff_go_$band.png")
    close(fig)

    fig = figure("2w0", figsize = (7,7))
    cp = contour(z₀grid, Rgrid, z2ω₀, colors="blue", linewidth=2.0, levels=range(0.0, step = 0.05, stop = 0.9))
    clabel(cp, inline=1, fontsize=10)
    xlabel("Distance from focus [m]")
    ylabel("Chopper radius [m]")
    PyPlot.title("Efficiency, blanking at 2ω₀, $band GHz")
    tight_layout()
    savefig("eff_2w0_$band.svg")
    savefig("eff_2w0_$band.png")
    close(fig)
    
end
