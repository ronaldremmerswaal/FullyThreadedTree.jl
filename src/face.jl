# N-dimensional face with normal in the positive D direction
struct Face{N} <: AbstractFace{N}
    cells::Tuple{AbstractTree{N},AbstractTree{N}}
    face_direction::Int
    state

    Face{N}() where N = new()
    Face{N}(cells, face_direction, state) where N = new(cells, face_direction, state)
end

function cells(face::Face; with_fine_siblings = true)
    if !with_fine_siblings || !at_refinement(face)
        return face.cells
    else
        # TODO return iterator
        if level(face) == level(face.cells[2])
            return cat(face.cells[1], siblings(face.cells[2], face.face_direction, 1), dims=1)
        else
            return cat(siblings(face.cells[1], face.face_direction, 2), face.cells[2], dims=1)
        end
    end
end

# Initialize a face, here Val indicates the side (1 or 2) relative to cell of this face
function Face(cell::AbstractTree{N}, other_cell::AbstractTree{N}, face_direction, side, state::Function) where N
    side == 1 ? Face{N}((other_cell, cell), face_direction, state(centroid((other_cell, cell), face_direction))) : Face{N}((cell, other_cell), face_direction, state(centroid((cell, other_cell), face_direction)))
end
function Face(cell::AbstractTree{N}, other_cell::AbstractTree{N}, face_direction, side, state::Nothing) where N
    side == 1 ? Face{N}((other_cell, cell), face_direction, state) : Face{N}((cell, other_cell), face_direction, state)
end

@inline at_boundary(face::Face) = !initialized(face.cells[1]) || !initialized(face.cells[2])
@inline at_boundary(face::AbstractFace) = false
@inline at_refinement(face::Face) = initialized(face.cells[1]) && initialized(face.cells[2]) && level(face.cells[1]) != level(face.cells[2])
@inline at_refinement(face::AbstractFace) = false
@inline regular(face::Face) = level(face.cells[1]) == level(face.cells[2])
@inline regular(face::AbstractFace) = false

@inline active(face::Face) = (active(face.cells[1]) && active(face.cells[2]))# || (at_boundary(face) && (active(face.cells[1]) || active(face.cells[2])))
@inline active(face::AbstractFace) = false

@inline initialized(face::AbstractFace) = false
@inline initialized(face::Face) = true

@inline level(face::Face) = max(level(face.cells[1]), level(face.cells[2]))
@inline direction(face::Face) = face.face_direction

function collect_faces(tree::AbstractTree{N}; filter::Function = face -> true) where N
    faces = Vector{Face{N}}()
    collect_faces!(faces, tree, filter)
    return faces
end

function collect_faces!(faces::Vector{Face{N}}, tree::AbstractTree{N}, filter::Function) where N
    @inbounds for dir=1:N, side=1:2
        face = tree.faces[dir, side]
        if (side==1 || !regular(face)) && filter(face)
            push!(faces, face)
        end
    end
    if isempty(tree.children)
        return
    else
        for child ∈ tree.children
            collect_faces!(faces, child, filter)
        end
    end
end
