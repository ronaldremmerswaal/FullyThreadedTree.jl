struct DummyTree{N} <: AbstractTree{N} end

# A N-dimensional tree
mutable struct Tree{N} <: AbstractTree{N}
    parent::Tree{N}
    level::Int
    position::Vector
    faces::Array{Face{N}, 2}            # index1 = direction (x/y), index2 = side (left/right), ...
    children::Array{Tree{N}, N}         # index1 = x-direction, index2 = y-direction, ...
    state

    Tree{N}() where N = new()
    Tree{N}(parent, level, position, faces, children, state) where N = new(parent, level, position, faces, children, state)
end

Tree(parent, level, position, faces, children, state) = Tree{length(position)}(parent, level, position, faces, children, state)
function Tree(position; state::Function=x->nothing, periodic::Vector{Bool} = fill(false, length(position)))
    N = length(position)
    tree = Tree(Tree{N}(), 0, position, fill(Face{N}(), N, 2), fill(Tree{N}(), Tuple(zeros(Int, N))), state(position))
    for dir=1:N, side=1:2
        neigh = periodic[dir] ? tree : DummyTree{N}()
        tree.faces[dir,side] = Face(tree, neigh, dir, side)
    end
    return tree
end

# @inline level(cell::Tree{N, L}) where {N, L} = L
@inline level(cell::Tree) = cell.level
@inline level(cell::AbstractTree) = -1

@inline active(cell::Tree) = isempty(cell.children)
@inline active(cell::AbstractTree) = false
@inline initialized(cell::Tree) = true
@inline initialized(cell::AbstractTree) = false
@inline parent_of_active(cell::Tree) = !active(cell) && active(cell.children[1])
@inline parent_of_active(cell::AbstractTree) = false

@inline other_side(side) = 3 - side


# Refine a single leaf (graded)
function refine!(cell::Tree{N}; state::Function = x -> nothing, recurse = false) where N
    if active(cell)
        # Setup leaf children
        children = fill(Tree{N}(), Tuple(2*ones(Int, N)))
        initialize_children!(children, cell, state)

        # Set faces of children (may contain a call ro refine! due to graded refinement)
        initialize_faces_of_children!(children, cell, state)
        cell.children = children

        # NB the neighbouring faces of equal level are updated in initialize_faces_of_children!
    elseif recurse
        for child ∈ cell.children
            refine!(child, state = state, recurse = true)
        end
    end
    return nothing
end

# Refine a list of active_cells
function refine!(cells::Vector{Tree}; state::Function = x -> nothing, recurse = false, issorted = false)

    if !issorted
        # Order cells in increasing level
        levels = [level(cell) for cell ∈ cells]
        cells = cells[sortperm(levels)]
    end

    for cell ∈ cells
        refine!(cell, state = state, recurse = recurse)
    end
end

@generated function initialize_children!(children::Array{Tree{N}, N}, parent::Tree{N}, state::Function) where N
    dimensions = Tuple(zeros(Int, N))
    quote
        @nloops $N i d->1:2 @inbounds begin
            pos = copy(parent.position)
            @nexprs $N d -> begin
                pos[d] += (Float64(i_d) .- 1.5) / (2 << level(parent))
            end
            (@nref $N children i) = Tree(parent, level(parent) + 1, pos, fill(Face{$N}(), $N, 2), fill(DummyTree{N}(), $dimensions), state(pos))
        end
    end
end

# NB this is the N-dimensional variant of
# function initialize_children!(children::Array{AbstractTree{2}, 2}, parent::Tree{2}, state::Function)
#     for i=1:2, j=1:2
#         pos = parent.position + (Float64.([i, j]) .- 1.5) / (2 << level(parent))
#         parent.children[i,j] = Tree(parent, level(parent) + 1, pos, fill(Face{2}(), 2, 2), fill(DummyTree{2}(), 2, 2), state(pos))
#     end
# end

# NB when this function is called, it is assumed that the faces are fully initialized
# up untill and including level=level(cell)
@generated function initialize_faces_of_children!(children::Array{Tree{N}, N}, parent::Tree{N}, state::Function) where N
    quote
        @nloops $N i d->1:2 @inbounds begin
            child = (@nref $N children i)

            @nexprs $N d -> begin
                # Half of the faces are siblings
                if i_d == 2
                    other_child = (@nref $N children k -> k == d ? other_side(i_d) : i_k)
                    child.faces[d,other_side(i_d)] = other_child.faces[d,i_d]
                else
                    child.faces[d,other_side(i_d)] = Face(child, (@nref $N children k -> k == d ? other_side(i_d) : i_k), d, other_side(i_d))
                end

                # The other half aren't
                neighbour_parent = parent.faces[d,i_d].cells[i_d]
                if !initialized(neighbour_parent)
                    # Neighbour lies outside of domain (at_boundary)
                    face = Face(child, DummyTree{$N}(), d, i_d)
                else
                    if active(neighbour_parent)
                        # Neighbouring parent has no children (at_refinement)
                        if level(parent) == level(neighbour_parent)
                            neighbour = neighbour_parent
                        else
                            # Ensure that difference in refined level is at most one between neighbouring cells
                            refine!(neighbour_parent, state = state)
                            neighbour = parent.faces[d,i_d].cells[i_d]
                        end
                        face = Face(child, neighbour, d, i_d)
                    else
                        # If neighbouring parent has children, then take neighbouring child (regular)
                        neighbour_children = neighbour_parent.children
                        neighbour = (@nref $N neighbour_children k -> k == d ? other_side(i_d) : i_k)

                        face = Face(neighbour, child, d, other_side(i_d))

                        # Also update the faces of the neighbour (only when they are of equal level)
                        neighbour.faces[d,other_side(i_d)] = face
                    end
                end
                child.faces[d,i_d] = face
            end
        end
    end
end

# Coarsen a single leafparent (graded in the sense that if faces are of a higher level then we do not coarsen)
function coarsen!(cell::Tree{N}; state::Function = x -> nothing) where N
    if !parent_of_active(cell) return end
    for neighbour ∈ cell.faces
        # graded noncoarsening
        if initialized(neighbour) && level(neighbour) > level(cell) return end
    end

    # Update any face which pointed to the children which are to be removed
    update_faces_of_neighbouring_children!(cell.children, cell, state)

    # Remove children
    cell.children = fill(Tree{N}(), Tuple(zeros(Int, N)))
    return nothing
end

function coarsen!(cells::Vector{Tree}; state::Function = x -> nothing, issorted = false)
    if !issorted
        # Order cells in decreasing level (to ensure that graded noncoarsening is not an issue)
        levels = [level(cell) for cell ∈ cells]
        cells = cells[sortperm(levels, rev=true)]
    end

    for cell ∈ cells
        coarsen!(cell, state = state)
    end
end

@generated function update_faces_of_neighbouring_children!(children::Array{Tree{N}, N}, parent::Tree{N}, state::Function) where N
    quote
        @nloops $N i d->1:2 @inbounds begin
            child = (@nref $N children i)

            @nexprs $N d -> begin
                # Half of the faces are siblings; these faces are simply removed when the children are removed

                # The other half may refer to child
                neighbour = child.faces[d,i_d].cells[i_d]
                if level(child) == level(neighbour)
                    # After child is removed, the neighbour of neighbour will be the parent
                    neighbour.faces[d,other_side(i_d)] = Face(neighbour, parent, d, other_side(i_d))
                end
            end
        end
    end
end
