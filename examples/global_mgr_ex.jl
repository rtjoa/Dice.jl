using Dice
# Initialize global BDD mgr.
# TODO: Can/should we avoid this being necessary?
dice_init()

# Run infer to get a distribution over values as a dict
infer(flip(0.4))  # Dict(false => 0.6, true => 0.4)

# For DistBools, we can also directly get the probability that it is true
infer_bool(flip(0.4))  # 0.4

# DistInts work as expected
x = Dice.ifelse(flip(0.3), DistInt(3), DistInt(4))
infer(safe_add(x, x))  # Dict(6 => 0.3, 14 => 0.7)

# Shared code!
include("util.jl")
y = discrete([0.1, 0.2, 0.3, 0.4])
infer(y)  # Dict(0 => 0.1, 1 => 0.2, 2 => 0.3, 3 => 0.4)
