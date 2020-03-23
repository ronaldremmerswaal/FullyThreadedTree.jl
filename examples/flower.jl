using FullyThreadedTree

max_level = 10
error_tolerance = 1E-2

# Define a smooth function which has a sharp gradient at a circle
flower(x) = 1 / (1E-1 + (x[1]^2 + x[2]^2 - 0.25 * (1 + 0.0 * cos(5 * atan(x[2], x[1]) + 1)))^2)

tree = initialize_quadtree([0., 0.], flower)

function adaptive_refinement!(tree, fun, max_level, error_tolerance)
    if isleaf(tree) refine!(tree, fun) end

    for level = 2:max_level
        marked = Vector{Quad}()

        max_error = 0.
        nr_cells = 0
        nr_leaf_cells = 0
        for quad ∈ tree
            nr_cells += 1

            if isleaf(quad) nr_leaf_cells += 1 end
            if isleafparent(quad)
                error_estimate = abs(quad.state - sum([child.state for child ∈ quad.children]) / 4)
                max_error = max(error_estimate, max_error)
                if error_estimate > error_tolerance
                    push!(marked, quad)
                end
            end

        end

        print("At level $level we marked $(4*length(marked)) cells (leaf/uniform = $(nr_leaf_cells/(1<<(2*(level-1))))) with max error = $max_error\n")

        if length(marked) == 0
            break
        end

        refine!(marked, fun, recurse=true)
    end

end

function nary(number::Int, n::Int)
    rep = Vector{Int}()
    while number > 0
        rem = mod(number, n)
        push!(rep, rem)
        number = (number - rem) / n
    end
    return rep
end

adaptive_refinement!(tree, flower, max_level, error_tolerance)
