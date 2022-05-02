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
num_steps = 4
top_n = 40  # Only the top_n most likely strings are printed

code = @dice begin
    lparen = DistEnum(terms_enum, "(")
    rparen = DistEnum(terms_enum, ")")
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
                rhs_wrapped = prob_extend(DistVector([DistEnum(terms_enum, lhs), lparen]), prob_append(rhs, rparen))
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
dist = sort([(join(x, ' '), val) for (x, val) in dist], by= xv -> -xv[2])  # by decreasing probability
print_dict(dist[1:min(length(dist),top_n)])
println("$(num_nodes(bdd)) nodes, $(num_flips(bdd)) flips")

#==
Probability of error: 0.025600000000000008
Vector{Tuple{String, Float64}} with 40 entries
   1                                                                                         => 0.5999999999999999
   EXPR ( 1 ) + EXPR ( 1 )                                                                   => 0.14400000000000002
   EXPR ( 1 ) + EXPR ( EXPR ( 1 ) + EXPR ( 1 ) )                                             => 0.034560000000000014
   EXPR ( EXPR ( 1 ) + EXPR ( 1 ) ) + EXPR ( 1 )                                             => 0.034560000000000014
   EXPR ( EXPR ( 1 ) + EXPR ( 1 ) ) + EXPR ( EXPR ( 1 ) + EXPR ( 1 ) )                       => 0.008294400000000006
   EXPR ( 1 ) + EXPR ( EXPR ( EXPR ( 1 ) + EXPR ( 1 ) ) + EXPR ( 1 ) )                       => 0.008294400000000006
   EXPR ( 1 ) + EXPR ( EXPR ( 1 ) + EXPR ( EXPR ( 1 ) + EXPR ( 1 ) ) )                       => 0.008294400000000006
   EXPR ( EXPR ( 1 ) + EXPR ( EXPR ( 1 ) + EXPR ( 1 ) ) ) + EXPR ( 1 )                       => 0.008294400000000006
   EXPR ( EXPR ( EXPR ( 1 ) + EXPR ( 1 ) ) + EXPR ( 1 ) ) + EXPR ( 1 )                       => 0.008294400000000006
   EXPR ( 1 ) + EXPR ( EXPR ( EXPR ( + ) + EXPR ( 1 ) ) + EXPR ( 1 ) )                       => 0.005529600000000003
   EXPR ( EXPR ( EXPR ( + ) + EXPR ( 1 ) ) + EXPR ( 1 ) ) + EXPR ( 1 )                       => 0.005529600000000003
   EXPR ( 1 ) + EXPR ( EXPR ( EXPR ( 1 ) + EXPR ( + ) ) + EXPR ( 1 ) )                       => 0.005529600000000003
   EXPR ( 1 ) + EXPR ( EXPR ( 1 ) + EXPR ( EXPR ( + ) + EXPR ( 1 ) ) )                       => 0.005529600000000003
   EXPR ( EXPR ( 1 ) + EXPR ( EXPR ( 1 ) + EXPR ( + ) ) ) + EXPR ( 1 )                       => 0.005529600000000003
   EXPR ( EXPR ( EXPR ( 1 ) + EXPR ( + ) ) + EXPR ( 1 ) ) + EXPR ( 1 )                       => 0.005529600000000003
   EXPR ( EXPR ( 1 ) + EXPR ( EXPR ( + ) + EXPR ( 1 ) ) ) + EXPR ( 1 )                       => 0.005529600000000003
   EXPR ( EXPR ( EXPR ( + ) + EXPR ( + ) ) + EXPR ( 1 ) ) + EXPR ( 1 )                       => 0.0036864000000000007
   EXPR ( EXPR ( 1 ) + EXPR ( EXPR ( + ) + EXPR ( + ) ) ) + EXPR ( 1 )                       => 0.0036864000000000007
   EXPR ( 1 ) + EXPR ( EXPR ( EXPR ( + ) + EXPR ( + ) ) + EXPR ( 1 ) )                       => 0.0036864000000000007
   EXPR ( EXPR ( EXPR ( 1 ) + EXPR ( 1 ) ) + EXPR ( 1 ) ) + EXPR ( EXPR ( 1 ) + EXPR ( 1 ) ) => 0.0019906560000000017
   EXPR ( EXPR ( 1 ) + EXPR ( 1 ) ) + EXPR ( EXPR ( 1 ) + EXPR ( EXPR ( 1 ) + EXPR ( 1 ) ) ) => 0.0019906560000000017
   EXPR ( EXPR ( 1 ) + EXPR ( EXPR ( 1 ) + EXPR ( 1 ) ) ) + EXPR ( EXPR ( 1 ) + EXPR ( 1 ) ) => 0.0019906560000000017
   EXPR ( 1 ) + EXPR ( EXPR ( EXPR ( 1 ) + EXPR ( 1 ) ) + EXPR ( EXPR ( 1 ) + EXPR ( 1 ) ) ) => 0.0019906560000000017
   EXPR ( EXPR ( EXPR ( 1 ) + EXPR ( 1 ) ) + EXPR ( EXPR ( 1 ) + EXPR ( 1 ) ) ) + EXPR ( 1 ) => 0.0019906560000000017
   EXPR ( EXPR ( 1 ) + EXPR ( 1 ) ) + EXPR ( EXPR ( EXPR ( 1 ) + EXPR ( 1 ) ) + EXPR ( 1 ) ) => 0.0019906560000000017
   EXPR ( EXPR ( 1 ) + EXPR ( EXPR ( + ) + EXPR ( 1 ) ) ) + EXPR ( EXPR ( 1 ) + EXPR ( 1 ) ) => 0.0013271040000000006
   EXPR ( EXPR ( 1 ) + EXPR ( EXPR ( 1 ) + EXPR ( + ) ) ) + EXPR ( EXPR ( 1 ) + EXPR ( 1 ) ) => 0.0013271040000000006
   EXPR ( EXPR ( 1 ) + EXPR ( 1 ) ) + EXPR ( EXPR ( EXPR ( 1 ) + EXPR ( + ) ) + EXPR ( 1 ) ) => 0.0013271040000000006
   EXPR ( EXPR ( EXPR ( + ) + EXPR ( 1 ) ) + EXPR ( 1 ) ) + EXPR ( EXPR ( 1 ) + EXPR ( 1 ) ) => 0.0013271040000000006
   EXPR ( 1 ) + EXPR ( EXPR ( EXPR ( + ) + EXPR ( 1 ) ) + EXPR ( EXPR ( 1 ) + EXPR ( 1 ) ) ) => 0.0013271040000000006
   EXPR ( EXPR ( EXPR ( 1 ) + EXPR ( + ) ) + EXPR ( 1 ) ) + EXPR ( EXPR ( 1 ) + EXPR ( 1 ) ) => 0.0013271040000000006
   EXPR ( EXPR ( EXPR ( + ) + EXPR ( 1 ) ) + EXPR ( EXPR ( 1 ) + EXPR ( 1 ) ) ) + EXPR ( 1 ) => 0.0013271040000000006
   EXPR ( EXPR ( 1 ) + EXPR ( 1 ) ) + EXPR ( EXPR ( EXPR ( + ) + EXPR ( 1 ) ) + EXPR ( 1 ) ) => 0.0013271040000000006
   EXPR ( EXPR ( 1 ) + EXPR ( 1 ) ) + EXPR ( EXPR ( 1 ) + EXPR ( EXPR ( + ) + EXPR ( 1 ) ) ) => 0.0013271040000000006
   EXPR ( 1 ) + EXPR ( EXPR ( EXPR ( 1 ) + EXPR ( 1 ) ) + EXPR ( EXPR ( + ) + EXPR ( 1 ) ) ) => 0.0013271040000000006
   EXPR ( 1 ) + EXPR ( EXPR ( EXPR ( 1 ) + EXPR ( + ) ) + EXPR ( EXPR ( 1 ) + EXPR ( 1 ) ) ) => 0.0013271040000000006
   EXPR ( EXPR ( EXPR ( 1 ) + EXPR ( + ) ) + EXPR ( EXPR ( 1 ) + EXPR ( 1 ) ) ) + EXPR ( 1 ) => 0.0013271040000000006
   EXPR ( EXPR ( EXPR ( 1 ) + EXPR ( 1 ) ) + EXPR ( EXPR ( 1 ) + EXPR ( + ) ) ) + EXPR ( 1 ) => 0.0013271040000000006
   EXPR ( EXPR ( EXPR ( 1 ) + EXPR ( 1 ) ) + EXPR ( EXPR ( + ) + EXPR ( 1 ) ) ) + EXPR ( 1 ) => 0.0013271040000000006
   EXPR ( 1 ) + EXPR ( EXPR ( EXPR ( 1 ) + EXPR ( + ) ) + EXPR ( EXPR ( + ) + EXPR ( 1 ) ) ) => 0.0008847360000000002
255 nodes, 15 flips
==#