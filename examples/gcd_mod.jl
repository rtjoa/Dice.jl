using Revise
using Dice
using Dice: num_flips, num_nodes

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
    sparse2::Vector{Tuple{Int,Float64}}
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

            ans = DistInt(mb-1)
            for i=mb-1:-1:1
                ans = if flip(v[i]) DistInt(i-1) else ans end
            end
            return ans
        end

        # https://en.wikipedia.org/wiki/Euclidean_algorithm#Implementations
        function dice_gcd(a::DistInt, b::DistInt)
            for _ = 1 : 1 + max_bits(b) ÷ log2(MathConstants.golden)
                b_zero = prob_equals(b, 0)
                a, b = Dice.ifelse(b_zero, a, b), Dice.ifelse(b_zero, b, a % b)
            end
            return a
        end

        a = discrete(discrete_dist1)
        b = discrete(discrete_dist2)
        g = dice_gcd(a, b)
    end
end

function test(sparse::Vector{Tuple{Int,Float64}})
    gcd_dist = gcd_enumeration(sparse, sparse)
    code = code_gcd(sparse, sparse)
    bdd = compile(code)
    dice_p = infer(bdd)
    @assert infer(bdd.error) == 0
    for res in Set(Iterators.flatten((keys(gcd_dist), 0:1)))
        @assert dice_p[res + 1] ≈ get(gcd_dist, res, 0)
    end
end

# test([(4, 0.3), (6, 0.2), (9, 0.5)])  # 4 has probability 0.3, etc...
# test([(0, 0.2), (4, 0.3), (6, 0.5)])
# test([(0, 0.1), (2, 0.2), (3, 0.7)])
# test([(0, 0.1), (8, 0.2), (13, 0.7)])
# test([(0, 0.1), (34, 0.2), (55, 0.7)])
test([(144, 0.1), (233, 0.2), (610, 0.5), (987, 0.05), (988, 0.05), (989, 0.05), (990, 0.05)])