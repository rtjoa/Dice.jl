export DistITE

struct DistITE
    mgr
    cond::DistBool
    then
    elze
end

function group_infer(f, d::DistITE, prior, prior_p::Float64)
    group_infer(d.cond, prior, prior_p) do cond, cond_prior, cond_p
        if cond
            group_infer(f, d.then, cond_prior, cond_p)
        else
            group_infer(f, d.elze, cond_prior, cond_p)
        end
    end
end

bools(d::DistITE) = 
    vcat(bools(d.cond), bools(d.then)), bools(d.elze)
