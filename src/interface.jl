function Base.iterate(quad::Quad, state=initialized(quad) ? (quad, 0, Vector{Int}())  : nothing)
    element, count, indices = state

    if element == nothing return nothing end

    if isleaf(element)
        indices[end] += 1
        if indices[end] < 5
            next_element = element.parent.children[indices[end]]
        end
    else
        next_element = element.children[1]
        push!(indices, 1)
    end

    if indices[end] >= 5
        next_element = element
        while indices[end] >= 5
            next_element = next_element.parent
            pop!(indices)
            if isempty(indices)
                next_element = nothing
                break
            end
            indices[end] += 1
            if indices[end] < 5
                next_element = next_element.parent.children[indices[end]]
            end
        end
    end
    return (element, (next_element, count + 1, indices))
end
