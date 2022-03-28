using Revise
using Dice

# Convert (value, weight) tuples to input for dice discrete distribution
# Example: unpack_sparse([(0, 0.2), (3, 0.8)]) => [0.2, 0, 0, 0.8]
function unpack_sparse(sparse::Vector{Tuple{Int,Float64}})
    dice_disc = zeros(maximum(val for (val, _) in sparse) + 1)
    for (val, weight) in sparse
        dice_disc[val + 1] = weight
    end
    return dice_disc
end

# Naively calculate PMF of gcd(X, Y) given distributions of X and Y
function gcd_enumeration(
    sparse1::Vector{Tuple{Int,Float64}},
    sparse2::Vector{Tuple{Int,Float64}}
)
    gcd_dist = Dict()
    for (val1, weight1) in sparse1
        for (val2, weight2) in sparse2
            res = gcd(val1, val2)
            gcd_dist[res] = get(gcd_dist, res, 0) + weight1 * weight2
        end
    end
    return gcd_dist
end

# Generate Dice code for P[gcd(X, Y) = res] given distributions of X and Y
function code_gcd(
    sparse1::Vector{Tuple{Int,Float64}},
    sparse2::Vector{Tuple{Int,Float64}},
    res::Int
)
    discrete_dist1 = unpack_sparse(sparse1)
    discrete_dist2 = unpack_sparse(sparse2)
    @dice begin
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

        # https://en.wikipedia.org/wiki/Euclidean_algorithm#Implementations
        function dice_gcd(a::DistInt, b::DistInt)
            a = a, flip(0)
            b = b, flip(0)
            for _ = 1 : 1 + max_bits(b[1]) ÷ log2(MathConstants.golden)
                b_zero = prob_equals(b[1], 0)
                t = b
                amb = (a[1] % b[1])
                b = Dice.ifelse(b_zero, b[1], amb[1]), Dice.ifelse(b_zero, b[2], amb[2] | a[2] | b[2])
                a = Dice.ifelse(b_zero, a[1], t[1]), Dice.ifelse(b_zero, a[2], t[2])
            end
            return a[1], a[2]
        end

        a = discrete(discrete_dist1)
        b = discrete(discrete_dist2)
        g = dice_gcd(a, b)
        prob_equals(g[1], res) & !g[2]
    end
end

function test(sparse::Vector{Tuple{Int,Float64}})
    gcd_dist = gcd_enumeration(sparse, sparse)
    for res in Set(Iterators.flatten((keys(gcd_dist), 0:1)))
        code = code_gcd(sparse, sparse, res)
        bdd = compile(code)
        dice_p = infer(code, :bdd)
        @assert dice_p ≈ get(gcd_dist, res, 0)
    end
end

test([(4, 0.3), (6, 0.2), (9, 0.5)])  # 4 has probability 0.3, etc...
test([(0, 0.2), (4, 0.3), (6, 0.5)])
test([(0, 0.1), (2, 0.2), (3, 0.7)])
test([(0, 0.1), (8, 0.2), (13, 0.7)])
test([(0, 0.1), (34, 0.2), (55, 0.7)])
# test([(144, 0.1), (233, 0.2), (610, 0.3), (987, 0.4)])  # too slow...