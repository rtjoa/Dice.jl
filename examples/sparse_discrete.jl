using Revise
using Dice

# Convert (value, weight) tuples to input for dice discrete distribution
# Example: unpack_sparse([(0, 0.2), (3, 0.8)]) => [0.2, 0.0, 0.0, 0.8]
function unpack_sparse(sparse::Vector{Tuple{Int,Float64}})
    dice_disc = zeros(maximum(val for (val, _) in sparse) + 1)
    for (val, weight) in sparse
        dice_disc[val + 1] = weight
    end
    return dice_disc
end

# Generate Dice code for P[X+Y = res] given distributions of X and Y
function gen_code1(
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

            ans = DistInt(dicecontext(), mb-1)
            for i=mb-1:-1:1
                ans = if flip(v[i]) DistInt(dicecontext(), i-1) else ans end
            end
            return ans
        end

        a = add_bits(discrete(discrete_dist1), 1)
        b = add_bits(discrete(discrete_dist2), 1)
        (a + b)[1]
    end
end

# Generate Dice code for P[X+Y = res] given distributions of X and Y
function gen_code2(
    sparse1::Vector{Tuple{Int,Float64}},
    sparse2::Vector{Tuple{Int,Float64}}
)
    @dice begin
        function discrete_from_sparse(sparse::Vector{Tuple{Int,Float64}})
            v = Dict()
            sum = 1.
            for (val, weight) in sparse
                v[val] = weight/sum
                sum -= weight
            end

            ans = DistInt(dicecontext(), last(sparse)[1])
            for i = (length(sparse) - 1):-1:1
                (val, weight) = sparse[i]
                ans = if flip(v[val]) DistInt(dicecontext(), val) else ans end
            end
            return ans
        end

        a = add_bits(discrete_from_sparse(sparse1), 1)
        b = add_bits(discrete_from_sparse(sparse2), 1)
        (a + b)[1]
    end
end

sparse1 = [(4, 0.3), (6, 0.2), (600, 0.5)] # 4 has probability 0.3, etc...
sparse2 = [(0, 0.2), (4, 0.3), (9, 0.5)]
total_time1 = 0. 
total_time2 = 0.

code = gen_code1(sparse1, sparse2)
bdd = compile(code)
println("Using a \"dense\" discrete function (original):")
println(num_flips(bdd), " flips")
@time one_res = infer(code, :bdd)

code = gen_code2(sparse1, sparse2)
bdd = compile(code)
println("Using a \"sparse\" discrete function:")
println(num_flips(bdd), " flips")
@time two_res = infer(code, :bdd)

# This check is stricter than need be. If fails, consider switching to isapprox
@assert one_res == two_res