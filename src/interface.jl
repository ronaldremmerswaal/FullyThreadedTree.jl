Base.iterate(tree::Tree) = iterate((tree, x->true))

function Base.iterate(tuple::Tuple{Tree, Function}, state=initialized(tuple[1]) ? (tuple[1], 0, Vector{Int}())  : nothing)
    element, count, indices = state

    if element == nothing return nothing end
    filter = tuple[2]

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
function find_next_element(element::Tree{D}, indices::Vector{Int}) where D
    if !isleaf(element)
        # Depth first: go to higher level
        next_element = element.children[1]
        push!(indices, 1)
    elseif isempty(indices)
        next_element = nothing
    else
        # Find sibling or sibling of parent (or grandparent etc.)
        level = findlast(index -> index < 1<<D, indices)
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
        if !isleaf(tree) && !compact
            print(io, "with $(levels(tree)) levels and $(length(leaves(tree))) leaves out of $(length(cells(tree))) cells")
        end
    end
end

cells(tree::Tree) = (tree, x -> true)
cells(tree::Tree, level::Int) = (tree, x -> x.level == level)
leaves(tree::Tree) = (tree, isleaf)
leaves(tree::Tree, level::Int) = (tree, x -> isleaf(x) && x.level == level)
leafparents(tree::Tree) = (tree, isleafparent)
leafparents(tree::Tree, level::Int) = (tree, x -> isleafparent(x) && x.level == level)

function Base.length(tuple::Tuple{Tree, Function})
    count = 0
    for cell ∈ tuple
        count += 1
    end
    return count
end
