
abstract type AbstractQuad end

struct Quad <: AbstractQuad
    parent::AbstractQuad
    level
    position
    neighbours::Array{AbstractQuad, 2}  # index1 = direction (x/y), index2 = side (left/right)
    children::Array{AbstractQuad, 2}    # index1 = x-direction, index2 = y-direction
    state

    Quad() = new()
    Quad(parent, level, position, neighbours, children, state) = new(parent, level, position, neighbours, children, state)
end

@inline isleaf(quad) = !isdefined(quad.children[1], :level)
@inline initialized(quad) = isdefined(quad, :level)
@inline isleafparent(quad) = !isleaf(quad) && isleaf(quad.children[1])

function initialize_quadtree(position, state::Function=x->0.)
    quad = Quad(Quad(), 0, position, fill(Quad(), 2, 2), fill(Quad(), 2, 2), state(position))
    return quad
end

# Refine a single leaf (graded)
function refine!(quad::Quad, state::Function=x->0.; recurse=false, may_not_be_leaf=false)
    if isleaf(quad)

        # Setup leaf children
        initialize_children!(quad, state)

        # Set neighbours of children (may contain a call ro refine! due to graded refinement)
        set_neighbours_of_children!(quad, state)

        # NB the neighbouring neighbours of equal level are updated in set_neighbours_of_children!
    elseif !recurse
        may_not_be_leaf || error("Quad is not a leaf and therefore cannot be refined")
    else
        for child ∈ quad.children
            refine!(child, state, recurse=true)
        end
    end

end

# Refine a list of leaves
function refine!(quads::Vector{Quad}, state::Function=x->0.; recurse=false)

    # Order quads in increasing level
    levels = [quad.level for quad ∈ quads]
    quads = quads[sortperm(levels)]

    for quad ∈ quads
        # NB Due to graded refinement a quad may already be refined
        refine!(quad, state, may_not_be_leaf=true, recurse=recurse)
    end
end

# Coarsen a single leaf (not graded)
function coarsen!(quad::Quad)
    for neighbour ∈ quad.neighbours
        if neighbour.level > quad.level return end
    end

    # Remove children
    quad.children = fill(Quad(), 2, 2)

    # Update neighbour pointers (same level only)
    for dir=1:2, side=1:2
        if quad.neighbours[dir,side].level == quad.level + 1
            quad.neighbours[dir,side].neighbours[dir,3-side] = quad
        end
    end

end

function coarsen!(quads::Vector{Quad})
    # Order quads in decreasing level (to ensure that graded noncoarsening is not an issue)
    levels = [quad.level for quad ∈ quads]
    quads = quads[sortperm(levels, rev=true)]

    for quad ∈ quads
        coarsen!(quad)
    end
end

function initialize_children!(quad, state::Function)
    for i=1:2, j=1:2
        pos = quad.position + (Float64.([i, j]) .- 1.5) / (2 << quad.level)
        quad.children[i,j] = Quad(quad, quad.level + 1, pos, fill(Quad(), 2, 2), fill(Quad(), 2, 2), state(pos))
    end
end

# NB when this function is called, it is assumed that the neighbours are fully initialized
# up untill and including level=quad.level
function set_neighbours_of_children!(quad::Quad, state::Function)
    for i=1:2, j=1:2
        # TODO loop over direction

        # Two neighbours are siblings
        quad.children[i,j].neighbours[1,3-i] = quad.children[3-i,j]
        quad.children[i,j].neighbours[2,3-j] = quad.children[i,3-j]

        # The other two aren't
        neighbour_parent = quad.neighbours[1,i]
        if initialized(neighbour_parent)
            if isleaf(neighbour_parent)
                # Neighbouring parent has no children
                if quad.level == neighbour_parent.level
                    neighbour = neighbour_parent
                else
                    # Ensure that different in refined level is at most one between neighbouring cells
                    refine!(neighbour_parent, state)
                    neighbour = quad.neighbours[1,i]
                end
            else
                # If neighbouring parent has children, then take neighbouring child
                neighbour = neighbour_parent.children[3-i,j]

                # Also update the neighbours of the neighbour (only when they are of equal level)
                neighbour_parent.children[3-i,j].neighbours[1,3-i] = quad.children[i,j]
            end
            quad.children[i,j].neighbours[1,i] = neighbour
        end

        neighbour_parent = quad.neighbours[2,j]
        if initialized(neighbour_parent)
            if isleaf(neighbour_parent)
                # Neighbouring parent has no children
                if quad.level == neighbour_parent.level
                    neighbour = neighbour_parent
                else
                    # Ensure that different in refined level is at most one between neighbouring cells
                    refine!(neighbour_parent, state)
                    neighbour = quad.neighbours[2,j]
                end
            else
                # If neighbouring parent has children, then take neighbouring child
                neighbour = neighbour_parent.children[i,3-j]

                # Also update the neighbours of the neighbour (only when they are of equal level)
                neighbour_parent.children[i,3-j].neighbours[2,3-j] = quad.children[i,j]
            end
            quad.children[i,j].neighbours[2,j] = neighbour
        end
    end
end
