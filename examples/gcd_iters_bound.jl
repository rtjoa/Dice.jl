# Number of iterations Euclidean Algorithm needs for gcd(a, b)
function gcd_iters(a, b)
    iters = 0
    while b != 0
        iters += 1
        a, b = b, a % b
    end
    return iters
end

# Number of bits needed to represent some non-negative n
function num_bits(n)
    ct = 1
    n >>= 1
    while n != 0
        n >>= 1
        ct += 1
    end
    return ct
end

# Test num_bits
num_bits_tests = [(0, 1), (1, 1), (2, 2), (3, 2), (4, 3), (5, 3), (6, 3), (7, 3), (8, 4)]
for (num, ans) in num_bits_tests
    @assert num_bits(num) == ans
end

small_numbers = collect(0:2^12-1)
fibs = [0, 1] # Fibonacci numbers
for i in 1:90
    push!(fibs, fibs[length(fibs) - 1] + fibs[length(fibs)])
end
two_powers = [2 ^ x for x in 1 : 60] 
mersenne_numbers = [x - 1 for x in two_powers]

operands_of_interest = Set(vcat(small_numbers, fibs, two_powers, mersenne_numbers))

# Verify that for all operands of interest, num iters is <= 1 + num_bits(y) ÷ log2_of_φ (note floor divison)
log2_of_φ = log2(MathConstants.golden)
for x in operands_of_interest, y in operands_of_interest
# for x in 0:2^16-1, y in 0:2^16-1
    iters = gcd_iters(x, y)
    if 1 + num_bits(y) ÷ log2_of_φ < iters
        println("gcd($(x), $(y)) takes $(iters) iters (max bits: $(max_bits), ratio: $(iters / max_bits))")
    end
    @assert iters <= 1 + num_bits(y) ÷ log2_of_φ 
end
println("Done")

#==
Operands where (# of iterations)/(max_bits) = 1.5 (none have a higher ratio, up through 14 bits)
Note that all are sequential fibonacci #s
gcd(2, 3) takes 3 iters (max bits: 2)
gcd(8, 13) takes 6 iters (max bits: 4)
gcd(34, 55) takes 9 iters (max bits: 6)
gcd(144, 233) takes 12 iters (max bits: 8)
gcd(610, 987) takes 15 iters (max bits: 10)


https://stackoverflow.com/questions/9060816/running-time-of-euclids-gcd-algorithm
y = second arg
b = # of bits in second arg
bound is:
1 + log(φ, y)
1 + log(φ, 2^b - 1)
1 + log(2, 2^b - 1)/log(2, φ)
1 + b/log(2, φ)

experimentally verified for all numbers representable in 16 bits

==#