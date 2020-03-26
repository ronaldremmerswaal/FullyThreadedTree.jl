using Plots

import Plots.plot

function plot(tree::Tree{2})
    X = Vector()
    Y = Vector()
    Z = Vector()
    max_level = 0
    for leaf ∈ active_cells(tree)
        append!(X, NaN)
        append!(Y, NaN)
        # append!(Z, 1.)
        append!(X, leaf.position[1] .+ [-1., 1., 1., -1., -1.] / (2 << (leaf.level)))
        append!(Y, leaf.position[2] .+ [-1., -1., 1., 1., -1.] / (2 << (leaf.level)))
        # append!(Z, leaf.state)
        max_level = max(max_level, leaf.level)
    end
    # plot(X, Y, legend=false, seriestype=:shape, fill_z=Z, linewidth=2. / (1 << max_level))
    plot(X, Y, legend=false, seriestype=:shape, linewidth=2. / (1 << max_level))#, fill_z=Z

end
