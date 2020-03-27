Base.iterate(tree::Tree) = iterate((tree, x->true, typemax(Int)))

function Base.iterate(tuple::Tuple{Tree, Function, Int}, state = (tuple[1], 0, Vector{Int}()))
    cell, count, indices = state

    if cell == nothing return nothing end
    tree, filter, max_level = tuple

    cell, next_cell = find_next_filtered_cell!(cell, indices, filter, max_level)
    if cell == nothing
        return nothing
    else
        return (cell, (next_cell, count + 1, indices))
    end

end

function find_next_filtered_cell!(cell::Tree{N}, indices::Vector{Int}, filter::Function, max_level::Int) where N
    next_cell = find_next_cell!(cell, indices, max_level)
    while !filter(cell)
        cell = next_cell
        if cell == nothing break end
        next_cell = find_next_cell!(cell, indices, max_level)
    end

    return cell, next_cell
end

# indices[l] yields the child index at level l in the following sense
# cell = cell.parent.children[indices[end]]
#         = cell.parent.parent.children[indices[end-1]].children[end]
#         = ...
function find_next_cell!(cell::Tree{N}, indices::Vector{Int}, max_level::Int) where N
    if !active(cell) && level(cell) < max_level
        # Depth first: go to higher level
        next_cell = cell.children[1]
        push!(indices, 1)
    elseif isempty(indices)
        next_cell = nothing
    else
        # Find sibling or sibling of parent (or grandparent etc.)
        next_cell = cell
        while indices[end] == 1<<N
            next_cell = next_cell.parent
            pop!(indices)
            if isempty(indices) return nothing end
        end
        indices[end] += 1
        next_cell = next_cell.parent.children[indices[end]]
    end

    return next_cell
end

function Base.show(io::IO, tree::Tree)
    compact = get(io, :compact, false)

    print(io, "$(typeof(tree)) ")
    if initialized(tree)
        if level(tree) == 0
            print(io, "root ")
        else
            if active(tree) print(io, "leaf ") end
            print(io, "on level $(level(tree)) ")
        end
        if !active(tree) && !compact
            print(io, "with $(levels(tree)) levels and $(length(active_cells(tree))) active_cells out of $(length(cells(tree))) cells")
        end
    end
end

cells(tree::Tree) = (tree, cell -> true, typemax(Int))
cells(tree::Tree, lvl::Int) = (tree, cell -> level(cell) == lvl, lvl)
active_cells(tree::Tree) = (tree, active, typemax(Int))
active_cells(tree::Tree, lvl::Int) = (tree, cell -> active(cell) && level(cell) == lvl, lvl)
parents_of_active_cell(tree::Tree) = (tree, parent_of_active, typemax(Int))
parents_of_active_cell(tree::Tree, lvl::Int) = (tree, cell -> parent_of_active(cell) && level(cell) == lvl, lvl)

function Base.length(tuple::Tuple{Tree, Function, Int})
    count = 0
    for cell ∈ tuple
        count += 1
    end
    return count
end

# Iterate over the faces, starting at the left-hand side (first dimension) face of some tree
function Base.iterate(tuple::Tuple{Face, Function, Int}, state = (tuple[1], 0, tuple[1].cells[2], Vector{Int}(), [1, 1]))
    face, count, cell, cell_indices, face_indices = state

    if face == nothing return nothing end
    tree, filter, max_level = tuple

    next_face, cell = find_next_face!(face_indices, cell_indices, cell, max_level)
    face_good = filter(face)
    while cell != nothing && !face_good
        face = next_face
        next_face, cell = find_next_face!(face_indices, cell_indices, cell, max_level)
        face_good = filter(face)
    end
    if cell == nothing next_face = nothing end

    if !face_good
        return nothing
    else
        return (face, (next_face, count + 1, cell, cell_indices, face_indices))
    end
end

# Loop over the faces (NB now the filter acts on faces)
# Per cell we loop over the left-hand side faces as well as boundary and refinement faces
function find_next_face!(face_indices::Vector{Int}, cell_indices::Vector{Int}, cell::Tree{N}, max_level::Int) where N
    if face_indices[2] == 1
        # Go to right hand side
        face_indices[2] += 1
        if regular(cell.faces[face_indices[1],face_indices[2]])
            # but only if face is not regular, otherwise go to next dimension
            face_indices[2] = 1
            face_indices[1] += 1
        end
    else
        # Go to next dimension
        face_indices[2] = 1
        face_indices[1] += 1
    end
    if face_indices[1] > N
        cell = find_next_cell!(cell, cell_indices, max_level)
        if cell == nothing return nothing, nothing end
        face_indices .= 1
    end
    return cell.faces[face_indices[1],face_indices[2]], cell
end

faces(tree::Tree) = (tree.faces[1], face -> true, typemax(Int))
faces(tree::Tree, f::Function) = (tree.faces[1], f, typemax(Int))
faces(tree::Tree, lvl::Int) = (tree.faces[1], face -> level(face) == lvl, lvl)
boundary_faces(tree::Tree) = (tree.faces[1], at_boundary, typemax(Int))
boundary_faces(tree::Tree, lvl::Int) = (tree.faces[1], face -> at_boundary(face) && level(face) == lvl, lvl)
refinement_faces(tree::Tree) = (tree.faces[1], at_refinement, typemax(Int))
refinement_faces(tree::Tree, lvl::Int) = (tree.faces[1], face -> at_refinement(face) && level(face) == lvl, lvl)
regular_faces(tree::Tree) = (tree.faces[1], regular, typemax(Int))
regular_faces(tree::Tree, lvl::Int) = (tree.faces[1], face -> regular(face) && level(face) == lvl, lvl)
active_faces(tree::Tree) = (tree.faces[1], active, typemax(Int))
active_faces(tree::Tree, lvl::Int) = (tree.faces[1], face -> active(face) && level(face) == lvl, lvl)
function Base.length(tuple::Tuple{Face, Function, Int})
    count = 0
    for cell ∈ tuple
        count += 1
    end
    return count
end
