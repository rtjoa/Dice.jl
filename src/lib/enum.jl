export DiceEnum, DistEnum

struct DiceEnum
    cases::Vector{Any}
    case_to_i::Dict{Any, Int}
    hash::UInt64
end

function DiceEnum(cases)
    case_to_i = Dict((v,i-1) for (i, v) in enumerate(cases))
    DiceEnum(cases, case_to_i, hash(cases))
end

function Base.:(==)(x::DiceEnum, y::DiceEnum)
    return x.hash == y.hash
end

struct DistEnum
    mgr
    enum::DiceEnum
    i::DistInt
end

function DistEnum(mgr, enum::DiceEnum, case)
    @assert haskey(enum.case_to_i, case)
    DistEnum(mgr, enum, DistInt(mgr, enum.case_to_i[case]))
end

function group_infer(f, d::DistEnum, prior, prior_p::Float64)
    group_infer(d.i, prior, prior_p) do n, new_prior, p
        f(d.enum.cases[n+1], new_prior, p)
    end
end

function prob_equals(x::DistEnum, y::DistEnum)
    @assert x.enum == y.enum
    prob_equals(x.i, y.i)
end

function prob_equals(x::DistEnum, y)
    @assert y in x.enum.case_to_i
    prob_equals(x, DistEnum(x.mgr, x.enum, y))
end

function prob_equals(x, y::DistEnum)
    @assert x in y.enum.case_to_i
    prob_equals(DistEnum(y.mgr, y.enum, x), y)
end

function ifelse(cond::DistBool, then::DistEnum, elze::DistEnum)
    @assert then.enum == elze.enum
    DistEnum(cond.mgr, then.enum, ifelse(cond, then.i, elze.i))
end

bools(c::DistEnum) =
    bools(c.i)
