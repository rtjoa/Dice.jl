# Dynamic programming version of grammar.jl
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

start_term = "S"
num_iters = 4
top_n = 40  # Only the top_n most likely strings are printed

# Dict from possible replacements for a sequence of terms to their probabilities
function generate_replacements(level, rules)
    if length(level) == 0
        return Dict([([], 1.)])
    end
    replacements = Dict()
    rhs_list = get(rules, level[1], [(level[1], 1.)])  # If terminal, always replaced by self
    for (first_replacement, p1) in rhs_list
        rest = @view level[2:length(level)]
        for (rest_replacement, p2) in generate_replacements(rest, rules)
            replacement = vcat(first_replacement, rest_replacement)  # todo: try linked list instead
            replacements[replacement] = get(replacements, replacement, 0.) + p1 * p2
        end
    end
    replacements
end

function generate_sentences(start, rules, num_iters)
    levels = Dict()
    levels[[start]] = 1.
    for _ in 1:num_iters
        next_levels = Dict()
        # For each possible sequence at this level
        for (level, p1) in levels
            # For each possible expansion of this sequence
            for (replacement, p2) in generate_replacements(level, rules)
                next_levels[replacement] = get(next_levels, replacement, 0.) + p1 * p2
            end
        end
        levels = next_levels
    end
    levels
end

@time dist = generate_sentences(start_term, rules, num_iters)
dist = sort([(x, val) for (x, val) in dist], by= xv -> -xv[2])  # by decreasing probability
print_dict(dist[1:min(length(dist),top_n)])

#==
 0.349707 seconds (1.77 M allocations: 66.971 MiB, 2.45% gc time, 89.46% compilation time)
Vector{Tuple{Vector{Any}, Float64}} with 40 entries
   Any["Alice", "saw"]                               => 0.16799999999999998
   Any["Bob", "saw"]                                 => 0.16799999999999998
   Any["Bob", "ran"]                                 => 0.11199999999999999
   Any["Alice", "ran"]                               => 0.11199999999999999
   Any["Bob", "saw", "Bob"]                          => 0.0288
   Any["Bob", "saw", "Alice"]                        => 0.0288
   Any["Alice", "saw", "Alice"]                      => 0.0288
   Any["Alice", "saw", "Bob"]                        => 0.0288
   Any["Bob", "ran", "Alice"]                        => 0.019200000000000002
   Any["Bob", "ran", "Bob"]                          => 0.019200000000000002
   Any["Alice", "ran", "Alice"]                      => 0.019200000000000002
   Any["Alice", "ran", "Bob"]                        => 0.019200000000000002
   Any["Bob", "and", "Alice", "saw"]                 => 0.013439999999999999
   Any["Alice", "and", "Alice", "saw"]               => 0.013439999999999999
   Any["Bob", "and", "Bob", "saw"]                   => 0.013439999999999999
   Any["Alice", "and", "Bob", "saw"]                 => 0.013439999999999999
   Any["Bob", "and", "Alice", "ran"]                 => 0.008960000000000001
   Any["Alice", "and", "Alice", "ran"]               => 0.008960000000000001
   Any["Alice", "and", "Bob", "ran"]                 => 0.008960000000000001
   Any["Bob", "and", "Bob", "ran"]                   => 0.008960000000000001
   Any["Alice", "saw", "Bob", "and", "Alice"]        => 0.0023040000000000005
   Any["Bob", "saw", "Bob", "and", "Bob"]            => 0.0023040000000000005
   Any["Alice", "saw", "Alice", "and", "Alice"]      => 0.0023040000000000005
   Any["Bob", "saw", "Bob", "and", "Alice"]          => 0.0023040000000000005
   Any["Bob", "saw", "Alice", "and", "Bob"]          => 0.0023040000000000005
   Any["Bob", "saw", "Alice", "and", "Alice"]        => 0.0023040000000000005
   Any["Alice", "saw", "Bob", "and", "Bob"]          => 0.0023040000000000005
   Any["Alice", "saw", "Alice", "and", "Bob"]        => 0.0023040000000000005
   Any["Alice", "and", "Alice", "saw", "Bob"]        => 0.002304
   Any["Bob", "and", "Alice", "saw", "Alice"]        => 0.002304
   Any["Alice", "and", "Bob", "saw", "Alice"]        => 0.002304
   Any["Bob", "and", "Alice", "saw", "Bob"]          => 0.002304
   Any["Bob", "and", "Bob", "saw", "Alice"]          => 0.002304
   Any["Alice", "and", "Bob", "saw", "Bob"]          => 0.002304
   Any["Bob", "and", "Bob", "saw", "Bob"]            => 0.002304
   Any["Alice", "and", "Alice", "saw", "Alice"]      => 0.002304
   Any["Bob", "and", "Bob", "and", "Bob", "saw"]     => 0.0021504000000000002
   Any["Bob", "and", "Alice", "and", "Bob", "saw"]   => 0.0021504000000000002
   Any["Alice", "and", "Alice", "and", "Bob", "saw"] => 0.0021504000000000002
   Any["Bob", "and", "Alice", "and", "Alice", "saw"] => 0.0021504000000000002
==#
