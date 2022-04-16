using Revise
using Dice
using Dice: num_flips, num_nodes, ifelse, dump_dot

# Calculate discrete(0.1, 0.2, 0.3, 0.4) using SBK
code_sbk = @dice begin
    if flip(1/10)
        DistInt(0)
    elseif flip(2/9)
        DistInt(1)
    elseif flip(3/7)
        DistInt(2)
    else
        DistInt(3)
    end
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

bdd = compile(code_sbk)
println("SBK: $(infer(code_sbk, :bdd))")
println("$(num_nodes(bdd)) add nodes, $(num_nodes(bdd, as_add=false)) bdd nodes, $(num_flips(bdd)) flips")
dump_dot(bdd, "sbk_add.dot")
dump_dot(bdd, "sbk_bdd.dot", as_add=false)