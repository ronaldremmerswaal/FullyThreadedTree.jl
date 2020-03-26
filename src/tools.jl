function volume(tree::Tree)
    vol = 0.
    for leaf ∈ active_cells(tree)
        vol += cell_volume(leaf)
    end
    return vol
end

function first_moment(tree::Tree)
    moment = [0., 0.]
    for leaf ∈ active_cells(tree)
        moment += leaf.position .* cell_volume(leaf)
    end
    return moment
end

function integrate(tree::Tree)
    state = zero(tree.state)
    for leaf ∈ active_cells(tree)
        state += leaf.state * cell_volume(leaf)
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

@inline cell_volume(cell::Tree{N}) where N = 1. / (1 << (N*cell.level))
