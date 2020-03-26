using FullyThreadedTree
using Test

@testset "FullyThreadedTree.jl" begin
    # Write your own tests here.
    function total_volume_via_faces(tree)
        vol = 0.0
        for face ∈ active_faces(tree)
            vol += volume(face)
        end
        return vol
    end
end
