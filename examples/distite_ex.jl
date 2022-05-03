using Dice

code = @dice begin
    DistITE(dicecontext(), flip(0.5), DistInt(8), flip(false))
end
bdd = compile(code)
dist = infer(bdd)