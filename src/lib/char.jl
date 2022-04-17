     
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

function group_infer(f, d::DistChar, prior, prior_p::Float64)
    group_infer(d.i, prior, prior_p) do n, new_prior, p
        f(valid_chars[n+1], new_prior, p)
    end
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
