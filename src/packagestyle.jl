using FileIO
using Pkg

function get_jl_file_expressions(path)::Expr
    return Meta.parseall(path |> open |> read |> String)
end

function get_using_exprs(prog)::Array{Expr}
    usings = []

    for arg in prog.args
        if typeof(arg) == Expr && arg.head == :using
            push!(usings, arg)
        elseif typeof(arg) == Expr
            cat(usings, get_using_exprs(arg), dims=1)
        end
    end

    return usings
end

function get_module_names(usings_list)
    """
    Assumes that usings_list is a list of exprs all with head :using
    """
    map(e -> e.args[1].args[1] |> String, usings_list)
end

function add_packages(modules; dir=".")
    Pkg.activate(dir)
    for m in modules
        println("> Attempting to add $m")
        try
            Pkg.add(m)
        catch e
            println(">>> Error in adding $m: $e")
        end
    end
end

function packagestyle(path)
    if isdir(path)
        dir_contents = readdir(path)
        for dpath in dir_contents
            packagestyle(path * dpath)
        end
    else
        prog = nothing
        try
            println("> Parsing $path")
            prog = path |> get_jl_file_expressions 
        catch e
            throw(Exception(">>> Error parsing $path: $e"))
        end

        prog |> get_using_exprs |> get_module_names |>
            add_packages

    end
end

packagestyle(ARGS[1])
