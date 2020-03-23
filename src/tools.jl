function volume(tree::Tree)
    vol = 0.
    for cell ∈ tree
        if isleaf(cell)
            vol += cell_volume(cell)
        end
    end
    return vol
end

function first_moment(tree::Tree)
    moment = [0., 0.]
    for cell ∈ tree
        if isleaf(cell)
            moment += cell.position .* cell_volume(cell)
        end
    end
    return moment
end

function integrate(tree::Tree)
    state = zero(tree.state)
    for cell ∈ tree
        if isleaf(cell)
            state += cell.state * cell_volume(cell)
        end
    end
    return state
end

function nr_leaves(tree::Tree)
    nr = 0
    for cell ∈ tree
        if isleaf(cell)
            nr += 1
        end
    end
    return nr
end

function nr_cells(tree::Tree)
    nr = 0
    for cell ∈ tree
        nr += 1
    end
    return nr
end

function max_level(tree::Tree)
    level = 0
    for cell ∈ tree
        level = max(level, cell.level)
    end
    return level
end

@inline cell_volume(cell::Tree) = 1. / (1 << (2*cell.level))
