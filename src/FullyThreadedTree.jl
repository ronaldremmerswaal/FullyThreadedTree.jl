module FullyThreadedTree

    include("quad.jl")

    export Quad,
           initialize_quadtree,
           refine!,
           isleaf,
           isleafparent

    include("interface.jl")

    export iterate

    include("tools.jl")

    export volume,
           first_moment,
           integrate,
           nr_quads,
           nr_leaves,
           quad_volume

    include("plotting.jl")

    export plot

end # module
