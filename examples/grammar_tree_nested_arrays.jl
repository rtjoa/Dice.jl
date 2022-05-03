using Dice
using Dice: num_flips, num_nodes
using Revise
include("util.jl")

rules = Dict([
    ("EXPR",  # LHS (always a single nonterminal)
        [(["1"], 0.6),  # Potential RHS, probability
        (["EXPR", "+", "EXPR"], 0.4)])
])
terminals = ["1", "+"]
others = ["EXPR", "S", "(", ")"]

terms_enum = DiceEnum(vcat(terminals, others))

start_term = "EXPR"
num_steps = 3
top_n = 40  # Only the top_n most likely strings are printed

code = @dice begin
    function expand_term(lhs, max_depth)
        if lhs in terminals
            DistVector([DistEnum(terms_enum, lhs)]), DistBool(dicecontext(), false)
        elseif max_depth == 0
            DistVector([]), flip(true)
        else
            expansion_error_tups = []
            for (rhs, p) in rules[lhs]
                expansion = DistVector([])
                error = flip(false)
                for subterm in rhs
                    x = expand_term(subterm, max_depth - 1)
                    expansion, error = prob_extend(expansion, x[1]), error | x[2] 
                end
                push!(expansion_error_tups, (expansion, error))
            end
            
            # Find flip weights
            v = Vector(undef, length(rules[lhs]))
            s = 1.
            for (i, (rhs, p)) in reverse(collect(enumerate(rules[lhs])))
                v[i] = p/s
                s -= p
            end

            # Choose rhs
            rhs, error = expansion_error_tups[1]
            for i in 2:length(rules[lhs])
                f = flip(v[i])
                rhs = if f expansion_error_tups[i][1] else rhs end
                error = if f expansion_error_tups[i][2] else error end
            end
            if max_depth == num_steps  # Wrapping first iteration w start NT unnecessary
                rhs, error
            else
                # rhs_wrapped = DistVector([rhs])
                rhs_wrapped = prob_append(DistVector([DistEnum(terms_enum, lhs)]), rhs)
                rhs_wrapped, error
            end
        end
    end
    rhs, error = expand_term(start_term, num_steps)
    [rhs, error]
end
bdd = compile(code)
error_p = 0
dist = Dict()
group_infer(bdd[2], true, 1.0) do error, prior, p
    if error
        # We don't care about rhs if there is error; normally we would call group_infer again
        global error_p = p 
    else
        group_infer(bdd[1], prior, p) do assignment, _, p
            dist[assignment] = p
        end
    end
end
println("Probability of error: $(error_p)")
dist = sort([(x, val) for (x, val) in dist], by= xv -> -xv[2])  # by decreasing probability
print_dict(dist[1:min(length(dist),top_n)])
println("$(num_nodes(bdd)) nodes, $(num_flips(bdd)) flips")

#==
Probability of error: 0.06400000000000002
Vector{Tuple{Vector{Any}, Float64}} with 16 entries
   Any["1"]                                                => 0.6
   Any["EXPR", Any["1"], "+", "EXPR", Any["1"]]            => 0.14400000000000002  
   Any["EXPR", Any["EXPR", Any["1"], "+", "EXPR", Any["1"]], "+", "EXPR", Any["1"]]                                     => 0.034560000000000014 
   Any["EXPR", Any["1"], "+", "EXPR", Any["EXPR", Any["1"], "+", "EXPR", Any["1"]]]                                     => 0.034560000000000014 
   Any["EXPR", Any["EXPR", Any["1"], "+", "EXPR", Any["+"]], "+", "EXPR", Any["1"]]                                     => 0.023040000000000005 
   Any["EXPR", Any["1"], "+", "EXPR", Any["EXPR", Any["+"], "+", "EXPR", Any["1"]]]                                     => 0.023040000000000005 
   Any["EXPR", Any["EXPR", Any["+"], "+", "EXPR", Any["1"]], "+", "EXPR", Any["1"]]                                     => 0.023040000000000005 
   Any["EXPR", Any["EXPR", Any["+"], "+", "EXPR", Any["+"]], "+", "EXPR", Any["1"]]                                     => 0.01536
   Any["EXPR", Any["EXPR", Any["1"], "+", "EXPR", Any["1"]], "+", "EXPR", Any["EXPR", Any["1"], "+", "EXPR", Any["1"]]] => 0.008294400000000006 
   Any["EXPR", Any["EXPR", Any["+"], "+", "EXPR", Any["1"]], "+", "EXPR", Any["EXPR", Any["1"], "+", "EXPR", Any["1"]]] => 0.005529600000000003 
   Any["EXPR", Any["EXPR", Any["1"], "+", "EXPR", Any["1"]], "+", "EXPR", Any["EXPR", Any["+"], "+", "EXPR", Any["1"]]] => 0.005529600000000003 
   Any["EXPR", Any["EXPR", Any["1"], "+", "EXPR", Any["+"]], "+", "EXPR", Any["EXPR", Any["1"], "+", "EXPR", Any["1"]]] => 0.005529600000000003 
   Any["EXPR", Any["EXPR", Any["1"], "+", "EXPR", Any["+"]], "+", "EXPR", Any["EXPR", Any["+"], "+", "EXPR", Any["1"]]] => 0.0036864000000000007   Any["EXPR", Any["EXPR", Any["+"], "+", "EXPR", Any["+"]], "+", "EXPR", Any["EXPR", Any["1"], "+", "EXPR", Any["1"]]] => 0.0036864000000000007   Any["EXPR", Any["EXPR", Any["+"], "+", "EXPR", Any["1"]], "+", "EXPR", Any["EXPR", Any["+"], "+", "EXPR", Any["1"]]] => 0.0036864000000000007   Any["EXPR", Any["EXPR", Any["+"], "+", "EXPR", Any["+"]], "+", "EXPR", Any["EXPR", Any["+"], "+", "EXPR", Any["1"]]] => 0.0024576
11 nodes, 7 flips
==#