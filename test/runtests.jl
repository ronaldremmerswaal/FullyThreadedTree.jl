using FullyThreadedTree
using Test

@testset "FullyThreadedTree.jl" begin
    # Verify that the cell_volume corresponding to all the cells cover the
    # domain exactly once
    function total_volume_via_cells(tree)
        vol = 0.0
        for cell ∈ cells(tree, filter = active)
            vol += volume(cell)
        end
        return vol
    end

    function total_firstMoment_via_cells(tree::Tree{N}) where N
        moment = zeros(N)
        for cell ∈ cells(tree, filter = active)
            moment += centroid(cell) * volume(cell)
        end
        return moment
    end

    # Verify that the cell_volume corresponding to all the faces cover the
    # domain exactly dim times (NB since boundary faces are inactive, we need
    # periodicity)
    function total_volume_via_faces(tree)
        vol = 0.0
        for face ∈ all_faces(tree, filter = active)
            vol += cell_volume(face)
        end
        return vol
    end

    for dim ∈ 1:3
        tree = Tree(rand(dim), periodic=ones(Bool, dim))
        @test total_volume_via_cells(tree) == 1.0
        @test total_firstMoment_via_cells(tree) ≈ tree.position
        @test total_volume_via_faces(tree) == dim

        refine!(tree)
        @test total_volume_via_cells(tree) == 1.0
        @test total_firstMoment_via_cells(tree) ≈ tree.position
        @test total_volume_via_faces(tree) == dim

        refine!(tree, recurse=true)
        @test total_volume_via_cells(tree) == 1.0
        @test total_firstMoment_via_cells(tree) ≈ tree.position
        @test total_volume_via_faces(tree) == dim

        refine!(tree.children[end].children[1])
        @test total_volume_via_cells(tree) == 1.0
        @test total_firstMoment_via_cells(tree) ≈ tree.position
        @test total_volume_via_faces(tree) == dim

        refine!(tree, recurse=true)
        @test total_volume_via_cells(tree) == 1.0
        @test total_firstMoment_via_cells(tree) ≈ tree.position
        @test total_volume_via_faces(tree) == dim
    end
end
