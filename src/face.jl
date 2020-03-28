# N-dimensional face with normal in the positive D direction
struct Face{N} <: AbstractFace{N}
    cells::Tuple{AbstractTree{N},AbstractTree{N}}
    face_direction::Int
    state

    Face{N}() where N = new()
    Face{N}(cells, face_direction, state) where N = new(cells, face_direction, state)
end
cells(face::Face) = face.cells

# Initialize a face, here Val indicates the side (1 or 2) relative to cell of this face
function Face(cell::AbstractTree{N}, other_cell::AbstractTree{N}, face_direction, side; state = nothing) where N
    side == 1 ? Face{N}((other_cell, cell), face_direction, state) : Face{N}((cell, other_cell), face_direction, state)
end

@inline at_boundary(face::Face) = !initialized(face.cells[1]) || !initialized(face.cells[2])
@inline at_boundary(face::AbstractFace) = false
@inline at_refinement(face::Face) = initialized(face.cells[1]) && initialized(face.cells[2]) && level(face.cells[1]) != level(face.cells[2])
@inline at_refinement(face::AbstractFace) = false
@inline regular(face::Face) = level(face.cells[1]) == level(face.cells[2])
@inline regular(face::AbstractFace) = false

@inline active(face::Face) = (active(face.cells[1]) && active(face.cells[2])) || (at_boundary(face) && (active(face.cells[1]) || active(face.cells[2])))
@inline active(face::AbstractFace) = false

@inline initialized(face::AbstractFace) = false
@inline initialized(face::Face) = true

@inline level(face::Face) = max(level(face.cells[1]), level(face.cells[2]))
@inline direction(face::Face) = face.face_direction
