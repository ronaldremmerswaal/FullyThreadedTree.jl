using FullyThreadedTree
using Plots

import Plots.plot


function plot(quad::Quad)
    plot()
    # TODO fast plotting by first collecting all polygons, and then plotting them using a single call to plot
    plot!(quad)

    return current()
end

function plot!(quad::Quad)
    if isdefined(quad.children[1], :level)
        for child ∈ quad.children
            plot!(child)
        end
    else
        x = quad.position[1] .+ [-1., 1., 1., -1., -1.] / (2 << (quad.level))
        y = quad.position[2] .+ [-1., -1., 1., 1., -1.] / (2 << (quad.level))
        plot!(x, y, legend=false, seriestype=:shape, fill_z=quad.state)
    end
end

q = initialize_quadtree([0.0, 0.0], x->1/(x[1]^2+x[2]^2));
plot(q)#, state->state)
