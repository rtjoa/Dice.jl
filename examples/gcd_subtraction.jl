using Revise
using Dice

# 4 has probability 0.3, etc...
dist_vals = [4, 6, 9]
dist_weights = [0.3, 0.2, 0.5]

# Convert to input for dice discrete distribution
dice_disc = zeros(maximum(dist_vals) + 1)
for (val, weight) in zip(dist_vals, dist_weights)
    dice_disc[val + 1] = weight
end

# Naively calculate GCD(discrete(dice_disc), discrete(dice_disc))
gcd_dist = Dict()
for (val1, weight1) in zip(dist_vals, dist_weights)
    for (val2, weight2) in zip(dist_vals, dist_weights)
        res = gcd(val1, val2)
        if !haskey(gcd_dist, res)
            gcd_dist[res] = 0
        end
        gcd_dist[res] += weight1 * weight2
    end
end

@show gcd_dist

code = @dice begin
    function discrete(p::Vector{Float64})
        mb = length(p)
        v = Vector(undef, mb)
        sum = 1
        for i=1:mb
            v[i] = p[i]/sum
            sum = sum - p[i]
        end

        ans = DistInt(dicecontext(), mb-1)
        for i=mb-1:-1:1
            ans = if flip(v[i]) DistInt(dicecontext(), i-1) else ans end
        end
        return ans
    end

    # Subtraction-based GCD
    # https://en.wikipedia.org/wiki/Euclidean_algorithm#Implementations
    function gcd(a::Tuple{DistInt, DistBool}, b::Tuple{DistInt, DistBool})
        for _ = 0:100  # TODO: better bound
            gt = a[1] > b[1]
            lt = b[1] > a[1]
            amb = a[1] - b[1]
            bma = b[1] - a[1]
            a = Dice.ifelse(gt, amb[1], a[1]), a[2] | (amb[2] & gt)
            b = Dice.ifelse(lt, bma[1], b[1]), b[2] | (bma[2] & lt)
        end
        return a[1], a[2]
    end

    a = discrete(dice_disc), flip(0)
    b = discrete(dice_disc), flip(0)
    g = gcd(a, b)
    prob_equals(g[1], 2) & !g[2]
end

infer(code, :bdd)
