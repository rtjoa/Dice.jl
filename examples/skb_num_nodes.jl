using Revise
using Dice
using Dice: num_flips, num_nodes, ifelse

# Number of nodes SKB needs to model a distribution on n bits
skb_num_nodes(n) = 2^n * (n - 1) + 2

function generate_code_skb(p::Vector{Float64})
    @dice begin
        function helper(i)
            if i == length(p)
                DistInt(i - 1)
            else
                ifelse(flip(p[i]/sum(p[i:length(p)])),
                    DistInt(dicecontext(), i-1),
                    helper(i+1))
            end
        end
        helper(1)
    end
end

function test_skb_num_nodes(p::Vector{Float64})
    code = generate_code_skb(p)
    bdd = compile(code)
    @assert infer(code, :bdd) ≈ p  # Verify correctness

    bdd_nodes = num_nodes(bdd, as_add=false)
    num_bits = round(Int, log2(length(p)))
    @assert bdd_nodes == skb_num_nodes(num_bits)  # Verify num bits

    println("SKB for a $(num_bits)-bit distribution: $(bdd_nodes) bdd nodes, $(num_flips(bdd)) flips")
end

dist_2 = [0.5, 0.5]
dist_4 = [0.1, 0.2, 0.3, 0.4]
dist_8 = [0.02, 0.04, 0.06, 0.08, 0.1, 0.12, 0.14, 0.44]
dist_16 = [0.005, 0.02, 0.03, 0.04, 0.05, 0.06, 0.07, 0.08, 0.09, 0.001, 0.11, 0.12, 0.13, 0.14, 0.022, 0.032]

for dist in [dist_2, dist_4, dist_8, dist_16]
    test_skb_num_nodes(dist)
end

# To investigate: the below discrete() fuction, which only meaningfully changes
# the order of flip introduction, takes fewer nodes (but still O(n2^n)).

#==                                       vvvvvvvvvvvvvvv diff
skb_num_nodes(n) = 2^n * (n - 1) + 2      - 2^(n - 1) + 1

function generate_code_skb(p::Vector{Float64})
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
        discrete(p)
    end
end
==#
