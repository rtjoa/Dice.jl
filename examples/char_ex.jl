using Dice
using Dice: num_flips, num_nodes, ifelse, dump_dot

code = @dice begin
    if flip(1/10)
        DistChar('a')
    elseif flip(2/9)
        DistChar('D')
    elseif flip(3/7)
        DistChar(' ')
    else
        DistChar('!')
    end
end

bdd = compile(code)
infer(bdd)