using FullyThreadedTree
using BenchmarkTools

function sumvol(tree::Tree)
    val = 0.0
    for cell ∈ cells(tree, filter = active)
        val += volume(cell)
    end
    val
end
function sumvol(vec::Vector{Tree{N}}) where N
    val = 0.0
    for cell ∈ filter(active, vec)
        val += volume(cell)
    end
    val
end
function sumvol_faces(tree::Tree)
    val = 0.0
    for face ∈ all_faces(tree, filter = active)
        val += cell_volume(face)
    end
    val
end
function sumvol_faces(vec::Vector{Face{N}}) where N
    val = 0.0
    for face ∈ filter(active, vec)
        val += cell_volume(face)
    end
    val
end

function compare_performance(dim, nr_steps)
    tree = Tree(zeros(dim))
    child = tree
    for step ∈ 1:nr_steps
        refine!(child)
        child = child.children[mod(step, 1<<dim) + 1]
    end

    println("Collecting cells")
    display(@benchmark collect_cells($tree))

    println("\nCollecting faces")
    display(@benchmark collect_faces($tree))

    cells = collect_cells(tree)
    faces = collect_faces(tree)

    println("\nCells using a vector of Trees")
    display(@benchmark sumvol($cells))

    println("\nFaces using a vector of Faces")
    display(@benchmark sumvol_faces($faces))

    println("\nCells using the Tree data structure")
    display(@benchmark sumvol($tree))

    println("\nFaces using the Tree data structure")
    display(@benchmark sumvol_faces($tree))

    return tree
end
