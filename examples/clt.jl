using Revise
using Dice
using Dice: num_flips, num_nodes, to_dice_ir

code = @dice begin
    function uniform(b::Int, w::Int) # b is the bits for uniform, w is the bitwidth
        x = Vector(undef, b)
        for i = b:-1:1
            x[i] = flip(0.5)
        end
        return add_bits(ProbInt(x), w - b)
    end
    sum = uniform(2, 4)
    for i = 1:3
        sum = (sum + uniform(2, 4))[1]
    end
    println(max_bits(sum))
    prob_equals(sum, 6)
end

# BDD analysis
bdd = compile(code)
num_flips(bdd)
num_nodes(bdd)
infer(code, :bdd)

# IR analysis
# to_dice_ir(code)
# has_dice_binary() && rundice(code)
# has_dice_binary() && infer(code, :ocaml)