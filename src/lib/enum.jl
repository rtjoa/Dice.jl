
struct Enum
    cases::Vector{Any}
    case_to_i::Dict{Any, Int}
    hash::UInt64
end

function Enum(cases)
    case_to_i = Dict((v,i) for (i, v) in enumerate(cases))
    Enum(cases, case_to_i, hash(cases))
end

function Base.:(==)(x::Enum, y::Enum)
    return x.hash = y.hash
end

struct DistEnum
    mgr
    enum::Enum
    i::DistInt
end

function DistEnum(mgr, enum::Enum, case)
    @assert haskey(enum.case_to_i, case)
    DistEnum(mgr, enum, DistInt(mgr, enum.case_to_i[case]))
end