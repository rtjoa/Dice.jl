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
