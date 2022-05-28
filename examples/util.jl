using Dice

function discrete(p)
    @assert sum(p) ≈ 1

    mb = length(p)
    v = Vector(undef, mb)
    p_sum = 1
    for i in 1:mb
        v[i] = p[i] / p_sum
        p_sum = p_sum - p[i]
    end

    ans = DistInt(mb-1)
    for i=mb-1:-1:1
        ans = Dice.ifelse(flip(v[i]), DistInt(i-1), ans)
    end
    return ans
end

function uniform(domain::AbstractVector{Int})
    p = zeros(maximum(domain) + 1)
    for x in domain
        p[x + 1] = 1/length(domain)
    end
    discrete(p)
end

function print_dict(d)
    d = sort([(join(x), val) for (x, val) in d], by= xv -> -xv[2])  # by decreasing probability
    println("$(typeof(d)) with $(length(d)) entries")
    widest = if length(d) > 0 maximum(length(string(k)) for (k, _) in d) else 0 end
    for (k, v) in d
        println("   $(rpad(k, widest, ' ')) => $(v)")
    end
end

function get_char_freqs_from_url(corpus_url)
    corpus = join(c for c in lowercase(read(download(corpus_url), String)) if c in valid_chars)
    counts = Dict([(c, 0) for c in valid_chars])
    for c in corpus
        counts[c] += 1
    end
    [counts[c]/length(corpus) for c in valid_chars]
end
