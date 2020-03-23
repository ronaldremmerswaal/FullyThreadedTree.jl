function Base.iterate(cell::Tree{D}, state=initialized(cell) ? (cell, 0, Vector{Int}())  : nothing) where D
    element, count, indices = state

    if element == nothing return nothing end

    if isleaf(element)
        indices[end] += 1
        if indices[end] <= 1<<D
            next_element = element.parent.children[indices[end]]
        end
    else
        next_element = element.children[1]
        push!(indices, 1)
    end

    if indices[end] > 1<<D
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
    return (element, (next_element, count + 1, indices))
end

function Base.show(io::IO, tree::Tree)
    compact = get(io, :compact, false)

    print(io, "Tree ")
    if initialized(tree)
        if tree.level == 0
            print(io, "root ")
        else
            print(io, "on level $(tree.level) ")
        end
        if !isleaf(tree) && !compact
            print(io, "with $(1 + max_level(tree)) levels and $(nr_leaves(tree)) leaves out of $(nr_cells(tree)) cells")
        end
    end
end
