using IRTools
using IfElse
using IRTools: Statement, BasicBlock, blocks, block!, IR, argument!, return!, branches, xcall, isconditional, Branch, arguments, branch!

##################
# Motivation
##################

# a function with control flow
function foo(x,y)
    z = y*0.5
    if x
        0.4 + z
    else
        0.1 + z
    end
    # mut = 0
    # if x
    #     # print("hi!")
    #     mut = y
    # end
    # mut + 1
end

function foo_float(x, y)
    # z = y * 0.5
    # w = 7
    # return x * (w+z) + (1-x) * (0.1 + z)
    IfElse.ifelse(x, foo(true, y), foo(false, y))
end
# control flow depending on `Bool`` guards works by default
foo(true, 0.1) # 0.45

# we would like control flow to be polymorphic, 
# for example to let `AbstractFloat` guards take the weighted average of both branches
IfElse.ifelse(guard::AbstractFloat, then, elze) = guard*then + (1-guard)*elze

# control flow depending on such `AbstractFloat` guards is not polymorphic by default
# foo(0.9, 0.1) # ERROR: TypeError: non-boolean (Float64) used in boolean context

##################
# Implementation
##################

function ir_to_function(ir, name=nothing)
    if name === nothing
        name = gensym("f")
    end
    @eval @generated function $(name)($([Symbol(:arg, i) for i = 1:length(arguments(ir))]...))
        return IRTools.Inner.build_codeinfo($ir)
    end
end

"Utility to translate between caller and function/block argument lists"
function mapvars(block)
    vmap = Dict() #? maps argument to parameter?
    callerargs = []
    lookup(x) = get!(vmap, x) do 
        if (x isa IRTools.Variable) 
            push!(callerargs, x) # add to block argument list
            argument!(block)
        else
            x # copy constants
        end
    end 
    callerargs, lookup, vmap
end

"Transform IR to have polymorphic control flow and add helper function IR"
function transform(ir)
    # ensure all cross-block variable use is through block arguments (make blocks functional)
    ir = IRTools.expand!(ir)
    helpers = []
    # point each conditional `br`` to its polymorphism block
    for i in eachindex(blocks(ir))
        block = IRTools.block(ir,i)
        branches = IRTools.branches(block) 

        # which variables are relevant to the remainder of the computation?
        args = [Set{IRTools.Variable}() for _ in 1:length(branches)]

        branches_rev = Branch[]
        for j in length(branches):-1:1
            # visit branches in reverse for data flow analysis and inserting branches
            br = branches[j]    
            push!(branches_rev, br)
        
            if isconditional(br) 
                @assert j < length(branches)
                cond = br.condition

                @assert cond isa IRTools.Variable # not sure if this will always be the case... (if false?)

                # add a polymorphism block to escape to when guard is non-boolean
                poly = block!(ir)

                # add arguments for guard, and variables that both branches depend on
                polyargs, lookup, vmap = mapvars(poly) 
                
                # look up all possible arguments for poly block
                lookup(cond) # guard is first argument
                foreach(lookup, br.args)
                foreach(lookup, args[j+1])                
                
                # put a new helper function on the TODO list for later
                helper = gensym("polybr_help")
                push!(helpers, (helper, copy(branches_rev), lookup, arguments(poly)))

                # call helper function for each branch, return polymorphic IfElse value
                branchargs = @view arguments(poly)[2:end]
                call_then = push!(poly, xcall(Base.invokelatest, helper, true, branchargs...))
                call_else = push!(poly, xcall(Base.invokelatest, helper, false, branchargs...))
                ite = push!(poly, xcall(IfElse.ifelse, lookup(cond), call_then, call_else))
                return!(poly, ite)
                
                # test whether guard is Bool, else go to polymorphism block
                isbool = push!(block, xcall(:isa, cond, :Bool))
                polybr = Branch(isbool, length(blocks(ir)), polyargs)
                push!(branches_rev, polybr)

                # data flow for condition 
                push!(args[j], br.condition)
            end

            # data flow for branch arguments
            for x in br.args 
                if x isa IRTools.Variable
                    push!(args[j],x)
                end
            end
            # make data flow cumulative
            if j < length(branches)
                union!(args[j], args[j+1])
            end
        end
        empty!(branches)
        append!(branches, reverse!(branches_rev))
    end

    # generate helper ir
    helpers_ir = map(helpers) do helper 
        sym, branches_rev, lookup1, caller_args = helper

        # add new block at the top
        help_ir = copy(ir)
        header = block!(help_ir, 1)

        # introduce header arguments for each caller argument
        _, lookup2, vmap = mapvars(header) 
        foreach(lookup2, caller_args)
        lookup(x) = lookup2(lookup1(x))

        # add branch statements translated to new variable vocabulary
        branches = IRTools.branches(header) 
        for i=length(branches_rev):-1:1
            br = branches_rev[i]
            br2 = Branch(lookup(br.condition), br.block+1, map(lookup, br.args))
            push!(branches, br2)
        end
        sym, help_ir
    end 

    ir, helpers_ir
end

"Generate a version of the method that has polymorphic control flow"
function gen_polybr_f(funtype, args...)
    gen_polybr_f_from_ir(IR(funtype, args...))
end

function gen_polybr_f_from_ir(ir)
    # print(ir)
    fir, helpers = transform(ir)
    println(fir)
    println(helpers)
    for (helpername, helperir) in helpers
        # cf https://github.com/FluxML/IRTools.jl/blob/master/src/eval.jl
        ir_to_function(helperir, helpername)
    end
    polybr = ir_to_function(fir)
    # hide first argument
    return (args...) -> polybr(nothing, args...)
end

##################
# Example
##################

# # apply source transformation
# foo2 = gen_polybr_f(typeof(foo), Any, Any)

# # `Bool` guards still work (and evaluate only a single branch)
# @assert foo2(true, 0.1) ≈ foo(true, 0.1) #0.45 # 0.45

# # `AbstractFloat`` guards now also work
# @assert foo2(0.4, 0.1) ≈ foo_float(0.4, 0.1) #0.27 #0.27

# # if the compiler can prove that the guard is `Bool`, the additional code disappears
# @code_typed foo2(true, 0.1)

# # if the compiler can prove that the guard is not `Bool``, 
# # there is no traditional control flow, 
# # only calls to helper functions for both branches and `ifelse`
# @code_typed foo2(0.4, 0.1)


##################
# While Loop Example
##################

# expected number of `true` sampled coins at start of list
# function num_true(x)
#     size = 0
#     while !isempty(x) && x[1]
#         x = x[2:end]
#         size += 1
#     end
#     size
# end

# # num_true([0.2, 0.9]) # ERROR: TypeError: non-boolean (Float64) used in boolean context

# num_true2 = gen_polybr_f(typeof(num_true), Vector{Float64})

# @assert num_true2([]) ≈ 0 #0
# @assert num_true2([0.2]) ≈ 0.2 #0.2
# @assert num_true2([0.2, 0.9]) ≈ 0.38 # 0.2*(1-0.9)*1 + 0.2*0.9*2 = 0.38
# num_true2([0.2, 0.9, 0.4]) ≈ 0.452 # 0.2*(1-0.9)*1 + 0.2*0.9*(1-0.4)*2 + 0.2*0.9*0.4*3 = 0.452
# num_true2([0.2, 0.9, 0.4, 0.0]) ≈ 0.452 # 0.2*(1-0.9)*1 + 0.2*0.9*(1-0.4)*2 + 0.2*0.9*0.4*3 = 0.452




# IR Skeleton
ir = IR()
block!(ir)
block!(ir)
block1 = blocks(ir)[1]
block2 = blocks(ir)[2]
block3 = blocks(ir)[3]
_1 = argument!(block1)
_2 = argument!(block1)
_3 = argument!(block1)
_4 = argument!(block1)
_5 = argument!(block2)
_6 = argument!(block3)
_7 = argument!(block3)

# Block 1
push!(branches(block1), Branch(_1, 3, [_3, _4]))
push!(branches(block1), Branch(nothing, 2, [_2]))

# Block 2
return!(block2, _5)

# Block 3
_8 = push!(block3, xcall(:+, _6, _7))
return!(block3, _8)

# idk how this got added but let's remove it
deleteat!(branches(block1), 1)  
# println()
# println(ir)

f = ir_to_function(ir)
gen_polybr_f_from_ir(ir)