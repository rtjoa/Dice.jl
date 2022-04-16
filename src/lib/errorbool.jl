export DistBoolWithError

struct DistBoolWithError <: Dist{Bool}
    bit::DistBool
    error::DistBool
end

Base.:&(x::DistBoolWithError, y::DistBoolWithError) =
    DistBoolWithError(x.bit & y.bit, x.error | y.error)

Base.:|(x::DistBoolWithError, y::DistBoolWithError) =
    DistBoolWithError(x.bit | y.bit, x.error | y.error)
    
Base.:!(x::DistBoolWithError) = 
    DistBoolWithError(!x.bit, x.error)

prob_equals(x::DistBoolWithError, y::DistBoolWithError) =
    DistBoolWithError(prob_equals(x.bit, y.bit), x.error | y.error)

bools(b::DistBoolWithError) = [bools(b.bit); bools(b.error)]