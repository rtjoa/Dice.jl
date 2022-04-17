using Dice

code = @dice begin
    s = if flip(3/5) DistString("sand") else DistString("san") end
    s = if flip(2/3) s + 'd' else s end
    t = if flip(1/10) DistString("wich") else DistString("box") end
    prob_equals(s + t, "sandwich")
end
bdd = compile(code)
@assert infer(bdd) ≈ 3/5*1/3*1/10 + 2/5*2/3*1/10

code = @dice begin
    s = if flip(0.6) DistString("abc") else DistString("xyz") end

    # Choose whether to change index 1 (Pr=0.3) or 2 (Pr = 0.7)
    f1 = flip(0.3)
    i = DistInt([f1, !f1])

    c = if flip(0.1) DistChar('d') else DistChar('e') end
    s = prob_setindex(s, i, c)
    prob_equals("aec", s)
end
bdd = compile(code)
@assert infer(bdd) ≈ 0.6*0.7*0.9