function volume(tree::Tree)
    vol = 0.
    for leaf ∈ leaves(tree)
        vol += cell_volume(leaf)
    end
    return vol
end

function first_moment(tree::Tree)
    moment = [0., 0.]
    for leaf ∈ leaves(tree)
        moment += leaf.position .* cell_volume(leaf)
    end
    return moment
end

function integrate(tree::Tree)
    state = zero(tree.state)
    for leaf ∈ leaves(tree)
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

# function polytope(tree::Tree{D}) where T
#     poly = Vector(undef, D)
#     poly[1] = cell.position[1] .+ [-1., 1., 1., -1., -1.] / (2 << (cell.level))
#     poly[2] = cell.position[2] .+ [-1., -1., 1., 1., -1.] / (2 << (cell.level))
# end

@inline cell_volume(cell::Tree{D}) where D = 1. / (1 << (D*cell.level))
