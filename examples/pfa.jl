using Dice

machine = Dict([  # List of transitions
    (1,  # Start state of edge
        [(2, 'm', 0.7),  # End state of edge, character, probability of taking
        (3, 'a', 0.3)]),
    (2,
        [(3, 'n', 0.2),
        (4, 'a', 0.8)]),
    (3,
        [(2, 'a', 1.0)])
])

start = 1
num_steps = 7

code = @dice begin
    state = DistInt(start)
    str = DistString("")
    for _ in 1:num_steps
        # Consider each state we can be at
        for (state1, transitions) in machine
            # Consider each transition we can take from this state
            total_p = 1.0
            cand_state = DistInt(last(transitions)[1])
            cand_str = str + last(transitions)[2]
            have_taken = DistBool(dicecontext(), false)
            for (state2, c, p) in @view transitions[1:length(transitions) - 1]
                take = !have_taken & flip(p/total_p)
                have_taken = have_taken | take
                total_p -= p
                cand_state = if take DistInt(state2) else cand_state end
                cand_str = if take str + c else cand_str end
            end
            state_matches = prob_equals(state, state1)
            # Only update if our current state matches state1
            # Note that this means we do not update if we are at the end
            state = if state_matches cand_state else state end
            str = if state_matches cand_str else str end
        end
    end
    [state, str]
end
bdd = compile(code)
dist = infer(bdd)
@show sort(dist, by= x->-x, byvalue=true)  # Display in order of decreasing probability
#==
OrderedCollections.OrderedDict{Any, Any} with 13 entries:
  Any[4, "ma"]            => 0.56
  Any[4, "aaa"]           => 0.24
  Any[4, "mnaa"]          => 0.112
  Any[4, "aanaa"]         => 0.048
  Any[4, "mnanaa"]        => 0.0224
  Any[4, "aananaa"]       => 0.0096
  Any[4, "mnananaa"]      => 0.00448
  Any[4, "aanananaa"]     => 0.00192
  Any[4, "mnanananaa"]    => 0.000896
  Any[4, "aananananaa"]   => 0.000384
  Any[4, "mnananananaa"]  => 0.0001792
  Any[2, "aananananana"]  => 9.6e-5
  Any[2, "mnananananana"] => 4.48e-5
==#