using Plots

import Plots.plot

function plot(tree::Tree)
    X = Vector()
    Y = Vector()
    Z = Vector()
    max_level = 0
    for cell ∈ tree
        if isleaf(cell)
            append!(X, NaN)
            append!(Y, NaN)
            # append!(Z, 1.)
            append!(X, cell.position[1] .+ [-1., 1., 1., -1., -1.] / (2 << (cell.level)))
            append!(Y, cell.position[2] .+ [-1., -1., 1., 1., -1.] / (2 << (cell.level)))
            # append!(Z, cell.state)
            max_level = max(max_level, cell.level)
        end
    end
    # plot(X, Y, legend=false, seriestype=:shape, fill_z=Z, linewidth=2. / (1 << max_level))
    plot(X, Y, legend=false, seriestype=:shape, linewidth=2. / (1 << max_level))#, fill_z=Z

end
