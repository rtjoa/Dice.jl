using Revise
using Dice
using Dice: num_flips, num_nodes, ifelse

# Calculate discrete(0.1, 0.2, 0.3, 0.4) using SKB
code_skb = @dice begin
    ifelse(flip(1/10),
        DistInt(dicecontext(), 0),
        ifelse(flip(2/9),
            DistInt(dicecontext(), 1),
            ifelse(flip(3/7),
                DistInt(dicecontext(), 2),
                DistInt(dicecontext(), 3)
            )
        )
    )
end

# Calculate discrete(0.1, 0.2, 0.3, 0.4) using BWH
code_bwh = @dice begin
    b1 = flip(7/10)
    b0 = Dice.ifelse(b1, flip(4/7), flip(2/3))
    DistInt([b0, b1])
end

bdd = compile(code_bwh)
println("BWH: $(infer(code_bwh, :bdd))")
println("$(num_nodes(bdd)) add nodes, $(num_nodes(bdd, as_add=false)) bdd nodes, $(num_flips(bdd)) flips")
dump_dot(bdd, "bwh_add.dot")
dump_dot(bdd, "bwh_bdd.dot", as_add=false)
println()

bdd = compile(code_skb)
println("SKB: $(infer(code_skb, :bdd))")
println("$(num_nodes(bdd)) add nodes, $(num_nodes(bdd, as_add=false)) bdd nodes, $(num_flips(bdd)) flips")
dump_dot(bdd, "skb_add.dot")
dump_dot(bdd, "skb_bdd.dot", as_add=false)