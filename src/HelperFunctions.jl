# This file is part of JuliaFMI.
# Licensed under MIT: https://github.com/AnHeuermann/JuliaFMI/blob/master/LICENSE.txt

"""
    fmi2SetCallbackFunction!(fmu::FMU;stepFinished::Function=nothing,componentEnvironment::Function=nothing)

Helper function to add a function declared in julia to the CallbackFunctions struct on the fmu.

...
# Arguments
- `fmu::FMU`:
Optional args:
- `stepFinished::Function=nothing`:
- `componentEnvironment::fmi2ComponentEnvironment=nothing`:
...

# Example
'''
'''
"""
function fmi2SetCallbackFunctions!(fmu::FMU; stepFinished::T=nothing,
   componentEnvironment::T=nothing) where {T<:Union{Nothing,Function}, U<:Union{Nothing,AbstractFMI2ComponentEnvironment}}
   fmi2SetCallbackFunctions!(fmu.functions, stepFinished=stepFinished, componentEnvironment=componentEnvironment)
end

"""
    fmi2SetCallbackFunction!(functions::CallbackFunctions;stepFinished::Function=nothing,componentEnvironment::ComponentEnvironment=nothing,)where{ComponentEnvironment<:Function}

Helper function to add a function declared in julia to the CallbackFunctions struct.

...
# Arguments
- `functions::CallbackFunctions`:
Optional args:
- `stepFinished::Function=nothing`:
- `componentEnvironment::AbstractFMI2ComponentEnvironment=nothing`:
- `where{ComponentEnvironment<:Function}`:
...

# Example
'''
'''
"""
function fmi2SetCallbackFunctions!(functions::CallbackFunctions; stepFinished::T=nothing, componentEnvironment::U=nothing
    ) where {T<:Union{Nothing,Function}, U<:Union{Nothing,AbstractFMI2ComponentEnvironment}}
    if !isnothing(stepFinished)
        GC.@preserve cfunc = @cfunction($stepFinished, Cvoid, (Ref(U), Cint))
        functions.stepFinished = cfunc.ptr
    end
    if !isnothing(componentEnvironment)
        GC.@preserve cfunc = @cfunction($componentEnvironment, Cvoid, ())
        functions.componentEnvironment = cfunc.ptr
    end
end



