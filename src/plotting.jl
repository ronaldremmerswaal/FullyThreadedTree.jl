using Plots

import Plots.plot

function plot(tree::Tree{1})
    X = Vector()
    Y = Vector()
    max_level = 0
    for cell ∈ cells(tree, filter=active)
        push!(X, cell.position[1])
        push!(Y, cell.state)

        max_level = max(max_level, level(cell))
    end

    plot(X, Y, legend = false)
    plot!(X, zeros(length(X)), seriestype=:scatter, markersize = 20. /  (1 << max_level))

    return current()
end

function plot(tree::Tree{2}; markers::Bool = false, max_marker_level::Int = 5, path::Bool = false)
    X = Vector()
    Y = Vector()

    max_level = 0
    for cell ∈ cells(tree, filter=active)
        append!(X, NaN)
        append!(Y, NaN)

        append!(X, cell.position[1] .+ [-1., 1., 1., -1., -1.] / (2 << (level(cell))))
        append!(Y, cell.position[2] .+ [-1., -1., 1., 1., -1.] / (2 << (level(cell))))

        max_level = max(max_level, level(cell))
    end
    linewidth0 = 4.
    linewidth = linewidth0 / (1 << max_level)
    plot(X, Y, legend = false, color=:black, linewidth = linewidth)

    if path
        X = Vector()
        Y = Vector()
        for cell ∈ cells(tree, filter=active)
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
        for cell ∈ cells(tree, filter=active)
            if level(cell) < max_marker_level
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
        plot!(X, Y, seriestype = :scatter, markersize = markersize, markerstrokewidth = markerstrokewidth, marker = :square)
    end

    return current()
end

function plot(tree::Tree{3}; markers::Bool = false, max_marker_level::Int = 5, path::Bool = false, wireframe=true)
    X = Vector()
    Y = Vector()
    Z = Vector()

    max_level = levels(tree) - 1
    linewidth0 = 4.
    linewidth = linewidth0 / (1 << max_level)
    if wireframe
        xloop = [-1., 1., 1., -1., -1.]
        yloop = [-1., -1., 1., 1., -1.]
        for cell ∈ cells(tree, filter=active)
            append!(X, NaN)
            append!(Y, NaN)
            append!(Z, NaN)

            append!(X, cell.position[1] .+ xloop / (2 << (level(cell))))
            append!(Y, cell.position[2] .+ yloop / (2 << (level(cell))))
            append!(Z, cell.position[3] .+ -ones(5) / (2 << (level(cell))))
            append!(X, cell.position[1] .+ xloop / (2 << (level(cell))))
            append!(Y, cell.position[2] .+ yloop / (2 << (level(cell))))
            append!(Z, cell.position[3] .+ ones(5) / (2 << (level(cell))))
            for i=2:4
                append!(X, NaN)
                append!(Y, NaN)
                append!(Z, NaN)
                append!(X, cell.position[1] .+ [xloop[i], xloop[i]] / (2 << (level(cell))))
                append!(Y, cell.position[2] .+ [yloop[i], yloop[i]] / (2 << (level(cell))))
                append!(Z, cell.position[3] .+ [-1., 1.] / (2 << (level(cell))))
            end
        end
        plot(X, Y, Z, legend = false, color = :black, linewidth = linewidth)
    end

    if path
        X = Vector()
        Y = Vector()
        Z = Vector()
        for cell ∈ cells(tree, filter=active)
            pos = centroid(cell)
            push!(X, pos[1])
            push!(Y, pos[2])
            push!(Z, pos[3])
        end
        plot!(X, Y, Z, linewidth = linewidth, color = :lightgray)
    end

    if markers
        markerstrokewidth = linewidth0 /  (1 << min(max_marker_level, max_level))
        markersize = 20. /  (1 << min(max_marker_level, max_level))

        X = Vector()
        Y = Vector()
        Z = Vector()
        for cell ∈ cells(tree, filter=active)
            if level(cell) < max_marker_level
                pos = centroid(cell)
                push!(X, pos[1])
                push!(Y, pos[2])
                push!(Z, pos[3])
            end
        end
        plot!(X, Y, Z, seriestype = :scatter, markersize = markersize, markerstrokewidth = markerstrokewidth, marker = :circle)

        X = Vector()
        Y = Vector()
        Z = Vector()
        for face ∈ active_faces(tree)
            if level(face) < max_marker_level
                pos = centroid(face)
                push!(X, pos[1])
                push!(Y, pos[2])
                push!(Z, pos[3])
            end
        end
        plot!(X, Y, Z, seriestype = :scatter, markersize = markersize, markerstrokewidth = markerstrokewidth, marker = :square)
    end

    return current()
end
