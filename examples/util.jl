function dict_isapprox(d1, d2)
    if Set(keys(d1)) != Set(keys(d2))
        println("keys")
        return false
    end
    for k in keys(d1)
        if !(d1[k] ≈ d2[k])
            println("$(k) $(d1[k]) $(d2[k])")
            return false
        end
    end
    return true
end

function print_dict(d)
    println("$(typeof(d)) with $(length(d)) entries")
    widest = if length(d) > 0 maximum(length(string(k)) for (k, _) in d) else 0 end
    for (k, v) in d
        println("   $(rpad(k, widest, ' ')) => $(v)")
    end
end