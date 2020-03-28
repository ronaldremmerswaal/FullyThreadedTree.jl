struct DummyTree{N} <: AbstractTree{N} end

mutable struct BoundaryTree{N} <: AbstractTree{N}
    level::Int
    position::Vector
    face::Face{N}
    state
end

# A N-dimensional tree
mutable struct Tree{N} <: AbstractTree{N}
    parent::Tree{N}
    level::Int
    position::Vector
    faces::Array{Face{N}, 2}            # index1 = direction (x/y), index2 = side (left/right), ...
    children::Array{Tree{N}}            # index1 = x-direction, index2 = y-direction, ...
    state

    Tree{N}() where N = new()
    Tree{N}(parent, level, position, faces, children, state) where N = new(parent, level, position, faces, children, state)
end

Tree(parent, level, position, faces, children, state) = Tree{length(position)}(parent, level, position, faces, children, state)
function Tree(position; cell_state::Function = x->nothing, face_state = nothing, periodic::Vector{Bool} = fill(false, length(position)))
    N = length(position)
    tree = Tree(Tree{N}(), 0, position, fill(Face{N}(), N, 2), Vector{Tree{N}}(), cell_state(position))
    for dir=1:N, side=1:2
        neigh = periodic[dir] ? tree : DummyTree{N}()
        tree.faces[dir,side] = periodic[dir] && side == 2 ? tree.faces[dir,other_side(side)] : Face(tree, neigh, dir, side, face_state)
    end
    return tree
end


@inline faces(cell::Tree) = cell.faces
@inline faces(cell::AbstractTree{N}) where N = fill(Tree{N}(), 0, 0)

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
function refine!(cell::Tree{N}; cell_state::Function = x -> nothing, face_state = nothing, recurse = false) where N
    if active(cell)
        # Setup leaf children
        children = initialize_children(cell, cell_state)

        # Set faces of children (may contain a call ro refine! due to graded refinement)
        initialize_faces_of_children!(children, cell, cell_state, face_state)
        cell.children = children

        # NB the neighbouring faces of equal level are updated in initialize_faces_of_children!
    elseif recurse
        for child ∈ cell.children
            refine!(child, cell_state = cell_state, face_state = face_state, recurse = true)
        end
    end
    return nothing
end

# refine!(cells::Array{Tree, N} where N; state::Function = x -> nothing, recurse = false, issorted = false) = refine!(reshape(cells, length(cells)), state = state, recurse = recurse, issorted = issorted)

# Refine a list of active_cells
function refine!(cells::Vector{Tree{N}}; cell_state::Function = x -> nothing, face_state = nothing, recurse = false, issorted = false) where N

    if !issorted
        # Order cells in increasing level
        sort!(cells, by=level)
    end

    for cell ∈ cells
        refine!(cell, cell_state = cell_state, face_state = face_state, recurse = recurse)
    end
end

@generated function initialize_children(parent::Tree{N}, state::Function) where N
    quote
        children = fill(Tree{N}(), Tuple(2*ones(Int, N)))
        @nloops $N i d->1:2 @inbounds begin
            pos = copy(parent.position)
            @nexprs $N d -> begin
                pos[d] += (Float64(i_d) .- 1.5) / (2 << level(parent))
            end
            (@nref $N children i) = Tree(parent, level(parent) + 1, pos, fill(Face{$N}(), $N, 2), Vector{Tree{N}}(), state(pos))
        end
        return children
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
@generated function initialize_faces_of_children!(children::Array{Tree{N}, N}, parent::Tree{N}, cell_state::Function, face_state) where N
    quote
        @nloops $N i d->1:2 @inbounds begin
            child = (@nref $N children i)

            @nexprs $N d -> begin
                # Half of the faces are between siblings
                if i_d == 2
                    other_child = (@nref $N children k -> k == d ? other_side(i_d) : i_k)
                    child.faces[d,other_side(i_d)] = other_child.faces[d,i_d]
                else
                    child.faces[d,other_side(i_d)] = Face(child, (@nref $N children k -> k == d ? other_side(i_d) : i_k), d, other_side(i_d), face_state)
                end

                # The other half aren't
                neighbour_parent = parent.faces[d,i_d].cells[i_d]
                if !initialized(neighbour_parent)
                    # Neighbour lies outside of domain (at_boundary)
                    face = Face(child, DummyTree{$N}(), d, i_d, face_state)
                else
                    if active(neighbour_parent)
                        if level(parent) == 0
                            # Periodic (neighbour_parent == parent); so all faces are between siblings
                            if i_d == 2
                                other_child = (@nref $N children k -> k == d ? other_side(i_d) : i_k)
                                face = other_child.faces[d,other_side(i_d)]
                            else
                                face = Face(child, (@nref $N children k -> k == d ? other_side(i_d) : i_k), d, i_d, face_state)
                            end
                        else
                            # Neighbouring parent has no children (at_refinement)
                            if level(parent) == level(neighbour_parent)
                                neighbour = neighbour_parent
                            else
                                # Ensure that difference in refined level is at most one between neighbouring cells
                                refine!(neighbour_parent, cell_state = cell_state, face_state = face_state)
                                neighbour = parent.faces[d,i_d].cells[i_d]
                            end
                            face = Face(child, neighbour, d, i_d, face_state)
                        end
                    else
                        # If neighbouring parent has children, then take neighbouring child (regular)
                        neighbour_children = neighbour_parent.children
                        neighbour = (@nref $N neighbour_children k -> k == d ? other_side(i_d) : i_k)

                        # face = Face(neighbour, child, d, other_side(i_d), face_state)
                        if i_d == 1
                            face = Face{N}((neighbour, child), d, neighbour.faces[d,other_side(i_d)].state)
                        else
                            face = Face{N}((child, neighbour), d, neighbour.faces[d,other_side(i_d)].state)
                        end

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
function coarsen!(cell::Tree{N}; face_state = nothing) where N
    if !parent_of_active(cell) return end
    for dir=1:N, side=1:2
        neighbour = cell.faces[dir,side]

        # graded noncoarsening
        if !at_boundary(neighbour) && !active(neighbour.cells[side])
            return Vector{Tree{N}}(), Vector{Face{N}}()
        end
    end

    # Update any face which pointed to the children which are to be removed
    update_faces_of_neighbouring_children!(cell.children, cell, face_state)

    # Remove children
    cell.children = Vector{Tree{N}}()
end

function coarsen!(cells::Vector{Tree{N}}; face_state = nothing, issorted = false) where N
    if !issorted
        # Order cells in decreasing level (to ensure that graded noncoarsening is not an issue)
        sort!(cells, by=level, rev=true)
    end

    for cell ∈ cells
        coarsen!(cell, face_state = face_state)
    end
end

# Child is either at higher level than neighbour or at same
@generated function update_faces_of_neighbouring_children!(children::Array{Tree{N}, N}, parent::Tree{N}, face_state) where N
    quote
        @nloops $N i d->1:2 @inbounds begin
            child = (@nref $N children i)

            @nexprs $N d -> begin
                # Half of the faces are siblings; these faces are simply removed when the children are removed

                # The other half may refer to child
                neighbour = child.faces[d,i_d].cells[i_d]
                if level(child) == level(neighbour)         # !at_refinement
                    # After child is removed, the neighbour of neighbour will be the parent
                    neighbour.faces[d,other_side(i_d)] = Face(neighbour, parent, d, other_side(i_d), face_state)
                end
            end
        end
    end
end
