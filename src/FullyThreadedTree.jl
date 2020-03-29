module FullyThreadedTree

    using Base.Cartesian

    abstract type AbstractTree{N} end
    abstract type AbstractFace{N} end

    include("face.jl")

    export Face,
           cells,
           at_boundary,
           at_refinement,
           regular,
           active,
           level,
           collect_faces

    include("tree.jl")

    export Tree,
           initialize_tree,
           refine!,
           coarsen!,
           active,
           parent_of_active,
           initialized,
           level,
           faces,
           siblings,
           root,
           collect_cells

    include("interface.jl")

    export iterate,
           show,
           length,
           cells,
           all_faces

    include("tools.jl")

    export volume,
           centroid,
           integrate,
           cell_distance,
           cell_volume,
           area,
           volume,
           levels

    include("plotting.jl")

    export plot,
           plot!


end # module
