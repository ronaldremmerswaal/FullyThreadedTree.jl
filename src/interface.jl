Base.iterate(tree::Tree) = iterate((tree, x->true))

function Base.iterate(tuple::Tuple{Tree, Function}, state=initialized(tuple[1]) ? (tuple[1], 0, Vector{Int}())  : nothing)
    element, count, indices = state

    if element == nothing return nothing end

    filter = tuple[2]
    next_element = element
    while true
        next_element = find_next_element(next_element, indices)
        if next_element == nothing || filter(next_element) break end
    end

    return (element, (next_element, count + 1, indices))
end

function find_next_element(element::Tree{D}, indices::Vector{Int}) where D
    if !isleaf(element)
        # Depth first: go to higher level
        next_element = element.children[1]
        push!(indices, 1)
    elseif isempty(indices)
        next_element = nothing
    else
        indices[end] += 1
        if indices[end] <= 1<<D
            # Go to sibling
            next_element = element.parent.children[indices[end]]
        else
            # Find sibling of parent
            next_element = element
            while indices[end] > 1<<D
                next_element = next_element.parent
                pop!(indices)
                if isempty(indices)
                    next_element = nothing
                    break
                end
                indices[end] += 1
                if indices[end] <= 1<<D
                    next_element = next_element.parent.children[indices[end]]
                end
            end
        end
    end

    return next_element
end

function Base.show(io::IO, tree::Tree)
    compact = get(io, :compact, false)

    print(io, "$(typeof(tree)) ")
    if initialized(tree)
        if tree.level == 0
            print(io, "root ")
        else
            print(io, "on level $(tree.level) ")
        end
        if !isleaf(tree) && !compact
            print(io, "with $(levels(tree)) levels and $(nr_leaves(tree)) leaves out of $(nr_cells(tree)) cells")
        end
    end
end

cells(tree::Tree) = (tree, x->true)
leaves(tree::Tree) = (tree, isleaf)
leafparents(tree::Tree) = (tree, isleafparent)
