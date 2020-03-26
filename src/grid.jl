abstract type AbstractGrid end
abstract type AbstractFace end

struct Face <: AbstractFace
    cells::Tuple{Tree, Tree}
end

struct Grid <: AbstractGrid
    tree::Tree
    faces::Vector{Face}

    nr_leaves

    Grid(tree, faces) = new(tree, faces, nr_leaves(tree))
end

@inline nr_leaves(grid::Grid) = grid.nr_leaves
@inline nr_faces(grid::Grid) = length(grid.faces)
@inline faces(grid::Grid) = grid.faces
@inline cells(grid::Grid) = grid.tree
