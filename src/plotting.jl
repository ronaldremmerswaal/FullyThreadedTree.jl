using Plots

import Plots.plot

function plot(quad::Quad)
    plot()
    # TODO fast plotting by first collecting all polygons, and then plotting them using a single call to plot
    plot!(quad)

    return current()
end

function plot!(quad::Quad)
    if !isleaf(quad)
        for child ∈ quad.children
            plot!(child)
        end
    else
        x = quad.position[1] .+ [-1., 1., 1., -1., -1.] / (2 << (quad.level))
        y = quad.position[2] .+ [-1., -1., 1., 1., -1.] / (2 << (quad.level))
        Plots.plot!(x, y, legend=false, seriestype=:shape, fill_z=quad.state)
    end
end
