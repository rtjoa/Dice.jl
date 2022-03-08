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

# Naively calculate P[gcd(X, Y) = res] given distributions of X and Y
function gcd_enumeration(
    sparse1::Vector{Tuple{Int,Float64}},
    sparse2::Vector{Tuple{Int,Float64}},
    res::Int
)
    total_weight = 0
    for (val1, weight1) in sparse1
        for (val2, weight2) in sparse2
            if gcd(val1, val2) == res
                total_weight += weight1 * weight2
            end
        end
    end
    return total_weight
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

        # Subtraction-based GCD
        # https://en.wikipedia.org/wiki/Euclidean_algorithm#Implementations
        function dice_gcd(a::Tuple{DistInt, DistBool}, b::Tuple{DistInt, DistBool})
            # Swap if a < b to handle cases where a=0 and b!=0
            lt = b[1] > a[1]
            t = a
            a = Dice.ifelse(lt, b[1], a[1]), Dice.ifelse(lt, b[2], a[2])
            b = Dice.ifelse(lt, t[1], b[1]), Dice.ifelse(lt, t[2], b[2])
            
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

        a = discrete(discrete_dist1), flip(0)
        b = discrete(discrete_dist2), flip(0)
        g = dice_gcd(a, b)
        prob_equals(g[1], res) & !g[2]
    end
end

all_pass = true
function test(sparse::Vector{Tuple{Int,Float64}})
    for res = 0:10
        code = code_gcd(sparse, sparse, res)
        bdd = compile(code)
        dice_p = infer(code, :bdd)
        naive_p = gcd_enumeration(sparse, sparse, res)
        if !isapprox(dice_p, naive_p)
            global all_pass = false
            println("FAIL. ", sparse, " ", res, " Expected: ", naive_p, " Got: ", dice_p)
        end
    end
end

sparse1 = [(4, 0.3), (6, 0.2), (9, 0.5)] # 4 has probability 0.3, etc...
sparse2 = [(0, 0.2), (4, 0.3), (6, 0.5)]
test(sparse1)
test(sparse2)
if all_pass
    println("ALL TESTS PASSED")
end