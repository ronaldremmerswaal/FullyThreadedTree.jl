
abstract type AbstractTree{D} end

struct DummyTree{D} <: AbstractTree{D} end

# A D-dimensional tree
struct Tree{D} <: AbstractTree{D}
    parent::AbstractTree{D}
    level::Int
    position::Vector
    neighbours::Array{AbstractTree{D}, 2}  # index1 = direction (x/y), index2 = side (left/right), ...
    children::Array{AbstractTree{D}, D}    # index1 = x-direction, index2 = y-direction, ...
    state
end

Tree(parent, level, position, neighbours, children, state) = Tree{length(position)}(parent, level, position, neighbours, children, state)

@inline isleaf(cell) = !isa(cell.children[1], Tree)
@inline initialized(cell) = isa(cell, Tree)
@inline isleafparent(cell) = !isleaf(cell) && isleaf(cell.children[1])

function initialize_tree(position, state::Function=x->0.)
    D = length(position)
    return Tree(DummyTree{D}(), 0, position, fill(DummyTree{D}(), D, 2), fill(DummyTree{D}(), Tuple(2*ones(Int, D))), state(position))
end

# Refine a single leaf (graded)
function refine!(cell::Tree, state::Function=x->0.; recurse=false)
    if isleaf(cell)
        # Setup leaf children
        initialize_children!(cell, state)

        # Set neighbours of children (may contain a call ro refine! due to graded refinement)
        set_neighbours_of_children!(cell, state)

        # NB the neighbouring neighbours of equal level are updated in set_neighbours_of_children!
    elseif recurse
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
        refine!(cell, state, recurse=recurse)
    end
end

# Coarsen a single leaf (graded in the sense that if neighbours are of a higher level then we do not coarsen)
function coarsen!(cell::Tree{D}) where D
    for neighbour ∈ cell.neighbours
        # graded noncoarsening
        if !isleaf(neighbour) return end
    end

    # Remove children
    cell.children = fill(DummyTree{D}(), Tuple(2*ones(Int, D)))

    # Update neighbour pointers (same level only)
    for dir=1:D, side=1:2
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

@generated function initialize_children!(cell::Tree{D}, state::Function) where D
    quote
        children = cell.children
        Base.Cartesian.@nloops $D i d->1:2 begin
            pos = cell.position + (Float64.(collect(Base.Cartesian.@ntuple $D i)) .- 1.5) / (2 << cell.level)
            (Base.Cartesian.@nref $D children i) = Tree(cell, cell.level + 1, pos, fill(DummyTree{$D}(), $D, 2), fill(DummyTree{$D}(), Tuple(2*ones(Int, $D))), state(pos))
        end
    end
end

# NB this is the D-dimensional variant of
# function initialize_children!(cell::Tree{D}, state::Function) where D
#     for i=1:2, j=1:2
#         pos = cell.position + (Float64.([i, j]) .- 1.5) / (2 << cell.level)
#         cell.children[i,j] = Tree(cell, cell.level + 1, pos, fill(DummyTree{D}(), 2, 2), fill(DummyTree{D}(), 2, 2), state(pos))
#     end
# end

# NB when this function is called, it is assumed that the neighbours are fully initialized
# up untill and including level=cell.level
@generated function set_neighbours_of_children!(cell::Tree{D}, state::Function) where D
    quote
        children = cell.children
        Base.Cartesian.@nloops $D i d->1:2 begin
            child = (Base.Cartesian.@nref $D children i)

            Base.Cartesian.@nexprs $D d -> begin
                # Half of the neighbours are siblings
                child.neighbours[d,3-i_d] = (Base.Cartesian.@nref $D children k -> k == d ? 3 - i_d : i_k)

                # The other half aren't
                neighbour_parent = cell.neighbours[d,i_d]
                if initialized(neighbour_parent)
                    if isleaf(neighbour_parent)
                        # Neighbouring parent has no children
                        if cell.level == neighbour_parent.level
                            neighbour = neighbour_parent
                        else
                            # Ensure that different in refined level is at most one between neighbouring cells
                            refine!(neighbour_parent, state)
                            neighbour = cell.neighbours[d,i_d]
                        end
                    else
                        # If neighbouring parent has children, then take neighbouring child
                        neighbour_children = neighbour_parent.children
                        neighbour = (Base.Cartesian.@nref $D neighbour_children k -> k == d ? 3 - i_d : i_k)

                        # Also update the neighbours of the neighbour (only when they are of equal level)
                        neighbour_neighbours = neighbour.neighbours
                        neighbour_neighbours[d,3-i_d] = child
                    end
                    child.neighbours[d,i_d] = neighbour
                end
            end
        end
    end
end

# function set_neighbours_of_children!(cell::Tree, state::Function)
#     for i=1:2, j=1:2
#         # TODO loop over direction
#
#         # Half of the neighbours are siblings
#         cell.children[i,j].neighbours[1,3-i] = cell.children[3-i,j]
#         cell.children[i,j].neighbours[2,3-j] = cell.children[i,3-j]
#
#         # The other half aren't
#         neighbour_parent = cell.neighbours[1,i]
#         if initialized(neighbour_parent)
#             if isleaf(neighbour_parent)
#                 # Neighbouring parent has no children
#                 if cell.level == neighbour_parent.level
#                     neighbour = neighbour_parent
#                 else
#                     # Ensure that different in refined level is at most one between neighbouring cells
#                     refine!(neighbour_parent, state)
#                     neighbour = cell.neighbours[1,i]
#                 end
#             else
#                 # If neighbouring parent has children, then take neighbouring child
#                 neighbour = neighbour_parent.children[3-i,j]
#
#                 # Also update the neighbours of the neighbour (only when they are of equal level)
#                 neighbour_parent.children[3-i,j].neighbours[1,3-i] = cell.children[i,j]
#             end
#             cell.children[i,j].neighbours[1,i] = neighbour
#         end
#
#         neighbour_parent = cell.neighbours[2,j]
#         if initialized(neighbour_parent)
#             if isleaf(neighbour_parent)
#                 # Neighbouring parent has no children
#                 if cell.level == neighbour_parent.level
#                     neighbour = neighbour_parent
#                 else
#                     # Ensure that different in refined level is at most one between neighbouring cells
#                     refine!(neighbour_parent, state)
#                     neighbour = cell.neighbours[2,j]
#                 end
#             else
#                 # If neighbouring parent has children, then take neighbouring child
#                 neighbour = neighbour_parent.children[i,3-j]
#
#                 # Also update the neighbours of the neighbour (only when they are of equal level)
#                 neighbour_parent.children[i,3-j].neighbours[2,3-j] = cell.children[i,j]
#             end
#             cell.children[i,j].neighbours[2,j] = neighbour
#         end
#     end
# end
