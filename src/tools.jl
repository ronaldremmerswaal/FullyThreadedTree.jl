function integrate(tree::Tree)
    state = zero(tree.state)
    for leaf ∈ cells(tree, filter=active)
        state += leaf.state * volume(leaf)
    end
    return state
end

function levels(tree::Tree)
    lvl = 0
    for cell ∈ cells(tree)
        lvl = max(lvl, level(cell))
    end
    return 1 + lvl
end

# function polytope(tree::Tree{N}) where T
#     poly = Vector(undef, N)
#     poly[1] = cell.position[1] .+ [-1., 1., 1., -1., -1.] / (2 << (level(cell)))
#     poly[2] = cell.position[2] .+ [-1., -1., 1., 1., -1.] / (2 << (level(cell)))
# end

@inline volume(cell::Tree{N}) where N = 1. / (1 << (N*level(cell)))
@inline centroid(cell::Tree) = cell.position


@inline area(face::Face{N}) where N = 1. / (1 << ((N-1)*level(face)))
function centroid(face::Face{N}) where N
    if initialized(face.cells[1]) && initialized(face.cells[2])
        idx = level(face.cells[1]) > level(face.cells[2]) ? 1 : 2
    else
        idx = initialized(face.cells[1]) ? 1 : 2
    end

    position = copy(face.cells[idx].position)
    if idx == 1
        position[direction(face)] += 1. / (2<<level(face.cells[idx]))
    else
        position[direction(face)] -= 1. / (2<<level(face.cells[idx]))
    end
    return position
end

function cell_distance(face::Face)
    dist = 0.0
    if initialized(face.cells[1])
        dist += 1. / (2<<level(face.cells[1]))
    end
    if initialized(face.cells[2])
        dist += 1. / (2<<level(face.cells[2]))
    end
    return dist
end

@inline volume(face::Face) = cell_distance(face) * area(face)
