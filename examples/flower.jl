using FullyThreadedTree
using PrettyTables

max_steps = 12
error_tolerance = 1E-2
R = pi / 12.

# Define a smooth function which has a sharp gradient at some interface
interface(x) = sum(x.^2) - R^2 * (1 + 0.25 * cos(5 * atan(x[end], x[1]) + 1))^2
shape(x) = tanh(32 * pi * interface(x))

function adaptive_refinement(fun::Function, max_steps::Int, error_tolerance; plot_error::Bool = false, print_table::Bool = false, dim::Int = 2)
    tree = Tree(zeros(dim), cell_state = fun)

    collect_data = print_table || plot_error
    if collect_data
        max_error = Vector()
        integral = Vector()
        nr_of_cells = Vector()
        nr_of_active_cells = Vector()
        nr_marked_cells = Vector()
    end

    marked = Vector{Tree{dim}}()
    push!(marked, tree)
    for steps = 1:max_steps

        refine!(marked, cell_state = fun, recurse = true)
        if collect_data
            push!(integral, integrate(tree))
            push!(nr_of_cells, length(cells(tree)))
            push!(nr_of_active_cells, length(cells(tree, filter=active)))
        end
        marked = Vector{Tree{dim}}()

        if collect_data
            push!(max_error, 0.)
            push!(nr_marked_cells, 0)
        end
        for cell ∈ cells(tree, filter=parent_of_active)
            error_estimate = abs(cell.state - sum([child.state for child ∈ cell.children]) / (1<<dim))
            if collect_data max_error[end] = max(error_estimate, max_error[end]) end
            if error_estimate > error_tolerance
                if collect_data  nr_marked_cells[end] += 1<<dim end
                push!(marked, cell)
            end
        end

        if length(marked) == 0
            max_steps = steps
            break
        end
    end

    if print_table
        formatter = Dict(0 => (v, i) -> typeof(v) == Int ? Int(v) : round(v; digits=5))
        pretty_table(hcat(1 : max_steps, nr_of_active_cells, nr_of_cells, nr_marked_cells, max_error, integral), ["step", "# active_cells", "# cells", "# marked", "error", "integral"], tf = markdown, formatter = formatter)
    end
    if plot_error
        display(plot(nr_of_active_cells, max_error, xaxis = :log, yaxis = :log))
    end

    return tree
end

tree = adaptive_refinement(shape, max_steps, error_tolerance, print_table=true)
display(plot(tree))
