using Plots

import Plots.plot

function plot(tree::Tree{2})
    X = Vector()
    Y = Vector()
    Z = Vector()
    max_level = 0
    for cell ∈ active_cells(tree)
        append!(X, NaN)
        append!(Y, NaN)
        # append!(Z, 1.)
        append!(X, cell.position[1] .+ [-1., 1., 1., -1., -1.] / (2 << (cell.level)))
        append!(Y, cell.position[2] .+ [-1., -1., 1., 1., -1.] / (2 << (cell.level)))
        # append!(Z, leaf.state)
        max_level = max(max_level, cell.level)
    end
    # plot(X, Y, legend=false, seriestype=:shape, fill_z=Z, linewidth=2. / (1 << max_level))
    plot(X, Y, legend=false, seriestype=:shape, linewidth=2. / (1 << max_level))#, fill_z=Z


    X = Vector()
    Y = Vector()
    for cell ∈ active_cells(tree)
        pos = centroid(cell)
        push!(X, pos[1])
        push!(Y, pos[2])
    end

    plot!(X, Y, seriestype=:scatter, markersize = 20. /  (1 << max_level), marker=:circle)

    X = Vector()
    Y = Vector()
    for face ∈ active_faces(tree)
        pos = centroid(face)
        push!(X, pos[1])
        push!(Y, pos[2])
    end
    plot!(X, Y, seriestype=:scatter, markersize = 20. /  (1 << max_level), marker=:square)

end
