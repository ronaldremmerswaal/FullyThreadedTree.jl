abstract type AbstractGrid end
abstract type AbstractFace end

struct Face <: AbstractFace
    cells::Tuple{Tree, Tree}
end

struct Grid <: AbstractGrid
    tree::AbstractTree
    faces::Vector{AbstractFace}
end

@inline faces(grid::Grid) = grid.faces
@inline cells(grid::Grid) = cells(grid.tree)
