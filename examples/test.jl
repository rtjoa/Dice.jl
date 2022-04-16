using Revise
using Dice
using Dice: num_flips, num_nodes, ifelse, dump_dot

code = @dice begin
    a = DistInt([flip(0.5), flip(0.5)])  # uniform distribution on {0, 1, 2, 3}
    if !prob_equals(a, 3)
        a + 1
    else
        a
    end
    # [0.0, 0.25, 0.25, 0.5]
    # Error: 0.25
    # true
end

bdd = compile(code)
println(infer(bdd))
println("Error: $(infer_error(bdd))")
dump_dot(bdd, "test.dot")
println("$(num_nodes(bdd)) nodes, $(num_flips(bdd)) flips")
