module FullyThreadedTree

    using Base.Cartesian

    abstract type AbstractTree{N} end
    abstract type AbstractFace{N} end

    include("face.jl")

    export Face,
           faces,
           cells,
           at_boundary,
           at_refinement,
           regular,
           active,
           level

    include("tree.jl")

    export Tree,
           initialize_tree,
           refine!,
           coarsen!,
           active,
           parent_of_active,
           initialized,
           level

    include("interface.jl")

    export iterate,
           show,
           length,
           cells,
           active_cells,
           parents_of_active_cell,
           boundary_faces,
           refinement_faces,
           regular_faces,
           active_faces


    include("tools.jl")

    export volume,
           centroid,
           integrate,
           cell_distance,
           area,
           volume,
           levels

    include("plotting.jl")

    export plot


end # module
