# N-dimensional face with normal in the positive D direction
struct DummyFace{N,D} <: AbstractFace{N,D} end

struct Face{N,D,S} <: AbstractFace{N,D} where S
    cells::Tuple{AbstractTree{N},AbstractTree{N}}
end
# Initialize a face, here Val indicates the side (1 or 2) relative to cell of this face
Face{N,D,2}(cell::AbstractTree{N}, other_cell::AbstractTree{N}) where {N,D} = Face{N,D,1}((cell, other_cell))
Face{N,D,1}(cell::AbstractTree{N}, other_cell::AbstractTree{N}) where {N,D} = Face{N,D,2}((other_cell, cell))

@inline at_boundary(face::Face) = (initialized(face.cells[1]) && !initialized(face.cells[2])) || (initialized(face.cells[2]) && !initialized(face.cells[1]))
@inline at_boundary(face::AbstractFace) = false
@inline at_refinement(face::Face) = initialized(face.cells[1]) && initialized(face.cells[2]) && face.cells[1].level != face.cells[2].level
@inline at_refinement(face::AbstractFace) = false
@inline regular(face::Face) = initialized(face.cells[1]) && initialized(face.cells[2]) && face.cells[1].level == face.cells[2].level
@inline regular(face::AbstractFace) = false

@inline active(face::Face) = (active(face.cells[1]) && active(face.cells[2])) || (at_boundary(face) && (active(face.cells[1]) || active(face.cells[2])))
@inline active(face::AbstractFace) = false

@inline initialized(face::AbstractFace) = false
@inline initialized(face::Face) = true

@inline level(face::Face) = regular(face) ? max(face.cells[1].level, face.cells[2].level) : (initialized(face.cells[1]) ? face.cells[1].level : face.cells[2].level)
