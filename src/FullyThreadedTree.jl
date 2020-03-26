module FullyThreadedTree

    abstract type AbstractTree{N} end
    abstract type AbstractFace{N,D} end

    include("face.jl")

    export Face,
           faces,
           cells,
           at_boundary,
           at_refinement,
           ordinary,
           active

    include("tree.jl")

    export Tree,
           initialize_tree,
           refine!,
           coarsen!,
           active,
           parent_of_active,
           initialized

    include("interface.jl")

    export iterate,
           show,
           length,
           cells,
           active_cells,
           parents_of_active_cell,
           boundary_faces,
           refinement_faces,
           ordinary_faces


    include("tools.jl")

    export volume,
           first_moment,
           integrate,
           cell_volume,
           levels

    include("plotting.jl")

    export plot


end # module
