function integrate(tree::Tree)
    state = zero(tree.state)
    for leaf ∈ cells(tree, filter=active)
        state += leaf.state * volume(leaf)
    end
    return state
end

# function polytope(tree::Tree{N}) where T
#     poly = Vector(undef, N)
#     poly[1] = cell.position[1] .+ [-1., 1., 1., -1., -1.] / (2 << (level(cell)))
#     poly[2] = cell.position[2] .+ [-1., -1., 1., 1., -1.] / (2 << (level(cell)))
# end

@inline volume(cell::Tree{N}) where N = 1. / (1 << (N*level(cell)))
@inline centroid(cell::Tree) = cell.position

@inline area(face::Face{N}) where N = 1. / (1 << ((N-1)*level(face)))
function face_area(cell::Tree{N}, face::Face{N}) where N
    if !at_refinement(face) || level(cell) != level(face)
        return area(face)
    else
        return area(face) / 1 << (N-1)
    end
end

function centroid(cells::Tuple{AbstractTree{N}, AbstractTree{N}}, direction) where N
    if initialized(cells[1]) && initialized(cells[2])
        idx = level(cells[1]) > level(cells[2]) ? 1 : 2
    else
        idx = initialized(cells[1]) ? 1 : 2
    end

    position = copy(cells[idx].position)
    if idx == 1
        position[direction] += 1. / (2<<level(cells[idx]))
    else
        position[direction] -= 1. / (2<<level(cells[idx]))
    end
    return position
end
@inline centroid(face::Face) = centroid(face.cells, face.face_direction)

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

function cell_volume(face::Face{N}) where N
    if !at_refinement(face)
        return volume(face.cells[1])
    else
        return 1.5 / (1 << (N*level(face)))
    end
end
