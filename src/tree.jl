
abstract type AbstractTree end

struct Tree <: AbstractTree
    parent::AbstractTree
    level
    position
    neighbours::Array{AbstractTree, 2}  # index1 = direction (x/y), index2 = side (left/right)
    children::Array{AbstractTree, 2}    # index1 = x-direction, index2 = y-direction
    state

    Tree() = new()
    Tree(parent, level, position, neighbours, children, state) = new(parent, level, position, neighbours, children, state)
end

@inline isleaf(cell) = !isdefined(cell.children[1], :level)
@inline initialized(cell) = isdefined(cell, :level)
@inline isleafparent(cell) = !isleaf(cell) && isleaf(cell.children[1])

function initialize_tree(position, state::Function=x->0.)
    cell = Tree(Tree(), 0, position, fill(Tree(), 2, 2), fill(Tree(), 2, 2), state(position))
    return cell
end

# Refine a single leaf (graded)
function refine!(cell::Tree, state::Function=x->0.; recurse=false, may_not_be_leaf=false)
    if isleaf(cell)

        # Setup leaf children
        initialize_children!(cell, state)

        # Set neighbours of children (may contain a call ro refine! due to graded refinement)
        set_neighbours_of_children!(cell, state)

        # NB the neighbouring neighbours of equal level are updated in set_neighbours_of_children!
    elseif !recurse
        may_not_be_leaf || error("Tree is not a leaf and therefore cannot be refined")
    else
        for child ∈ cell.children
            refine!(child, state, recurse=true)
        end
    end

end

# Refine a list of leaves
function refine!(cells::Vector{Tree}, state::Function=x->0.; recurse=false)

    # Order cells in increasing level
    levels = [cell.level for cell ∈ cells]
    cells = cells[sortperm(levels)]

    for cell ∈ cells
        # NB Due to graded refinement a cell may already be refined
        refine!(cell, state, may_not_be_leaf=true, recurse=recurse)
    end
end

# Coarsen a single leaf (not graded)
function coarsen!(cell::Tree)
    for neighbour ∈ cell.neighbours
        if neighbour.level > cell.level return end
    end

    # Remove children
    cell.children = fill(Tree(), 2, 2)

    # Update neighbour pointers (same level only)
    for dir=1:2, side=1:2
        if cell.neighbours[dir,side].level == cell.level + 1
            cell.neighbours[dir,side].neighbours[dir,3-side] = cell
        end
    end

end

function coarsen!(cells::Vector{Tree})
    # Order cells in decreasing level (to ensure that graded noncoarsening is not an issue)
    levels = [cell.level for cell ∈ cells]
    cells = cells[sortperm(levels, rev=true)]

    for cell ∈ cells
        coarsen!(cell)
    end
end

function initialize_children!(cell, state::Function)
    for i=1:2, j=1:2
        pos = cell.position + (Float64.([i, j]) .- 1.5) / (2 << cell.level)
        cell.children[i,j] = Tree(cell, cell.level + 1, pos, fill(Tree(), 2, 2), fill(Tree(), 2, 2), state(pos))
    end
end

# NB when this function is called, it is assumed that the neighbours are fully initialized
# up untill and including level=cell.level
function set_neighbours_of_children!(cell::Tree, state::Function)
    for i=1:2, j=1:2
        # TODO loop over direction

        # Two neighbours are siblings
        cell.children[i,j].neighbours[1,3-i] = cell.children[3-i,j]
        cell.children[i,j].neighbours[2,3-j] = cell.children[i,3-j]

        # The other two aren't
        neighbour_parent = cell.neighbours[1,i]
        if initialized(neighbour_parent)
            if isleaf(neighbour_parent)
                # Neighbouring parent has no children
                if cell.level == neighbour_parent.level
                    neighbour = neighbour_parent
                else
                    # Ensure that different in refined level is at most one between neighbouring cells
                    refine!(neighbour_parent, state)
                    neighbour = cell.neighbours[1,i]
                end
            else
                # If neighbouring parent has children, then take neighbouring child
                neighbour = neighbour_parent.children[3-i,j]

                # Also update the neighbours of the neighbour (only when they are of equal level)
                neighbour_parent.children[3-i,j].neighbours[1,3-i] = cell.children[i,j]
            end
            cell.children[i,j].neighbours[1,i] = neighbour
        end

        neighbour_parent = cell.neighbours[2,j]
        if initialized(neighbour_parent)
            if isleaf(neighbour_parent)
                # Neighbouring parent has no children
                if cell.level == neighbour_parent.level
                    neighbour = neighbour_parent
                else
                    # Ensure that different in refined level is at most one between neighbouring cells
                    refine!(neighbour_parent, state)
                    neighbour = cell.neighbours[2,j]
                end
            else
                # If neighbouring parent has children, then take neighbouring child
                neighbour = neighbour_parent.children[i,3-j]

                # Also update the neighbours of the neighbour (only when they are of equal level)
                neighbour_parent.children[i,3-j].neighbours[2,3-j] = cell.children[i,j]
            end
            cell.children[i,j].neighbours[2,j] = neighbour
        end
    end
end
