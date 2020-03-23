function volume(tree::Quad)
    vol = 0.
    for quad ∈ tree
        if isleaf(quad)
            vol += quad_volume(quad)
        end
    end
    return vol
end

function first_moment(tree::Quad)
    moment = [0., 0.]
    for quad ∈ tree
        if isleaf(quad)
            moment += quad.position .* quad_volume(quad)
        end
    end
    return moment
end

function integrate(tree::Quad)
    state = zero(tree.state)
    for quad ∈ tree
        if isleaf(quad)
            state += quad.state * quad_volume(quad)
        end
    end
    return state
end

function nr_leaves(tree::Quad)
    nr = 0
    for quad ∈ tree
        if isleaf(quad)
            nr += 1
        end
    end
    return nr
end

function nr_quads(tree::Quad)
    nr = 0
    for quad ∈ tree
        nr += 1
    end
    return nr
end

@inline quad_volume(quad::Quad) = 1. / (1 << (2*quad.level))
