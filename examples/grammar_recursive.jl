using Dice
using Dice: num_flips, num_nodes
using Revise
include("util.jl")

rules = Dict([
    ("S",  # LHS (always a single nonterminal)
        [(["NP", "VP"], 1.0)]), # Potential RHS, probability
    ("NP",
        [(["Alice"], 0.4),
        (["Bob"], 0.4),
        (["NP", "and", "NP"], 0.2)]),
    ("VP",
        [(["V"], 0.7),
        (["V", "NP"], 0.3)]),
    ("V",
        [(["ran"], 0.4),
        (["saw"], 0.6)])
])

terminals = ["ran", "saw", "Alice", "Bob", "and"]
terms_enum = DiceEnum(terminals)

start_term = "S"
num_steps = 4
top_n = 40  # Only the top_n most likely strings are printed

code = @dice begin
    function expand_term(lhs, max_depth)
        if lhs in terminals
            DistVector([DistEnum(terms_enum, lhs)]), DistBool(dicecontext(), false)
        elseif max_depth == 0
            DistVector([]), DistBool(dicecontext(), true)
        else
            expansion_error_tups = []
            for (rhs, p) in rules[lhs]
                expansion = DistVector([])
                error = DistBool(dicecontext(), false)
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
            rhs, error
        end
    end
    rhs, error = expand_term(start_term, num_steps)
    observe = (rhs.len > 2) & prob_equals(rhs[2], DistEnum(terms_enum, "and"))
    (rhs, error, observe)
end
rhs_bdd, error_bdd, observe_bdd = compile(code)
error_p = 0
dist = Dict()
group_infer(observe_bdd, true, 1.0) do observe, observe_prior, denom
    if !observe return end
    group_infer(error_bdd, observe_prior, denom) do error, prior, p
        if error
            # We don't care about rhs if there is error; normally we would call group_infer again
            global error_p = p/denom
        else
            group_infer(rhs_bdd, prior, p) do assignment, _, p
                dist[assignment] = p/denom
            end
        end
    end
end
println("Probability of error: $(error_p)")
dist = sort([(x, val) for (x, val) in dist], by= xv -> -xv[2])  # by decreasing probability
print_dict(dist[1:min(length(dist),top_n)])
println("$(num_nodes([rhs_bdd, error_bdd, error_bdd])) nodes, $(num_flips([rhs_bdd, error_bdd, error_bdd])) flips")

#==
Probability of error: 0.011999999999999997
Vector{Tuple{Vector{Any}, Float64}} with 40 entries
   Any["Bob", "and", "Alice", "saw"]                   => 0.0672
   Any["Alice", "and", "Alice", "saw"]                 => 0.0672
   Any["Bob", "and", "Bob", "saw"]                     => 0.0672
   Any["Alice", "and", "Bob", "saw"]                   => 0.0672
   Any["Bob", "and", "Alice", "ran"]                   => 0.044799999999999965
   Any["Alice", "and", "Alice", "ran"]                 => 0.044799999999999965
   Any["Alice", "and", "Bob", "ran"]                   => 0.044799999999999965
   Any["Bob", "and", "Bob", "ran"]                     => 0.044799999999999965
   Any["Alice", "and", "Alice", "saw", "Bob"]          => 0.011519999999999999
   Any["Bob", "and", "Alice", "saw", "Alice"]          => 0.011519999999999999
   Any["Alice", "and", "Bob", "saw", "Alice"]          => 0.011519999999999999
   Any["Bob", "and", "Alice", "saw", "Bob"]            => 0.011519999999999999
   Any["Bob", "and", "Bob", "saw", "Alice"]            => 0.011519999999999999
   Any["Alice", "and", "Bob", "saw", "Bob"]            => 0.011519999999999999
   Any["Bob", "and", "Bob", "saw", "Bob"]              => 0.011519999999999999
   Any["Alice", "and", "Alice", "saw", "Alice"]        => 0.011519999999999999
   Any["Bob", "and", "Bob", "and", "Bob", "saw"]       => 0.010751999999999998
   Any["Bob", "and", "Alice", "and", "Bob", "saw"]     => 0.010751999999999998
   Any["Alice", "and", "Alice", "and", "Bob", "saw"]   => 0.010751999999999998
   Any["Bob", "and", "Alice", "and", "Alice", "saw"]   => 0.010751999999999998
   Any["Alice", "and", "Bob", "and", "Bob", "saw"]     => 0.010751999999999998
   Any["Alice", "and", "Bob", "and", "Alice", "saw"]   => 0.010751999999999998
   Any["Bob", "and", "Bob", "and", "Alice", "saw"]     => 0.010751999999999998
   Any["Alice", "and", "Alice", "and", "Alice", "saw"] => 0.010751999999999998
   Any["Alice", "and", "Bob", "ran", "Bob"]            => 0.007679999999999998
   Any["Bob", "and", "Bob", "ran", "Alice"]            => 0.007679999999999998
   Any["Bob", "and", "Bob", "ran", "Bob"]              => 0.007679999999999998
   Any["Alice", "and", "Alice", "ran", "Alice"]        => 0.007679999999999998
   Any["Bob", "and", "Alice", "ran", "Alice"]          => 0.007679999999999998
   Any["Alice", "and", "Alice", "ran", "Bob"]          => 0.007679999999999998
   Any["Alice", "and", "Bob", "ran", "Alice"]          => 0.007679999999999998
   Any["Bob", "and", "Alice", "ran", "Bob"]            => 0.007679999999999998
   Any["Bob", "and", "Bob", "and", "Alice", "ran"]     => 0.007167999999999994
   Any["Bob", "and", "Alice", "and", "Bob", "ran"]     => 0.007167999999999994
   Any["Bob", "and", "Alice", "and", "Alice", "ran"]   => 0.007167999999999994
   Any["Alice", "and", "Alice", "and", "Alice", "ran"] => 0.007167999999999994
   Any["Bob", "and", "Bob", "and", "Bob", "ran"]       => 0.007167999999999994
   Any["Alice", "and", "Bob", "and", "Bob", "ran"]     => 0.007167999999999994
   Any["Alice", "and", "Bob", "and", "Alice", "ran"]   => 0.007167999999999994
   Any["Alice", "and", "Alice", "and", "Bob", "ran"]   => 0.007167999999999994
137 nodes, 23 flips
==#