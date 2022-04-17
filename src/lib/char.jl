     
# Characters
export DistChar

# every single character. there aren't any others. :)
valid_chars = ['a':'z';'A':'Z';[' ',',','.','\'','"','!','?','(',')','\n']]
char_idx = Dict((c, i-1) for (i , c) in enumerate(valid_chars))

struct DistChar
    mgr
    i::DistInt
end

function DistChar(mgr, c::Char)
    DistChar(mgr, DistInt(mgr, char_idx[c]))
end

function infer(d::DistChar)
    ans = Dict{Char,Float64}()
    for c in valid_chars
        p = infer(prob_equals(d, c))
        if !(p ≈ 0)
            ans[c] = p
        end
    end
    ans
end

prob_equals(x::DistChar, y::DistChar) =
    prob_equals(x.i, y.i)

prob_equals(x::DistChar, y::Char) = 
    prob_equals(x, DistChar(x.mgr, y))

prob_equals(x::Char, y::DistChar) =
    prob_equals(y, x)

function ifelse(cond::DistBool, then::DistChar, elze::DistChar)
    DistChar(cond.mgr, ifelse(cond, then.i, elze.i))
end

function Base.:>(x::DistChar, y::DistChar)
    x.i > y.i
end
