# Strings
export DistString, prob_setindex

struct DistString
    mgr
    chars::Vector{DistChar}
    len::DistInt
end

function DistString(mgr, s::String)
    DistString(mgr, [DistChar(mgr, c) for c in s], DistInt(mgr, length(s)))
end

function group_infer(f, d::DistString, prior, prior_p::Float64)
    group_infer(d.len, prior, prior_p) do len, len_prior, len_p
        group_infer(d.chars[1:len], len_prior, len_p) do chars, chars_prior, chars_p
            f(join(chars), chars_prior, chars_p)
        end
    end
end

function prob_equals(x::DistString, y::DistString)
    res = prob_equals(x.len, y.len)
    for i = 1:min(length(x.chars), length(y.chars))
        res = res & ((i > x.len) | prob_equals(x.chars[i], y.chars[i]))
    end
    res
end

prob_equals(x::DistString, y::String) = 
    prob_equals(x, DistString(x.mgr, y))

prob_equals(x::String, y::DistString) =
    prob_equals(y, x)

function ifelse(cond::DistBool, then::DistString, elze::DistString)
    mb = max(length(then.chars), length(elze.chars))
    chars = Vector(undef, mb)
    for i = 1:mb
        if i > length(then.chars)
            chars[i] = elze.chars[i]
        elseif i > length(elze.chars)
            chars[i] = then.chars[i]
        else
            chars[i] = ifelse(cond, then.chars[i], elze.chars[i])
        end
    end
    DistString(cond.mgr, chars, ifelse(cond, then.len, elze.len))
end

# Quick int utilities for now. Will probably change when we figure out error handling
function safe_inc(d::DistInt)
    d_inc, carry = d + 1
    if issat(carry)
        return DistInt(d.mgr, [d_inc.bits;carry])
    end
    d_inc
end

function safe_add(x::DistInt, y::DistInt)
    if max_bits(x) > max_bits(y)
        x, y = y, x
    end
    z, carry = x + y
    while issat(carry)
        x, y = add_bits(x, 1), y
        z, carry = x + y
    end
    z
end

function Base.:+(s::DistString, c::DistChar)
    chars = Vector(undef, length(s.chars) + 1)
    for i = 1:length(s.chars)
        chars[i] = ifelse(prob_equals(s.len, i-1), c, s.chars[i])
    end
    chars[length(s.chars) + 1] = c
    DistString(s.mgr, chars, safe_inc(s.len))
end

Base.:+(s::DistString, c::Char) =
    s + DistChar(s.mgr, c)

# Consider divide and conquer? Reverse order?
function Base.getindex(s::DistString, idx::DistInt)
    res = s.chars[1]
    for i = 2:length(s.chars)
        res = ifelse(prob_equals(idx, i), s.chars[i], res)
    end
    res
end

function prob_setindex(s::DistString, idx::DistInt, c::DistChar)
    chars = collect(s.chars)
    for i = 1:length(s.chars)
        chars[i] = ifelse(prob_equals(idx, i), c, s.chars[i])
    end
    DistString(s.mgr, chars, s.len)
end

# Only works in straightline code, needs more code transformation, non-functional ifs, etc.
# function Base.setindex!(s::DistString, c::DistChar, idx::DistInt)
#     for i = 1:length(s.chars)
#         s.chars[i] = ifelse(prob_equals(idx, i), c, s.chars[i])
#     end
# end

function Base.:+(s::DistString, t::DistString)
    len = safe_add(s.len, t.len)
    chars = Vector(undef, length(s.chars) + length(t.chars))
    for i = 1:length(chars)
        if i <= length(s.chars)
            chars[i] = ifelse(s.len > (i - 1), s.chars[i], t[(i - s.len)[1]])
        else
            # Subtraction could overflow, but we don't care - accessing chars beyond len is UB
            chars[i] = t[(i - s.len)[1]]
        end
    end
    DistString(s.mgr, chars, len)
end

Base.:+(s::DistString, t::String) =
    s + DistString(s.mgr, t)
    
Base.:+(s::String, t::DistString) =
    DistString(t.mgr, s) + t
