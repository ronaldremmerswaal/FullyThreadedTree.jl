using Plots

import Plots.plot

function plot(tree::Tree{1})
    X = Vector()
    Y = Vector()
    max_level = 0
    for cell ∈ active_cells(tree)
        push!(X, cell.position[1])
        push!(Y, cell.state)

        max_level = max(max_level, cell.level)
    end

    plot(X, Y, legend = false)
    plot!(X, zeros(length(X)), seriestype=:scatter, markersize = 20. /  (1 << max_level))

    return current()
end

function plot(tree::Tree{2}; markers::Bool = false, max_marker_level::Int = 5, path::Bool = false)
    X = Vector()
    Y = Vector()

    max_level = 0
    for cell ∈ active_cells(tree)
        append!(X, NaN)
        append!(Y, NaN)

        append!(X, cell.position[1] .+ [-1., 1., 1., -1., -1.] / (2 << (cell.level)))
        append!(Y, cell.position[2] .+ [-1., -1., 1., 1., -1.] / (2 << (cell.level)))

        max_level = max(max_level, cell.level)
    end
    linewidth0 = 4.
    linewidth = linewidth0 / (1 << max_level)
    plot(X, Y, legend = false, seriestype = :shape, fill = :white, linewidth = linewidth)

    if path
        X = Vector()
        Y = Vector()
        for cell ∈ active_cells(tree)
            pos = centroid(cell)
            push!(X, pos[1])
            push!(Y, pos[2])
        end
        plot!(X, Y, linewidth = linewidth, color = :lightgray)
    end

    if markers
        markerstrokewidth = linewidth0 /  (1 << min(max_marker_level, max_level))
        markersize = 20. /  (1 << min(max_marker_level, max_level))

        X = Vector()
        Y = Vector()
        for cell ∈ active_cells(tree)
            if cell.level < max_marker_level
                pos = centroid(cell)
                push!(X, pos[1])
                push!(Y, pos[2])
            end
        end
        plot!(X, Y, seriestype = :scatter, markersize = markersize, markerstrokewidth = markerstrokewidth, marker = :circle)

        X = Vector()
        Y = Vector()
        for face ∈ active_faces(tree)
            if level(face) < max_marker_level
                pos = centroid(face)
                push!(X, pos[1])
                push!(Y, pos[2])
            end
        end
        plot!(X, Y, seriestype = :scatter, markersize = markersize, markerstrokewidth = markerstrokewidth, marker=:square)
    end

    return current()
end
