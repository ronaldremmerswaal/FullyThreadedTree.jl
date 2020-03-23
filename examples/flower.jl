using FullyThreadedTree
using PreyttyTables

max_level = 12
error_tolerance = 1E-2
R = pi / 12.

# Define a smooth function which has a sharp gradient at a circle
flower(x) = x[1]^2 + x[2]^2 - R^2 * (1 + 0.1 * cos(5 * atan(x[2], x[1]) + 1))^2
# shape(x) = 1 / (1E-2 + (x[1]^2 + x[2]^2 - R^2 * (1 + 0.1 * cos(5 * atan(x[2], x[1]) + 1)))^2)
shape(x) = tanh(32 * pi * flower(x))

tree = initialize_quadtree([0., 0.], shape)

function adaptive_refinement!(tree, fun, max_level, error_tolerance)
    if isleaf(tree) refine!(tree, fun) end

    max_error = Vector()
    integral = Vector()
    nr_cells = Vector()
    nr_leaf_cells = Vector()
    nr_marked_cells = Vector()

    for level = 2:max_level
        marked = Vector{Quad}()

        push!(max_error, 0.)
        push!(nr_cells, 0)
        push!(nr_leaf_cells, 0)
        push!(nr_marked_cells, 0)
        for quad ∈ tree
            nr_cells[end] += 1

            if isleaf(quad) nr_leaf_cells[end] += 1 end
            if isleafparent(quad)
                error_estimate = abs(quad.state - sum([child.state for child ∈ quad.children]) / 4)
                max_error[end] = max(error_estimate, max_error[end])
                if error_estimate > error_tolerance
                    nr_marked_cells[end] += 4
                    push!(marked, quad)
                end
            end

        end
        push!(integral, integrate(tree))

        if length(marked) == 0
            max_level = level
            break
        end

        refine!(marked, fun, recurse=true)
    end

    formatter = Dict(0 => (v, i) -> typeof(v) == Int ? Int(v) : round(v; digits=3))
    pretty_table(hcat(2 : max_level, nr_leaf_cells, nr_cells, nr_marked_cells, max_error, integral), ["level", "# leaves", "# cells", "# marked", "error", "integral"], tf = markdown, formatter = formatter)

end

adaptive_refinement!(tree, shape, max_level, error_tolerance)
display(plot(tree))
