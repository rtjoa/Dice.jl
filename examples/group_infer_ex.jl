code = @dice begin
    s = if flip(3/5) DistString("sand") else DistString("san") end
    s = if flip(2/3) s + 'd' else s end
    t = if flip(1/10) DistString("wich") else DistString("box") end
    s + t
end
bdd = compile(code)
infer(bdd)
#==
Dict{Any, Any} with 6 entries:
  "sanbox"    => 0.12
  "sandwich"  => 0.0466667
  "sanddbox"  => 0.36
  "sanwich"   => 0.0133333
  "sandbox"   => 0.42
  "sanddwich" => 0.04
==#

code = @dice begin
    hi_bye = if flip(3/5) DistString("hi") else DistString("bye") end
    is_three = flip(1/2)
    three_seven = if is_three DistInt(3) else DistInt(7) end
    [hi_bye, [is_three, three_seven]]
end
bdd = compile(code)
infer(bdd)
#==
Dict{Any, Any} with 4 entries:
  Any["hi", Any[true, 3]]   => 0.3
  Any["hi", Any[false, 7]]  => 0.3
  Any["bye", Any[true, 3]]  => 0.2
  Any["bye", Any[false, 7]] => 0.2
==#
