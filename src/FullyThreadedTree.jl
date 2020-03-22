module FullyThreadedTree

export Quad
export initialize_quadtree, refine!

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


function initialize_quadtree(position, state::Function=x->0.)
    quad = Quad(Quad(), 0, position, fill(Quad(), 2, 2), fill(Quad(), 2, 2), state(position))
    return quad
end

# Refine a single leaf
function refine!(quad::Quad, state::Function=x->0.; recurse=false)
    if !isdefined(quad.children[1], :level)

        # Setup leaf children
        initialize_children!(quad, state)

        # Set their neighbours
        set_neighbours_of_children!(quad)
    elseif !recurse
        error("Quad is not a leaf and therefore cannot be refined")
    else
        for child ∈ quad.children
            refine!(child, state, recurse=true)
        end
    end

end

# Refine a list of leafs, while ensuring graded refinement
function refine!(quads::Vector{Quad}, state::Function=x->0.)

end

function initialize_children!(quad, state::Function)
    for i=1:2, j=1:2
        pos = quad.position + (Float64.([i, j]) .- 1.5) / (2 << quad.level)
        quad.children[i,j] = Quad(quad, quad.level + 1, pos, fill(Quad(), 2, 2), fill(Quad(), 2, 2), state(pos))
    end
end

# NB when this function is called, it is assumed that the neighbours are fully initialized
# up untill and including level=quad.level
function set_neighbours_of_children!(quad::Quad)
    for i=1:2, j=1:2
        # TODO loop over direction

        # Two neighbours are siblings
        quad.children[i,j].neighbours[1,3-i] = quad.children[3-i,j]
        quad.children[i,j].neighbours[2,3-j] = quad.children[i,3-j]

        # The other two aren't
        neighbour_parent = quad.neighbours[1,i]
        if isdefined(neighbour_parent, :level)
            if !isdefined(neighbour_parent.children[3-i,j], :level)
                # Neighbouring parent has no children
                neighbour = neighbour_parent
            else
                # If neighbouring parent has children, then take neighbouring child
                neighbour = neighbour_parent.children[3-i,j]
            end
            quad.children[i,j].neighbours[1,i] = neighbour
        end

        neighbour_parent = quad.neighbours[2,j]
        if isdefined(neighbour_parent, :level)
            if !isdefined(neighbour_parent.children[i,3-j], :level)
                # Neighbouring parent has no children
                neighbour = neighbour_parent
            else
                # If neighbouring parent has children, then take neighbouring child
                neighbour = neighbour_parent.children[i,3-j]
            end
            quad.children[i,j].neighbours[2,j] = neighbour
        end
    end
end


end # module
