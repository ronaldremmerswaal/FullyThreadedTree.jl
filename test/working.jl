using FullyThreadedTree


f = x -> 1 / (1. + x[1]^2 + x[2]^2)
q = initialize_tree([0.0, 0.0], f);
