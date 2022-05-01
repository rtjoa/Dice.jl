using Dice

enum = DiceEnum(["random", 7, ["xyz"]])
code = @dice begin
    if flip(1/10)
        DistEnum(enum, "random")
    elseif flip(2/9)
        DistEnum(enum, 7)
    else
        DistEnum(enum, ["xyz"])
    end
end
bdd = compile(code)
dist = infer(bdd)
@assert sum(values(dist)) ≈ 1
@assert dist["random"] ≈ 1/10
@assert dist[7] ≈ 2/10
@assert dist[["xyz"]] ≈ 7/10

code = @dice begin
    x = if flip(1/10)
        DistEnum(enum, "random")
    elseif flip(2/9)
        DistEnum(enum, 7)
    else
        DistEnum(enum, ["xyz"])
    end
    y = if flip(1/10)
        DistEnum(enum, "random")
    elseif flip(2/9)
        DistEnum(enum, 7)
    else
        DistEnum(enum, ["xyz"])
    end
    prob_equals(x, y)
end
bdd = compile(code)
@assert infer(bdd) ≈ (1/10)^2 + (2/10)^2 + (7/10)^2
