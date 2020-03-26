function integrate(tree::Tree)
    state = zero(tree.state)
    for leaf ∈ active_cells(tree)
        state += leaf.state * volume(leaf)
    end
    return state
end

function levels(tree::Tree)
    level = 0
    for cell ∈ cells(tree)
        level = max(level, cell.level)
    end
    return 1 + level
end

# function polytope(tree::Tree{N}) where T
#     poly = Vector(undef, N)
#     poly[1] = cell.position[1] .+ [-1., 1., 1., -1., -1.] / (2 << (cell.level))
#     poly[2] = cell.position[2] .+ [-1., -1., 1., 1., -1.] / (2 << (cell.level))
# end

@inline volume(cell::Tree{N}) where N = 1. / (1 << (N*cell.level))
@inline centroid(cell::Tree) = cell.position


@inline area(face::Face{N}) where N = 1. / (1 << ((N-1)*level(face)))
function centroid(face::Face{N,D}) where {N,D}
    if initialized(face.cells[1]) && initialized(face.cells[2])
        idx = face.cells[1].level > face.cells[2].level ? 1 : 2
    else
        idx = initialized(face.cells[1]) ? 1 : 2
    end
    
    position = copy(face.cells[idx].position)
    if idx == 1
        position[D] += 1. / (2<<face.cells[idx].level)
    else
        position[D] -= 1. / (2<<face.cells[idx].level)
    end
    return position
end

function cell_distance(face::Face)
    dist = 0.0
    if initialized(face.cells[1])
        dist += 1. / (2<<face.cells[1].level)
    end
    if initialized(face.cells[2])
        dist += 1. / (2<<face.cells[2].level)
    end
    return dist
end

@inline volume(face::Face) = cell_distance(face) * area(face)
