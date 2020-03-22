function iterate(quad::Quad)
    return initialized(quad) ? quad : nothing
end

function iterate(quad::Quad, state)
    parent = state.parent

    # How to find myself? == === is a bad idea since this will recurse indefinitely

end
