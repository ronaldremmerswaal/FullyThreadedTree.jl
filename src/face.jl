# N-dimensional face with normal in the positive D direction
struct DummyFace{N,D} <: AbstractFace{N,D} end

struct Face{N,D} <: AbstractFace{N,D}
    cells::Tuple{AbstractTree{N},AbstractTree{N}}
    state
end
cells(face::Face) = face.cells

# Initialize a face, here Val indicates the side (1 or 2) relative to cell of this face
function Face{N,D}(cell::AbstractTree{N}, other_cell::AbstractTree{N}, side; state = nothing) where {N,D}
    side == 1 ? Face{N,D}((other_cell, cell), state) : Face{N,D}((cell, other_cell), state)
end

@inline at_boundary(face::Face) = (initialized(face.cells[1]) && !initialized(face.cells[2])) || (initialized(face.cells[2]) && !initialized(face.cells[1]))
@inline at_boundary(face::AbstractFace) = false
@inline at_refinement(face::Face) = initialized(face.cells[1]) && initialized(face.cells[2]) && level(face.cells[1]) != level(face.cells[2])
@inline at_refinement(face::AbstractFace) = false
@inline regular(face::Face) = initialized(face.cells[1]) && initialized(face.cells[2]) && level(face.cells[1]) == level(face.cells[2])
@inline regular(face::AbstractFace) = false

@inline active(face::Face) = (active(face.cells[1]) && active(face.cells[2])) || (at_boundary(face) && (active(face.cells[1]) || active(face.cells[2])))
@inline active(face::AbstractFace) = false

@inline initialized(face::AbstractFace) = false
@inline initialized(face::Face) = true

@inline level(face::Face) = (initialized(face.cells[1]) && initialized(face.cells[2])) ? max(level(face.cells[1]), level(face.cells[2])) : (initialized(face.cells[1]) ? level(face.cells[1]) : level(face.cells[2]))
