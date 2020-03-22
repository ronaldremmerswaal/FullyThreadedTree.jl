using FullyThreadedTree

max_level = 10
error_tolerance = 1E-2

# Define a smooth function which has a sharp gradient at a circle
flower(x) = 1 / (1E-1 + (x[1]^2 + x[2]^2 - 0.25 * (1 + 0.0 * cos(5 * atan(x[2], x[1]) + 1)))^2)

tree = initialize_quadtree([0., 0.], flower)
refine!(tree, flower)

function adaptive_refinement!(tree, fun, max_level, error_tolerance)

    for level = 2:max_level
        marked = Vector{Quad}()

        indices = Vector{Int64}()
        quads = Vector{Quad}()
        push!(indices, 1)
        push!(quads, tree)
        depth = 0
        max_error = 0.
        nr_cells = 0
        while true
            if indices[end] < 5
                quad = quads[end]

                nr_cells += 1
                if isleafparent(quad)
                    error_estimate = abs(quad.state - sum([child.state for child ∈ quad.children]) / 4)
                    max_error = max(error_estimate, max_error)
                    if error_estimate > error_tolerance
                        push!(marked, quad)
                    end
                end

                if isleaf(quads[end])
                    indices[end] += 1
                    if indices[end] < 5
                        quads[end] = quads[end-1].children[indices[end]]
                    end
                else
                    push!(quads, quad.children[1])
                    push!(indices, 1)
                end
            else
                pop!(quads)
                pop!(indices)
                if length(indices) == 1
                    break
                end
                indices[end] += 1
                if indices[end] < 5
                    quads[end] = quads[end-1].children[indices[end]]
                end
            end

        end

        print("At level $level we marked $(4*length(marked)) cells (out of $nr_cells, uniform $(2<<(2*level))) with max error = $max_error\n")

        if length(marked) == 0
            break
        end

        refine!(marked, fun, recurse=true)
    end

end

adaptive_refinement!(tree, flower, max_level, error_tolerance)
