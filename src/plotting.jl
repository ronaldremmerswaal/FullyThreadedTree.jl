using Plots

import Plots.plot

function plot(tree::Quad)
    X = Vector()
    Y = Vector()
    Z = Vector()
    max_level = 0
    for quad ∈ tree
        if isleaf(quad)
            append!(X, NaN)
            append!(Y, NaN)
            # append!(Z, 1.)
            append!(X, quad.position[1] .+ [-1., 1., 1., -1., -1.] / (2 << (quad.level)))
            append!(Y, quad.position[2] .+ [-1., -1., 1., 1., -1.] / (2 << (quad.level)))
            # append!(Z, quad.state)
            max_level = max(max_level, quad.level)
        end
    end
    # plot(X, Y, legend=false, seriestype=:shape, fill_z=Z, linewidth=2. / (1 << max_level))
    plot(X, Y, legend=false, seriestype=:shape, linewidth=2. / (1 << max_level))#, fill_z=Z

end
