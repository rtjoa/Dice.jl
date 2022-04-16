using Dice
using Dice: num_flips, num_nodes, ifelse, dump_dot

code = @dice begin
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

bdd = compile(code)
infer(bdd)