export infer, group_infer

# Efficient infer for any distribution for which group_infer is defined
function infer(d)
    ans = Dict()
    group_infer(d, true, 1.0) do assignment, _, p
        ans[assignment] = p
    end
    ans
end

# We infer a vector if we can infer the elements
function group_infer(f, vec::AbstractVector, prior, prior_p::Float64)
    if length(vec) == 0
        f([], prior, prior_p)
        return
    end
    group_infer(vec[1], prior, prior_p) do assignment, new_prior, new_p
        rest = @view vec[2:length(vec)]
        group_infer(rest, new_prior, new_p) do rest_assignment, rest_prior, rest_p
            assignments = vcat([assignment], rest_assignment)  # todo: try linkedlist instead
            f(assignments, rest_prior, rest_p)
        end
    end
end

# Workhorse for group_infer; it's DistBools all the way down
function group_infer(f, d::DistBool, prior, prior_p::Float64)
    new_prior = d & prior
    p = infer(new_prior)
    if p != 0
        f(true, new_prior, p)
    end
    if !(p ≈ prior_p)
        f(false, !d & prior, prior_p - p)
    end
end
