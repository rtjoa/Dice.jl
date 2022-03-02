using Revise
using Dice
using Dice: num_flips, num_nodes, to_dice_ir
using Distributions

code = @dice begin

    function uniform(b::Int) #b is the bitwidth
        x = Vector(undef, b)
        for i = b:-1:1
            x[i] = flip(0.5)
        end
        return DistInt(x)
    end

    function triangle(b::Int)
        s = false
        n = 2^b
        x = Vector(undef, b)
        y = Vector(undef, b)
        for i = b:-1:1
            x[i] = Dice.ifelse(s, flip(1/2), flip((3n - 2)/ (4n-4)))
            y[i] = flip((n-2)/(3n-2))
            s = s || (x[i] && !y[i])
            n = n/2
        end
        return DistInt(x)
    end

    function discrete(p::Vector{Float64})
        mb = length(p)
        # v = Vector(undef, mb)
        v = zeros(mb)
        sum = 1
        for i=1:mb
            if (p[i] ≈ sum)
                v[i] = 1
                break
            else
                v[i] = p[i]/sum
            end
            sum = sum - p[i]
            @assert v[i] >= 0
            @assert v[i] <= 1
        end

        ans = DistInt(dicecontext(), mb-1)
        for i=mb-1:-1:1
            ans = if flip(v[i]) DistInt(dicecontext(), i-1) else ans end
        end
        return ans
    end

    function anyline(bits::Int, p::Float64)
        # @assert p*2^bits >= 0
        # @assert p*2^bits <= 1
        ans = Dice.ifelse(flip(p*2^bits), add_bits(uniform(bits), 3), add_bits(triangle(bits), 3))
        return ans
    end

    function gaussian(whole_bits::Int, pieces::Int, mean::Float64, std::Float64)
        d = Normal(mean, std)
        start = 0
        interval_sz = 2^whole_bits/pieces
        bits = Int(log2(interval_sz))
    
        areas = Vector(undef, pieces)
        total_area = 0
    
        end_pts = Vector(undef, pieces)
        for i=1:pieces
            p1 = start + (i-1)*interval_sz
            p2 = p1 + 1
            p3 = start + (i)*interval_sz
            p4 = p3 - 1
    
            pts = [cdf.(d, p2) - cdf.(d, p1), cdf.(d, p3) - cdf.(d, p4)]
            end_pts[i] = pts
    
            areas[i] = (pts[1] + pts[2])*2^(bits - 1)
            total_area += areas[i]
        end

        rel_prob = areas/total_area
    
        b = discrete(rel_prob)
        a = end_pts[pieces][1]/areas[pieces]
        l = a > 1/2^bits

        ans = DistInt(dicecontext(), 2^whole_bits)
        @show whole_bits

        for i=pieces:-1:1
            a = end_pts[i][1]/areas[i]
            l = a > 1/2^bits
            ans = if prob_equals(b, i-1) 
                    (if l
                        (2^bits - 1 + (i - 1)*2^bits - anyline(bits, 2/2^bits - a))
                    else
                        (i - 1)*2^bits + 
                            anyline(bits, a)
                    end)[1]
                else
                    ans
                end  
        end
        return ans
    end

    mu = gaussian(8, 16, 2.0, 0.5) #0 to 32, 2 linear pieces, mu = 4, sigma = 1
    sigma = 1
    d = prob_equals((gaussian(6, 8, 8.0, 1.0) + mu)[1], 18)
    # d &= prob_equals((gaussian(6, 8, 8.0, 1.0) + mu)[1], 18)
    # ((n1 + n2)[1])
    # CondBool(10 > mu && mu > 7, d)
    # CondInt(mu, d)
    mu
end



bdd = compile(code)
num_flips(bdd)
num_nodes(bdd)
a = (infer(code, :bdd))
sum = 0
for i=1:16
    println(a[i])
    sum += a[i][1]*a[i][2]
    println(sum)
end
println(sum)
@assert infer(code, :bdd) ≈ 0.5

bdd = compile(code)
num_flips(bdd)
num_nodes(bdd)
infer(code, :bdd)