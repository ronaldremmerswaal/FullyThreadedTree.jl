Base.iterate(tree::Tree) = iterate((tree, x->true))

function Base.iterate(tuple::Tuple{Tree, Function}, state=initialized(tuple[1]) ? (tuple[1], 0, Vector{Int}())  : nothing)
    element, count, indices = state

    if element == nothing return nothing end
    tree, filter = tuple

    next_element = find_next_element(element, indices)
    while !filter(element)
        element = next_element
        if element == nothing return nothing end
        next_element = find_next_element(element, indices)
    end
    return (element, (next_element, count + 1, indices))
end

# indices[l] yields the child index at level l in the following sense
# element = element.parent.children[indices[end]]
#         = element.parent.parent.children[indices[end-1]].children[end]
#         = ...
function find_next_element(element::Tree{N}, indices::Vector{Int}) where N
    if !active(element)
        # Depth first: go to higher level
        next_element = element.children[1]
        push!(indices, 1)
    elseif isempty(indices)
        next_element = nothing
    else
        # Find sibling or sibling of parent (or grandparent etc.)
        level = findlast(index -> index < 1<<N, indices)
        if level == nothing
            next_element = nothing
        else
            nr_to_pop = length(indices) - level
            next_element = element
            for i=1:nr_to_pop
                next_element = next_element.parent
                pop!(indices)
            end
            indices[end] += 1
            next_element = next_element.parent.children[indices[end]]
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
        if !active(tree) && !compact
            print(io, "with $(levels(tree)) levels and $(length(active_cells(tree))) active_cells out of $(length(cells(tree))) cells")
        end
    end
end

cells(tree::Tree) = (tree, x -> true)
cells(tree::Tree, level::Int) = (tree, x -> x.level == level)
active_cells(tree::Tree) = (tree, active)
active_cells(tree::Tree, level::Int) = (tree, x -> active(x) && x.level == level)
parents_of_active_cell(tree::Tree) = (tree, parent_of_active)
parents_of_active_cell(tree::Tree, level::Int) = (tree, x -> parent_of_active(x) && x.level == level)

function Base.length(tuple::Tuple{Tree, Function})
    count = 0
    for cell ∈ tuple
        count += 1
    end
    return count
end

# function faces(tree::Tree) =
