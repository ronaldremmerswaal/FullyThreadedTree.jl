struct DummyTree{N} <: AbstractTree{N} end

# A N-dimensional tree
struct Tree{N} <: AbstractTree{N}
    parent::AbstractTree{N}
    level::Int
    position::Vector
    faces::Array{AbstractFace{N}, 2}        # index1 = direction (x/y), index2 = side (left/right), ...
    children::Array{AbstractTree{N}, N}     # index1 = x-direction, index2 = y-direction, ...
    state
end

Tree(parent, level, position, faces, children, state) = Tree{length(position)}(parent, level, position, faces, children, state)
function Tree(position, state::Function=x->0.)
    N = length(position)
    tree = Tree(DummyTree{N}(), 0, position, fill(DummyFace{N,0}(), N, 2), fill(DummyTree{N}(), Tuple(2*ones(Int, N))), state(position))
    for dir=1:N, side=1:2
        tree.faces[dir,side] = Face(tree, DummyTree{N}(), Val(dir), Val(side))
    end
    return tree
end

@inline active(cell::Tree) = !initialized(cell.children[1])
@inline active(cell::AbstractTree) = false
@inline initialized(cell::Tree) = true
@inline initialized(cell::AbstractTree) = false
@inline parent_of_active(cell::Tree) = !active(cell) && active(cell.children[1])
@inline parent_of_active(cell::AbstractTree) = false

@inline other_side(side) = 3 - side
@inline other_side(::Val{N}) where N = 3 - N

# Refine a single leaf (graded)
function refine!(cell::Tree, state::Function=x->0.; recurse=false)
    if active(cell)
        # Setup leaf children
        initialize_children!(cell, state)

        # Set faces of children (may contain a call ro refine! due to graded refinement)
        set_faces_of_children!(cell, state)

        # NB the neighbouring faces of equal level are updated in set_faces_of_children!
    elseif recurse
        for child ∈ cell.children
            refine!(child, state, recurse=true)
        end
    end

end

# Refine a list of active_cells
function refine!(cells::Vector{Tree}, state::Function=x->0.; recurse=false, issorted=false)

    if !issorted
        # Order cells in increasing level
        levels = [cell.level for cell ∈ cells]
        cells = cells[sortperm(levels)]
    end

    for cell ∈ cells
        refine!(cell, state, recurse=recurse)
    end
end

# Coarsen a single leafparent (graded in the sense that if faces are of a higher level then we do not coarsen)
function coarsen!(cell::Tree{N}) where N
    if !parent_of_active(cell) return end
    for neighbour ∈ cell.faces
        # graded noncoarsening
        if initialized(neighbour) && !active(neighbour) return end
    end

    # Remove children
    for (i, child) ∈ enumerate(cell.children)
        cell.children[i] = DummyTree{N}()
    end

    # Update neighbour pointers (same level only)
    for dir=1:N, side=1:2
        if initialized(cell.faces[dir,side]) && cell.faces[dir,side].level == cell.level + 1
            cell.faces[dir,side].faces[dir,other_side(side)] = cell
        end
    end

end

function coarsen!(cells::Vector{Tree}; issorted=false)
    if !issorted
        # Order cells in decreasing level (to ensure that graded noncoarsening is not an issue)
        levels = [cell.level for cell ∈ cells]
        cells = cells[sortperm(levels, rev=true)]
    end

    for cell ∈ cells
        coarsen!(cell)
    end
end

@generated function initialize_children!(cell::Tree{N}, state::Function) where N
    quote
        children = cell.children
        Base.Cartesian.@nloops $N i d->1:2 begin
            pos = cell.position + (Float64.(collect(Base.Cartesian.@ntuple $N i)) .- 1.5) / (2 << cell.level)
            (Base.Cartesian.@nref $N children i) = Tree(cell, cell.level + 1, pos, fill(DummyFace{$N,0}(), $N, 2), fill(DummyTree{$N}(), Tuple(2*ones(Int, $N))), state(pos))
        end
    end
end

# NB this is the N-dimensional variant of
# function initialize_children!(cell::Tree{N}, state::Function) where N
#     for i=1:2, j=1:2
#         pos = cell.position + (Float64.([i, j]) .- 1.5) / (2 << cell.level)
#         cell.children[i,j] = Tree(cell, cell.level + 1, pos, fill(DummyTree{N}(), 2, 2), fill(DummyTree{N}(), 2, 2), state(pos))
#     end
# end

# NB when this function is called, it is assumed that the faces are fully initialized
# up untill and including level=cell.level
@generated function set_faces_of_children!(cell::Tree{N}, state::Function) where N
    quote
        children = cell.children
        Base.Cartesian.@nloops $N i d->1:2 begin
            child = (Base.Cartesian.@nref $N children i)

            Base.Cartesian.@nexprs $N d -> begin
                # Half of the faces are siblings
                child.faces[d,other_side(i_d)] = Face(child, (Base.Cartesian.@nref $N children k -> k == d ? other_side(i_d) : i_k), Val(d), Val(other_side(i_d)))

                # The other half aren't
                if initialized(cell.faces[d,i_d])
                    neighbour_parent = cell.faces[d,i_d].cells[i_d]
                    if initialized(neighbour_parent)
                        if active(neighbour_parent)
                            # Neighbouring parent has no children
                            if cell.level == neighbour_parent.level
                                neighbour = neighbour_parent
                            else
                                # Ensure that difference in refined level is at most one between neighbouring cells
                                refine!(neighbour_parent, state)
                                neighbour = cell.faces[d,i_d].cells[i_d]
                            end
                            face = Face(child, neighbour, Val(d), Val(i_d))
                        else
                            # If neighbouring parent has children, then take neighbouring child
                            neighbour_children = neighbour_parent.children
                            neighbour = (Base.Cartesian.@nref $N neighbour_children k -> k == d ? other_side(i_d) : i_k)

                            face = Face(neighbour, child, Val(d), Val(other_side(i_d)))

                            # Also update the faces of the neighbour (only when they are of equal level)
                            neighbour_faces = neighbour.faces
                            neighbour_faces[d,other_side(i_d)] = face
                        end
                        child.faces[d,i_d] = face
                    end
                end
            end
        end
    end
end

# function set_faces_of_children!(cell::Tree, state::Function)
#     for i=1:2, j=1:2
#         # TODO loop over direction
#
#         # Half of the faces are siblings
#         cell.children[i,j].faces[1,3-i] = cell.children[3-i,j]
#         cell.children[i,j].faces[2,3-j] = cell.children[i,3-j]
#
#         # The other half aren't
#         neighbour_parent = cell.faces[1,i]
#         if initialized(neighbour_parent)
#             if active(neighbour_parent)
#                 # Neighbouring parent has no children
#                 if cell.level == neighbour_parent.level
#                     neighbour = neighbour_parent
#                 else
#                     # Ensure that different in refined level is at most one between neighbouring cells
#                     refine!(neighbour_parent, state)
#                     neighbour = cell.faces[1,i]
#                 end
#             else
#                 # If neighbouring parent has children, then take neighbouring child
#                 neighbour = neighbour_parent.children[3-i,j]
#
#                 # Also update the faces of the neighbour (only when they are of equal level)
#                 neighbour_parent.children[3-i,j].faces[1,3-i] = cell.children[i,j]
#             end
#             cell.children[i,j].faces[1,i] = neighbour
#         end
#
#         neighbour_parent = cell.faces[2,j]
#         if initialized(neighbour_parent)
#             if active(neighbour_parent)
#                 # Neighbouring parent has no children
#                 if cell.level == neighbour_parent.level
#                     neighbour = neighbour_parent
#                 else
#                     # Ensure that different in refined level is at most one between neighbouring cells
#                     refine!(neighbour_parent, state)
#                     neighbour = cell.faces[2,j]
#                 end
#             else
#                 # If neighbouring parent has children, then take neighbouring child
#                 neighbour = neighbour_parent.children[i,3-j]
#
#                 # Also update the faces of the neighbour (only when they are of equal level)
#                 neighbour_parent.children[i,3-j].faces[2,3-j] = cell.children[i,j]
#             end
#             cell.children[i,j].faces[2,j] = neighbour
#         end
#     end
# end
