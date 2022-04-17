using Dice

code = @dice begin
    # function choose_string(s::Vector{Tuple{String, Float64}})
    #     s
    # end
    s = if flip(3/5) DistString("sand") else DistString("san") end
    s = if flip(1/2) prob_append(s, 'd') else s end
    t = if flip(1/10) DistString("wich") else DistString("box") end
    st = prob_concat(s, t)
    prob_equals(st, "sandwich")
end

exp = 2/25