# This file is part of JuliaFMI.
# Licensed under MIT: https://github.com/AnHeuermann/JuliaFMI/blob/master/LICENSE.txt

# This file contains wrapper to call FMI functions.

# ##############################################################################
# Inquire Platform and Version Number of Header Files
# ##############################################################################

using Libdl

"""
```
    fmi2GetTypesPlatform(libHandle::Ptr{Nothing}) -> String

    fmi2GetTypesPlatform(fmu::FMU) -> String
```
Returns string to uniquely identify the "fmi2TypesPlatform.h" header file
used for compilation of the functions of the FMU.
Standard type is "default".
"""
function fmi2GetTypesPlatform(libHandle::Ptr{Nothing})
    func = dlsym(libHandle, :fmi2GetTypesPlatform)

    typesPlatform = ccall(
      func,
      Cstring,
      ()
      )

    return unsafe_string(typesPlatform)
end

function fmi2GetTypesPlatform(fmu::FMU)
    return fmi2GetTypesPlatform(fmu.libHandle)
end


"""
```
    function fmi2GetVersion(libHandle::Ptr{Nothing}) -> String

    function fmi2GetVersion(fmu::FMU) -> String
```
Returns the version of the "fmi2Functions.h" header file which was used to
compile the functions of the FMU.
Standard type is "2.0"
"""
function fmi2GetVersion(libHandle::Ptr{Nothing})
    func = dlsym(libHandle, :fmi2GetVersion)

    version = ccall(
      func,
      Cstring,
      ()
      )

    return unsafe_string(version)
end

function fmi2GetVersion(fmu::FMU)
    return fmi2GetVersion(fmu.libHandle)
end


# ##############################################################################
# Creation, Destruction and Logging of FMU Instances
# ##############################################################################

"""
```
    fmi2Instantiate(fmu::FMU)

    fmi2Instantiate(libHandle::Ptr{Nothing}, instanceName::String, fmuType::FMUType, fmuGUID::String, fmuResourceLocation::String, functions::CallbackFunctions, visible::Bool, loggingOn::Bool)
```
Returns a new instance of a FMU component.
If a null pointer is returned instantiation failed.

## Example calls
```
julia> fmu = loadFMU("path\\\\to\\\\fmu\\\\helloWorld.fmu")
julia> fmu = fmi2Instantiate(fmu)
```
or
```
julia> fmu = loadFMU("path\\\\to\\\\fmu\\\\helloWorld.fmu")
julia> fmi2Component = fmi2Instantiate(fmu.libHandle, fmu.instanceName,
modelExchange, fmu.fmuGUID, fmu.fmuResourceLocation, fmu.callbackFunctions, false)
```
"""
function fmi2Instantiate(libHandle::Ptr{Nothing}, instanceName::String,
    fmuType::JuliaFMI.FMUType, fmuGUID::String, fmuResourceLocation::String,
    functions::CallbackFunctions, visible::Bool=true, loggingOn::Bool=false)

    func = dlsym(libHandle, :fmi2Instantiate)

    fmi2Component = ccall(
      func,
      Ptr{Cvoid},
      (Cstring, Cint, Cstring, Cstring, Ptr{CallbackFunctions}, Cint, Cint),
      instanceName, fmuType, fmuGUID, fmuResourceLocation,
      Ref(functions), visible, loggingOn
      )

    if fmi2Component == C_NULL
        throw(FMI2Error("Could not instantiate FMU"))
    end

    return fmi2Component
end

function fmi2Instantiate!(fmu::FMU; visible::Bool=true, loggingOn::Bool=false)
    fmu.fmi2Component = fmi2Instantiate(fmu.libHandle, fmu.instanceName,
        fmu.fmuType, fmu.fmuGUID, fmu.fmuResourceLocation,
        fmu.functions,  visible, loggingOn)

    fmu.modelState = modelInstantiated

    return fmu
end


"""
```
    fmi2FreeInstance(libHandle::Ptr{Nothing}, fmi2Component::Ptr{Nothing})
```
Disposes the given instance, unloads the loaded model, and frees all the
allocated memory and other resources that have been allocated by the functions
of the FMU interface. If a null pointer is provided for `fmi2Component`,
the function call is ignored (does not have an effect).
"""
function fmi2FreeInstance(libHandle::Ptr{Nothing}, fmi2Component::Ptr{Nothing})

    func = dlsym(libHandle, :fmi2FreeInstance)

    ccall(
        func,
        Cvoid,
        (Ptr{Cvoid},),
        fmi2Component
        )
end

function fmi2FreeInstance(fmu::FMU)

    fmi2FreeInstance(fmu.libHandle, fmu.fmi2Component)
end


"""
```
    function fmi2SetDebugLogging(libHandle::Ptr{Nothing}, fmi2Component::Ptr{UInt}, loggingOn::Bool, [nCategories::Int], [categories::Array{String,1}])

    function fmi2SetDebugLogging(fmu::FMU, loggingOn::Bool, [nCategories::Int], [categories::Array{String,1}])
```
Enable or disable debug logging.
If optional argument `categories` is provided and `loggingOn=true` then only
debug messages according to the categories argument shall be printed via the
logger function.
`nCategories` has to be the length of `categories` an is optional as well.
"""
function fmi2SetDebugLogging(libHandle::Ptr{Nothing},
    fmi2Component::Ptr{Nothing}, loggingOn::Bool)

    func = dlsym(libHandle, :fmi2SetDebugLogging)

    status = ccall(
        func,
        Cuint,
        (Ptr{Cvoid}, Cint, Csize_t, Ptr{Cstring}),
        fmi2Component, loggingOn, 0, C_NULL
        )

    if status != 0
        throw(fmiError(status))
    end
end

function fmi2SetDebugLogging(libHandle::Ptr{Nothing},
    fmi2Component::Ptr{Nothing}, loggingOn::Bool, nCategories::UInt,
    categories::Array{String,1})

    if length(categories) != nCategories
        throw(DimensionMismatch("nCategories=$nCategories does not match length(categories)=$(length(categories))"))
    end

    func = dlsym(libHandle, :fmi2SetDebugLogging)

    status = ccall(
        func,
        Cuint,
        (Ptr{Cvoid}, Cint, Csize_t, Ptr{Cstring}),
        fmi2Component, loggingOn, nCategories, categories
        )

    if status != 0
        throw(fmiError(status))
    end
end

function fmi2SetDebugLogging(libHandle::Ptr{Nothing},
    fmi2Component::Ptr{Nothing}, loggingOn::Bool, categories::Array{String,1})

    fmi2SetDebugLogging(libHandle, fmi2Component, logginOn,
        UInt(length(categories)), categories)
end

function fmi2SetDebugLogging(libHandle::Ptr{Nothing},
    fmi2Component::Ptr{Nothing}, loggingOn::Bool, nCategories::Int,
    categories::Array{String,1})

    fmi2SetDebugLogging(libHandle, fmi2Component, loggingOn, UInt(nCategories), categories)
end

function fmi2SetDebugLogging(fmu::FMU, loggingOn::Bool, nCategories::Int,
    categories::Array{String,1})

    fmi2SetDebugLogging(fmu.libHandle, fmu.fmi2Component, loggingOn,
        nCategories, categories)
end

function fmi2SetDebugLogging(fmu::FMU, loggingOn::Bool, nCategories::UInt,
    categories::Array{String,1})

    fmi2SetDebugLogging(fmu.libHandle, fmu.fmi2Component, loggingOn,
        nCategories, categories)
end

function fmi2SetDebugLogging(fmu::FMU, loggingOn::Bool,
    categories::Array{String,1})

    fmi2SetDebugLogging(fmu.libHandle, fmu.fmi2Component, loggingOn,
        UInt(length(categories)), categories)
end

function fmi2SetDebugLogging(fmu::FMU, loggingOn::Bool)

    fmi2SetDebugLogging(fmu.libHandle, fmu.fmi2Component, loggingOn)
end


# ##############################################################################
# Initialization, Termination, and Resetting an FMU
# ##############################################################################

"""
```
    fmi2SetupExperiment(libHandle::Ptr{Nothing}, fmi2Component::Ptr{Nothing}, [toleranceDefined::Bool], [tolerance::Real], startTime::Real, [stopTimeDefined::Bool], [stopTime::Real])

    fmi2SetupExperiment(fmu::FMU, [toleranceDefined::Bool], [tolerance::Real], startTime::Real, [stopTimeDefined::Bool], [stopTime::Real])
```
Informs the `FMU` to setup the experiment. This function can be called after
`fmi2Instantiate` and before `fmi2EnterInitializationMode` is called.
"""
function fmi2SetupExperiment(libHandle::Ptr{Nothing},
    fmi2Component::Ptr{Nothing}, toleranceDefined::Bool, tolerance::Real,
    startTime::Real, stopTimeDefined::Bool=false, stopTime::Real=startTime+1)

    func = dlsym(libHandle, :fmi2SetupExperiment)

    status = ccall(
        func,
        Cuint,
        (Ptr{Cvoid}, Cint, Cdouble, Cdouble, Cint, Cdouble),
        fmi2Component, toleranceDefined, tolerance, startTime, stopTimeDefined,
        stopTime
        )

    if status != 0
        throw(fmiError(status))
    end
end

function fmi2SetupExperiment(libHandle::Ptr{Nothing},
    fmi2Component::Ptr{Nothing}, startTime::Real, stopTimeDefined::Bool=false,
    stopTime::Real=startTime+1)

    return fmi2SetupExperiment(libHandle, fmi2Component, false, 1e-8,
        startTime, stopTimeDefined, stopTime)
end

function fmi2SetupExperiment(fmu::FMU, toleranceDefined::Bool, tolerance::Real,
    startTime::Real, stopTimeDefined::Bool=false, stopTime::Real=startTime+1)

    return fmi2SetupExperiment(fmu.libHandle, fmu.fmi2Component,
        toleranceDefined, tolerance, startTime, stopTimeDefined, stopTime)
end

function fmi2SetupExperiment(fmu::FMU, startTime::Real,
    stopTimeDefined::Bool=false, stopTime::Real=startTime+1)

    return fmi2SetupExperiment(fmu.libHandle, fmu.fmi2Component,
        false, 1e-8, startTime, stopTimeDefined, stopTime)
end


"""
```
    fmi2EnterInitializationMode(libHandle::Ptr{Nothing}, fmi2Component::Ptr{Nothing})

    fmi2EnterInitializationMode(fmu::FMU)
```
Informs the FMU to enter Initialization Mode. Before calling this function,
function `fmi2SetupExperiment` must be called at least once.
All variables with attribute `initial = "exact"` or `initial="approx"` can be
set with the `fmi2SetReal`, `fmi2SetInteger`, `fmi2SetBoolean` and
`fmi2SetString` functions.
"""
function fmi2EnterInitializationMode(libHandle::Ptr{Nothing},
    fmi2Component::Ptr{Nothing})

    func = dlsym(libHandle, :fmi2EnterInitializationMode)

    status = ccall(
        func,
        Cuint,
        (Ptr{Cvoid},),
        fmi2Component
        )

    if status != 0
        throw(fmiError(status))
    end
end

function fmi2EnterInitializationMode(fmu::FMU)

    return fmi2EnterInitializationMode(fmu.libHandle, fmu.fmi2Component)
end


"""
```
    fmi2ExitInitializationMode(libHandle::Ptr{Nothing}, fmi2Component::Ptr{Nothing})

    fmi2ExitInitializationMode(fmu::FMU)
```
Informs the FMU to exit Initialization Mode.
"""
function fmi2ExitInitializationMode(libHandle::Ptr{Nothing},
    fmi2Component::Ptr{Nothing})

    func = dlsym(libHandle, :fmi2ExitInitializationMode)

    status = ccall(
        func,
        Cuint,
        (Ptr{Cvoid},),
        fmi2Component
        )

    if status != 0
        throw(fmiError(status))
    end
end

function fmi2ExitInitializationMode(fmu::FMU)

    return fmi2ExitInitializationMode(fmu.libHandle, fmu.fmi2Component)
end


"""
```
    fmi2Terminate(libHandle::Ptr{Nothing}, fmi2Component::Ptr{Nothing})

    fmi2Terminate(fmu::FMU)
```
Informs the FMU that the simulation run is terminated. After calling this
function, the final values of all variables can be inquired with the
`fmi2GetReal!`, `fmi2GetInteger!`, `fmi2GetBoolean!` and `fmi2GetString!`
functions. It is not allowed to call this function after one of the FMI
functions returned with a status `fmi2Error` or `fmi2Fatal`.
"""
function fmi2Terminate(libHandle::Ptr{Nothing},
    fmi2Component::Ptr{Nothing})

    func = dlsym(libHandle, :fmi2Terminate)

    status = ccall(
        func,
        Cuint,
        (Ptr{Cvoid},),
        fmi2Component
        )

    if status != 0
        throw(fmiError(status))
    end
end

function fmi2Terminate(fmu::FMU)

    return fmi2Terminate(fmu.libHandle, fmu.fmi2Component)
end


"""
```
    fmi2Reset(libHandle::Ptr{Nothing}, fmi2Component::Ptr{Nothing})

    fmi2Reset(fmu::FMU)
```
Resets the FMU after a simulation run. The FMU goes into the same state as if
`fmi2Instantiate` would have been called. All variables have their default
values. Before starting a new run, `fmi2SetupExperiment` and
`fmi2EnterInitializationMode` have to be called.
"""
function fmi2Reset(libHandle::Ptr{Nothing},
    fmi2Component::Ptr{Nothing})

    func = dlsym(libHandle, :fmi2Reset)

    status = ccall(
        func,
        Cuint,
        (Ptr{Cvoid},),
        fmi2Component
        )

    if status != 0
        throw(fmiError(status))
    end
end

function fmi2Reset(fmu::FMU)

    return fmi2Reset(fmu.libHandle, fmu.fmi2Component)
end


"""
    fmi2DoStep(libhandle::Ptr{Nothing},component::Ptr,currentCommunicationPoint::Cdouble,communicationStepSize::Cdouble,fmi2Boolean::Integer,noSetFMUStatePriorToCurrentPoint::Integer=true)

description

...
# Arguments
- `libhandle::Ptr{Nothing}`:
- `component::Ptr`:
- `currentCommunicationPoint::Cdouble`:
- `communicationStepSize::Cdouble`:
- `fmi2Boolean::Integer`:
- `noSetFMUStatePriorToCurrentPoint::Integer=true`:
...

# Example
'''
'''
"""
function fmi2DoStep(libHandle::Ptr{Nothing}, component::Ptr, currentCommunicationPoint::Cdouble,
    communicationStepSize::Cdouble, noSetFMUStatePriorToCurrentPoint::Integer=true)

    func = dlsym(libHandle, :fmi2DoStep)

    status = ccall(
        func,
        Cuint,
        (FMI2Component, Cdouble, Cdouble, Cint),
        unsafe_load(convert(Ptr{FMI2Component}, component)), currentCommunicationPoint,
        communicationStepSize, noSetFMUStatePriorToCurrentPoint)

    if status != 0
        throw(fmiError(status))
    end

    return status
end
function fmi2DoStep(fmu::FMU, currentCommunicationPoint::Cdouble,
    communicationStepSize::Cdouble, noSetFMUStatePriorToCurrentPoint::Integer=true)
    return fmi2DoStep(fmu.libHandle, fmu.fmi2Component, currentCommunicationPoint, communicationStepSize,
        noSetFMUStatePriorToCurrentPoint)
end




# ##############################################################################
# Getting Variable Values
# ##############################################################################

"""
```
    fmi2GetReal!(libHandle::Ptr{Nothing}, fmi2Component::Ptr{Nothing}, valueReference::T, [numberOfValueReference::Int], value::Array{Float64,1}) -> value
      where T is one of Array{UInt32,1}, Array{UInt,1}, Array{Int,1}

    fmi2GetReal!(fmu::FMU, valueReference::T, [numberOfValueReference::Int], value::Array{Float64,1}) -> value
      where T is one of Array{UInt32,1}, Array{UInt,1}, Array{Int,1}
```
Get values of real variables by providing their value references.
Overwrites provided array `value` with values.
Can be called after calling `fmi2EnterInitializationMode`.
See also `fmi2GetReal`.

## Example call
Get values of real variables with value references 0, 1 and 2
```
julia> value = Array{Float64}(undef,3)
julia> fmi2GetReal!(fmu, [0, 1, 2], value)
julia> println("value: \$value")
```
"""
function fmi2GetReal!(libHandle::Ptr{Nothing},
    fmi2Component::Ptr{Nothing}, valueReference::Array{UInt32,1},
    numberOfValueReference::Int, value::Array{Float64,1})

    if size(valueReference) != size(value)
        throw(DimensionMismatch("Arrays valueReference and value are not the same size."))
    elseif (length(valueReference) != numberOfValueReference)
        throw(DimensionMismatch("Wrong numberOfValueReference.
            Expected $(length(valueReference)) but got $numberOfValueReference."))
    end

    func = dlsym(libHandle, :fmi2GetReal)

    status = ccall(
        func,
        Cuint,
        (Ptr{Cvoid}, Ref{Cuint}, Csize_t, Ref{Cdouble}),
        fmi2Component, valueReference, numberOfValueReference, value
        )

    if status != 0
        throw(fmiError(status))
    end

    return value
end

function fmi2GetReal!(libHandle::Ptr{Nothing},
    fmi2Component::Ptr{Nothing}, valueReference::Array{UInt32,1},
    value::Array{Float64,1})

    return fmi2GetReal!(libHandle, fmi2Component, valueReference,
        length(valueReference), value)
end

function fmi2GetReal!(fmu::FMU, valueReference::Union{Array{UInt32,1}, Array{UInt64,1}, Array{Int,1}},
    numberOfValueReference::Int, value::Array{Float64,1})

    return fmi2GetReal!(fmu.libHandle, fmu.fmi2Component,
        convert(Array{UInt32,1},valueReference), numberOfValueReference, value)
end

function fmi2GetReal!(fmu::FMU, valueReference::Union{Array{UInt32,1}, Array{UInt64,1}, Array{Int,1}},
    value::Array{Float64,1})

    return fmi2GetReal!(fmu.libHandle, fmu.fmi2Component,
        convert(Array{UInt32,1},valueReference), length(valueReference), value)
end

"""
```
    fmi2GetReal(fmu::FMU, valueReference::Union{Int, UInt, UInt32}) -> value
```
Get value of real variable by providing a value reference.
See also `fmi2GetReal!`.

## Example call
Get value of real variable with value reference 0
```
julia> value = fmi2GetReal(fmu, 0)
julia> println("value: \$value")
```
"""
function fmi2GetReal(fmu::FMU, valueReference::Union{Int, UInt, UInt32})

    return fmi2GetReal!(fmu.libHandle, fmu.fmi2Component,
        convert(Array{UInt32,1},[valueReference]), 1, Array{Float64}(undef,1))
end

"""
```
    fmi2GetInteger!(libHandle::Ptr{Nothing}, fmi2Component::Ptr{Nothing}, valueReference::T, [numberOfValueReference::Int], value::Array{Int32,1}) -> value
      where T is one of Array{UInt32,1}, Array{UInt,1}, Array{Int32,1}

    fmi2GetInteger!(fmu::FMU, valueReference::T, [numberOfValueReference::Int], value::Array{Int32,1}) -> value
      where T is one of Array{UInt32,1}, Array{UInt,1}, Array{Int32,1}
```
Get values of integer variables by providing their value references.
Overwrites provided array `value` with values.
Can be called after calling `fmi2EnterInitializationMode`.
See also `fmi2GetInteger`.

## Example call
Get values of integer variables with value references 0, 1 and 2
```
julia> value = Array{Int32}(undef,3)
julia> fmi2GetInteger!(fmu, [0, 1, 2], value)
julia> println("value: \$value")
```
"""
function fmi2GetInteger!(libHandle::Ptr{Nothing},
    fmi2Component::Ptr{Nothing}, valueReference::Array{UInt32,1},
    numberOfValueReference::Int, value::Array{Int32,1})

    if size(valueReference) != size(value)
        throw(DimensionMismatch("Arrays valueReference and value are not the same size."))
    elseif (length(valueReference) != numberOfValueReference)
        throw(DimensionMismatch("Wrong numberOfValueReference.
            Expected $(length(valueReference)) but got $numberOfValueReference."))
    end

    func = dlsym(libHandle, :fmi2GetInteger)

    status = ccall(
        func,
        Cuint,
        (Ptr{Cvoid}, Ref{Cuint}, Csize_t, Ref{Cint}),
        fmi2Component, valueReference, numberOfValueReference, value
        )

    if status != 0
        throw(fmiError(status))
    end

    return value
end

function fmi2GetInteger!(libHandle::Ptr{Nothing},
    fmi2Component::Ptr{Nothing}, valueReference::Array{UInt32,1},
    value::Array{Int32,1})

    return fmi2GetInteger!(libHandle, fmi2Component, valueReference,
        length(valueReference), value)
end

function fmi2GetInteger!(fmu::FMU, valueReference::Union{Array{UInt32,1}, Array{UInt64,1}, Array{Int,1}},
    numberOfValueReference::Int, value::Array{Int32,1})

    return fmi2GetInteger!(fmu.libHandle, fmu.fmi2Component,
        convert(Array{UInt32,1},valueReference), numberOfValueReference, value)
end

function fmi2GetInteger!(fmu::FMU, valueReference::Union{Array{UInt32,1}, Array{UInt64,1}, Array{Int,1}},
    value::Array{Int32,1})

    return fmi2GetInteger!(fmu.libHandle, fmu.fmi2Component,
        convert(Array{UInt32,1},valueReference), length(valueReference), value)
end

function fmi2GetInteger!(fmu::FMU, valueReference::Union{Array{UInt32,1}, Array{UInt64,1}, Array{Int,1}},
    value::Array{Int64,1})

    return fmi2GetInteger!(fmu.libHandle, fmu.fmi2Component,
        convert(Array{UInt32,1},valueReference), length(valueReference), convert(Array{Int32,1},value))
end

"""
```
    fmi2GetInteger(fmu::FMU, valueReference::Union{Int, UInt, UInt32}) -> value
```
Get value of integer variable by providing a value reference.
See also `fmi2GetInteger!`.

## Example call
Get value of integer variable with value reference 0
```
julia> value = fmi2GetInteger(fmu, 0)
julia> println("value: \$value")
```
"""
function fmi2GetInteger(fmu::FMU, valueReference::Union{Int, UInt, UInt32})

    return fmi2GetInteger!(fmu.libHandle, fmu.fmi2Component,
        convert(Array{UInt32,1},[valueReference]), 1, Array{Int32}(undef,1))
end


"""
```
    fmi2GetBoolean!(libHandle::Ptr{Nothing}, fmi2Component::Ptr{Nothing}, valueReference::T, [numberOfValueReference::Int], value::Array{Int32,1}) -> value
      where T is one of Array{UInt32,1}, Array{UInt,1}, Array{Int32,1}

    fmi2GetBoolean!(fmu::FMU, valueReference::T, [numberOfValueReference::Int], value::Union{Array{Int32,1}, Array{Bool,1}}) -> value
      where T is one of Array{UInt32,1}, Array{UInt,1}, Array{Int32,1}
```
Get values of boolean variables by providing their value references.
Overwrites provided array `value` with values.
Can be called after calling `fmi2EnterInitializationMode`.
See also `fmi2GetBoolean`.

## Example call
Get values of boolean variables with value references 0, 1 and 2
```
julia> value = Array{Bool}(undef,3)
julia> fmi2GetBoolean!(fmu, [0, 1, 2], value)
julia> println("value: \$value")
```
"""
function fmi2GetBoolean!(libHandle::Ptr{Nothing},
    fmi2Component::Ptr{Nothing}, valueReference::Array{UInt32,1},
    numberOfValueReference::Int, value::Array{Int32,1})

    if size(valueReference) != size(value)
        throw(DimensionMismatch("Arrays valueReference and value are not the same size."))
    elseif (length(valueReference) != numberOfValueReference)
        throw(DimensionMismatch("Wrong numberOfValueReference.
            Expected $(length(valueReference)) but got $numberOfValueReference."))
    end

    func = dlsym(libHandle, :fmi2GetBoolean)

    status = ccall(
        func,
        Cuint,
        (Ptr{Cvoid}, Ref{Cuint}, Csize_t, Ref{Cint}),
        fmi2Component, valueReference, numberOfValueReference, value
        )

    if status != 0
        throw(fmiError(status))
    end

    return value
end

function fmi2GetBoolean!(libHandle::Ptr{Nothing},
    fmi2Component::Ptr{Nothing}, valueReference::Array{UInt32,1},
    value::Array{Int32,1})

    return fmi2GetBoolean!(libHandle, fmi2Component, valueReference,
        length(valueReference), value)
end

function fmi2GetBoolean!(fmu::FMU, valueReference::Union{Array{UInt32,1}, Array{UInt64,1}, Array{Int,1}},
    numberOfValueReference::Int, value::Union{Array{Int32,1}, Array{Bool,1}})

    return fmi2GetBoolean!(fmu.libHandle, fmu.fmi2Component,
        convert(Array{UInt32,1},valueReference), numberOfValueReference, value)
end

function fmi2GetBoolean!(fmu::FMU, valueReference::Union{Array{UInt32,1}, Array{UInt64,1}, Array{Int,1}},
    value::Union{Array{Int32,1}, Array{Bool,1}})

    return fmi2GetBoolean!(fmu.libHandle, fmu.fmi2Component,
        convert(Array{UInt32,1},valueReference), length(valueReference),
        convert(Array{Int32,1}, value))
end

"""
```
    fmi2GetBoolean(fmu::FMU, valueReference::Union{Int, UInt, UInt32}) -> value
```
Get value of boolean variable by providing a value reference.
See also `fmi2GetBool!`.

## Example call
Get value of boolean variable with value reference 0
```
julia> value = fmi2GetBoolean(fmu, 0)
julia> println("value: \$value")
```
"""
function fmi2GetBoolean(fmu::FMU, valueReference::Union{Int, UInt, UInt32})

    return fmi2GetBoolean!(fmu.libHandle, fmu.fmi2Component,
        convert(Array{UInt32,1},[valueReference]), 1, Array{Int32}(undef,1))
end


"""
```
    fmi2GetString!(libHandle::Ptr{Nothing}, fmi2Component::Ptr{Nothing}, valueReference::T, [numberOfValueReference::Int], value::Array{String,1}) -> value
      where T is one of Array{UInt32,1}, Array{UInt,1}, Array{Int32,1}

    fmi2GetString!(fmu::FMU, valueReference::T, [numberOfValueReference::Int], value::Array{String,1}) -> value
      where T is one of Array{UInt32,1}, Array{UInt,1}, Array{Int32,1}
```
Get values of string variables by providing their value references.
Overwrites provided array `value` with values. Actually I have no clue whats happening...
Can be called after calling `fmi2EnterInitializationMode`.
See also `fmi2GetString`.

## Example call
Get values of string variables with value references 0, 1 and 2
```
julia> value = Array{String}(undef,3)
julia> fmi2GetString!(fmu, [0, 1, 2], value)
julia> println("value: \$value")
```
"""
function fmi2GetString!(libHandle::Ptr{Nothing},
    fmi2Component::Ptr{Nothing}, valueReference::Array{UInt32,1},
    numberOfValueReference::Int, value::Array{String,1})

    if size(valueReference) != size(value)
        throw(DimensionMismatch("Arrays valueReference and value are not the same size."))
    elseif (length(valueReference) != numberOfValueReference)
        throw(DimensionMismatch("Wrong numberOfValueReference.
            Expected $(length(valueReference)) but got $numberOfValueReference."))
    end

    func = dlsym(libHandle, :fmi2GetString)

    status = ccall(
        func,
        Cuint,
        (Ptr{Cvoid}, Ref{Cuint}, Csize_t, Ref{Cstring}),
        fmi2Component, valueReference, numberOfValueReference, value
        )

    if status != 0
        throw(fmiError(status))
    end

    # Return copy of string array, since the FMU is allowed to free the
    # allocated memory at any time
    return copy(value)
end

function fmi2GetString!(libHandle::Ptr{Nothing},
    fmi2Component::Ptr{Nothing}, valueReference::Array{UInt32,1},
    value::Array{String,1})

    return fmi2GetString!(libHandle, fmi2Component, valueReference,
        length(valueReference), value)
end

function fmi2GetString!(fmu::FMU, valueReference::Array{UInt32,1},
    numberOfValueReference::Int, value::Array{String,1})

    return fmi2GetString!(fmu.libHandle, fmu.fmi2Component, valueReference,
        numberOfValueReference, value)
end

function fmi2GetString!(fmu::FMU, valueReference::Array{UInt64,1},
    numberOfValueReference::Int, value::Array{String,1})

    return fmi2GetString!(fmu.libHandle, fmu.fmi2Component,
            convert(Array{UInt32,1},valueReference),
        numberOfValueReference, value)
end

function fmi2GetString!(fmu::FMU, valueReference::Array{UInt32,1},
    value::Array{String,1})

    return fmi2GetString!(fmu.libHandle, fmu.fmi2Component, valueReference,
        length(valueReference), value)
end

function fmi2GetString!(fmu::FMU, valueReference::Array{UInt64,1},
    value::Array{String,1})

    return fmi2GetString!(fmu.libHandle, fmu.fmi2Component,
            convert(Array{UInt32,1},valueReference),
         length(valueReference), value)
end

"""
```
    fmi2GetString(fmu::FMU, valueReference::Union{Int, UInt, UInt32}) -> value
```
Get value of string variable by providing a value reference.
See also `fmi2GetString!`.

## Example call
Get value of string variable with value reference 0
```
julia> value = fmi2GetString(fmu, 0)
julia> println("value: \$value")
```
"""
function fmi2GetString(fmu::FMU, valueReference::Union{Int, UInt, UInt32})

    return fmi2GetString!(fmu.libHandle, fmu.fmi2Component,
        convert(Array{UInt32,1},[valueReference]), 1, Array{String}(undef,1))
end


# ##############################################################################
# Setting Variable Values
# ##############################################################################

"""
```
    fmi2SetReal(libHandle::Ptr{Nothing}, fmi2Component::Ptr{Nothing}, valueReference::T, [numberOfValueReference::Int], value::Array{Float64,1})
      where T is one of Array{UInt32,1}, Array{UInt,1}, Array{Int,1}

    fmi2SetReal(fmu::FMU, valueReference::T, [numberOfValueReference::Int], value::Array{Float64,1})
      where T is one of Array{UInt32,1}, Array{UInt,1}, Array{Int,1}

    fmi2SetReal(fmu::FMU, valueReference::T, value::Float64)
      where T is one of UInt32, UInt, Int
```
Set values of real variables by providing their value references and values.
Can be called after calling `fmi2EnterInitializationMode`.

## Example calls
Set value of real variable with value reference 0
```
julia> fmi2SetReal(fmu, 0, -42.1337)
```
Set values of real variables with value references 0, 1 and 2
```
julia> fmi2SetReal(fmu, [0, 1, 2], [1.2,3.4,-1.0])
```
"""
function fmi2SetReal(libHandle::Ptr{Nothing},
    fmi2Component::Ptr{Nothing}, valueReference::Array{UInt32,1},
    numberOfValueReference::Int, value::Array{Float64,1})

    if size(valueReference) != size(value)
        throw(DimensionMismatch("Arrays valueReference and value are not the same size."))
    elseif (length(valueReference) != numberOfValueReference)
        throw(DimensionMismatch("Wrong numberOfValueReference.
            Expected $(length(valueReference)) but got $numberOfValueReference."))
    end

    func = dlsym(libHandle, :fmi2SetReal)

    status = ccall(
        func,
        Cuint,
        (Ptr{Cvoid}, Ref{Cuint}, Csize_t, Ref{Cdouble}),
        fmi2Component, valueReference, numberOfValueReference, value
        )

    if status != 0
        throw(fmiError(status))
    end
end

function fmi2SetReal(libHandle::Ptr{Nothing},
    fmi2Component::Ptr{Nothing}, valueReference::Array{UInt32,1},
    value::Array{Float64,1})

    fmi2SetReal(libHandle, fmi2Component, valueReference,
        length(valueReference), value)
end

function fmi2SetReal(fmu::FMU, valueReference::Union{Array{UInt32,1}, Array{UInt64,1}, Array{Int,1}},
    numberOfValueReference::Int, value::Array{Float64,1})

    fmi2SetReal(fmu.libHandle, fmu.fmi2Component,
        convert(Array{UInt32,1},valueReference), numberOfValueReference, value)
end

function fmi2SetReal(fmu::FMU, valueReference::Union{Array{UInt32,1}, Array{UInt64,1}, Array{Int,1}},
    value::Array{Float64,1})

    fmi2SetReal(fmu.libHandle, fmu.fmi2Component,
        convert(Array{UInt32,1},valueReference), length(valueReference), value)
end

function fmi2SetReal(fmu::FMU, valueReference::Union{UInt32, UInt64, Int},
    value::Float64)

    fmi2SetReal(fmu.libHandle, fmu.fmi2Component,
        convert(Array{UInt32,1},[valueReference]), length(valueReference), [value])
end


"""
```
    fmi2SetInteger(libHandle::Ptr{Nothing}, fmi2Component::Ptr{Nothing}, valueReference::T, [numberOfValueReference::Int], value::Array{Int32,1})
      where T is one of Array{UInt32,1}, Array{UInt,1}, Array{Int32,1}

    fmi2SetInteger(fmu::FMU, valueReference::T, [numberOfValueReference::Int], value::Array{Int32,1})
      where T is one of Array{UInt32,1}, Array{UInt,1}, Array{Int32,1}

    fmi2SetInteger(fmu::FMU, valueReference::T, value::Int32)
      where T is one of UInt32, UInt, Int
```
Set values of integer variables by providing their value references.
Can be called after calling `fmi2EnterInitializationMode`.

## Example calls
Set value of integer variable with value reference 0
```
julia> fmi2SetInteger(fmu, 0, 42)
```
Set values of integer variables with value references 0, 1 and 2
```
julia> fmi2SetInteger(fmu, [0, 1, 2], [-1, 3, 27])
```
"""
function fmi2SetInteger(libHandle::Ptr{Nothing},
    fmi2Component::Ptr{Nothing}, valueReference::Array{UInt32,1},
    numberOfValueReference::Int, value::Array{Int32,1})

    if size(valueReference) != size(value)
        throw(DimensionMismatch("Arrays valueReference and value are not the same size."))
    elseif (length(valueReference) != numberOfValueReference)
        throw(DimensionMismatch("Wrong numberOfValueReference.
            Expected $(length(valueReference)) but got $numberOfValueReference."))
    end

    func = dlsym(libHandle, :fmi2SetInteger)

    status = ccall(
        func,
        Cuint,
        (Ptr{Cvoid}, Ref{Cuint}, Csize_t, Ref{Cint}),
        fmi2Component, valueReference, numberOfValueReference, value
        )

    if status != 0
        throw(fmiError(status))
    end
end

function fmi2SetInteger(libHandle::Ptr{Nothing},
    fmi2Component::Ptr{Nothing}, valueReference::Array{UInt32,1},
    value::Array{Int32,1})

    fmi2SetInteger(libHandle, fmi2Component, valueReference,
        length(valueReference), value)
end

function fmi2SetInteger(fmu::FMU, valueReference::Union{Array{UInt32,1}, Array{UInt64,1}, Array{Int,1}},
    numberOfValueReference::Int, value::Array{Int32,1})

    fmi2SetInteger(fmu.libHandle, fmu.fmi2Component,
        convert(Array{UInt32,1},valueReference), numberOfValueReference, value)
end

function fmi2SetInteger(fmu::FMU, valueReference::Union{Array{UInt32,1}, Array{UInt64,1}, Array{Int,1}},
    value::Array{Int32,1})

    fmi2GetInteger!(fmu.libHandle, fmu.fmi2Component,
        convert(Array{UInt32,1},valueReference), length(valueReference), value)
end

function fmi2SetInteger(fmu::FMU, valueReference::Union{UInt32, UInt64, Int},
    value::Int32)

    fmi2SetInteger(fmu.libHandle, fmu.fmi2Component,
        convert(Array{UInt32,1},[valueReference]), length(valueReference), [value])
end


"""
```
    fmi2SetBoolean(libHandle::Ptr{Nothing}, fmi2Component::Ptr{Nothing}, valueReference::T, [numberOfValueReference::Int], value::Array{Int32,1})
      where T is one of Array{UInt32,1}, Array{UInt,1}, Array{Int32,1}

    fmi2SetBoolean(fmu::FMU, valueReference::T, [numberOfValueReference::Int], value::Union{Array{Int32,1}, Array{Bool,1}})
      where T is one of Array{UInt32,1}, Array{UInt,1}, Array{Int32,1}

    fmi2SetBoolean(fmu::FMU, valueReference::T, value::Int32)
      where T is one of UInt32, UInt, Int
```
Set values of boolean variables by providing their value references.
Can be called after calling `fmi2EnterInitializationMode`.

## Example calls
Set value of boolean variable with value reference 0
```
julia> fmi2SetBoolean(fmu, 0, true)
```
Set values of boolean variables with value references 0, 1 and 2
```
julia> fmi2SetBoolean(fmu, [0, 1, 2], [true, false, false])
```
"""
function fmi2SetBoolean(libHandle::Ptr{Nothing},
    fmi2Component::Ptr{Nothing}, valueReference::Array{UInt32,1},
    numberOfValueReference::Int, value::Array{Int32,1})

    if size(valueReference) != size(value)
        throw(DimensionMismatch("Arrays valueReference and value are not the same size."))
    elseif (length(valueReference) != numberOfValueReference)
        throw(DimensionMismatch("Wrong numberOfValueReference.
            Expected $(length(valueReference)) but got $numberOfValueReference."))
    end

    func = dlsym(libHandle, :fmi2SetBoolean)

    status = ccall(
        func,
        Cuint,
        (Ptr{Cvoid}, Ref{Cuint}, Csize_t, Ref{Cint}),
        fmi2Component, valueReference, numberOfValueReference, value
        )

    if status != 0
        throw(fmiError(status))
    end
end

function fmi2SetBoolean(libHandle::Ptr{Nothing},
    fmi2Component::Ptr{Nothing}, valueReference::Array{UInt32,1},
    value::Array{Int32,1})

    fmi2SetBoolean(libHandle, fmi2Component, valueReference,
        length(valueReference), value)
end

function fmi2SetBoolean(fmu::FMU, valueReference::Union{Array{UInt32,1}, Array{UInt64,1}, Array{Int,1}},
    numberOfValueReference::Int, value::Array{Int32,1})

    fmi2SetBoolean(fmu.libHandle, fmu.fmi2Component,
        convert(Array{UInt32,1},valueReference), numberOfValueReference, value)
end

function fmiSGetBoolean(fmu::FMU, valueReference::Union{Array{UInt32,1}, Array{UInt64,1}, Array{Int,1}},
    value::Array{Int32,1})

    fmi2SetBoolean(fmu.libHandle, fmu.fmi2Component,
        convert(Array{UInt32,1},valueReference), length(valueReference), value)
end

function fmi2SetBoolean(fmu::FMU, valueReference::Union{Array{UInt32,1}, Array{UInt64,1}, Array{Bool,1}},
    value::Array{Int32,1})

    fmi2SetBoolean(fmu.libHandle, fmu.fmi2Component,
        convert(Array{UInt32,1},valueReference), length(valueReference),
        convert(Array{Int32,1}, value))
end

function fmi2SetBoolean(fmu::FMU, valueReference::Union{Int, UInt, UInt32}, value::Int32)

    fmi2SetBoolean(fmu.libHandle, fmu.fmi2Component,
        convert(Array{UInt32,1},[valueReference]), 1, Array{Int32}(value))
end


"""
```
    fmi2SetString(libHandle::Ptr{Nothing}, fmi2Component::Ptr{Nothing}, valueReference::T, [numberOfValueReference::Int], value::Array{String,1})
      where T is one of Array{UInt32,1}, Array{UInt,1}, Array{Int32,1}

    fmi2SetString(fmu::FMU, valueReference::T, [numberOfValueReference::Int], value::Array{String,1})
      where T is one of Array{UInt32,1}, Array{UInt,1}, Array{Int32,1}

    fmi2SetString(fmu::FMU, valueReference::T, value::String)
      where T is one of UInt32, UInt, Int
```
Set values of string variables by providing their value references.
Can be called after calling `fmi2EnterInitializationMode`.

## Example calls
Set value of string variable with value reference 0
```
julia> fmi2SetBoolean(fmu, 0, \"foo\")
```
Set values of string variables with value references 0, 1 and 2
```
julia> fmi2SetString(fmu, [0, 1, 2], [\"Hello\", \"FMU\", \"Julia\"])
```
"""
function fmi2SetString(libHandle::Ptr{Nothing},
    fmi2Component::Ptr{Nothing}, valueReference::Array{UInt32,1},
    numberOfValueReference::Int, value::Array{String,1})

    if size(valueReference) != size(value)
        throw(DimensionMismatch("Arrays valueReference and value are not the same size."))
    elseif (length(valueReference) != numberOfValueReference)
        throw(DimensionMismatch("Wrong numberOfValueReference.
            Expected $(length(valueReference)) but got $numberOfValueReference."))
    end

    func = dlsym(libHandle, :fmi2SetString)

    status = ccall(
        func,
        Cuint,
        (Ptr{Cvoid}, Ref{Cuint}, Csize_t, Ref{Cstring}),
        fmi2Component, valueReference, numberOfValueReference, value
        )

    if status != 0
        throw(fmiError(status))
    end
end

function fmi2SetString(libHandle::Ptr{Nothing},
    fmi2Component::Ptr{Nothing}, valueReference::Array{UInt32,1},
    value::Array{String,1})

    fmi2SetString(libHandle, fmi2Component, valueReference,
        length(valueReference), value)
end

function fmi2SetString(fmu::FMU, valueReference::Array{UInt32,1},
    numberOfValueReference::Int, value::Array{String,1})

    fmi2SetString(fmu.libHandle, fmu.fmi2Component, valueReference,
        numberOfValueReference, value)
end

function fmi2SetString(fmu::FMU, valueReference::Array{UInt32,1},
    value::Array{String,1})

    fmi2SetString(fmu.libHandle, fmu.fmi2Component, valueReference,
        length(valueReference), value)
end

function fmi2SetString(fmu::FMU, valueReference::Union{Int, UInt, UInt32},
    value::String)

    fmi2SetString(fmu.libHandle, fmu.fmi2Component,
        convert(Array{UInt32,1},[valueReference]), 1, Array{String}(value))
end


# ##############################################################################
# Getting and Setting the Complete FMU State
# ##############################################################################

"""
Function `fmi2GetFMUstate` not implemeted yet.
Probably not very usefull in Julia context for ModelExchange.
"""
function fmi2GetFMUstate(fmu::FMU)

    #fmi2Status fmi2GetFMUstate (fmi2Component c, fmi2FMUstate* FMUstate);

    error("FMI function not supportet")
end


"""
Function `fmi2SetFMUstate` not implemeted yet.
Probably not very usefull in Julia context for ModelExchange.
"""
function fmi2SetFMUstate(fmu::FMU)

    #fmi2Status fmi2SetFMUstate (fmi2Component c, fmi2FMUstate FMUstate);

    error("FMI function not supportet")
end


"""
Function `fmi2FreeFMUstate` not implemeted yet.
Probably not very usefull in Julia context for ModelExchange.
"""
function fmi2FreeFMUstate(fmu::FMU)

    #fmi2Status fmi2FreeFMUstate(fmi2Component c, fmi2FMUstate* FMUstate);

    error("FMI function not supportet")
end


"""
Function `fmi2SerializedFMUstateSize` not implemeted yet.
Probably not very usefull in Julia context for ModelExchange.
"""
function fmi2SerializedFMUstateSize(fmu::FMU)

    #fmi2Status fmi2SerializedFMUstateSize(fmi2Component c, fmi2FMUstate FMUstate, size_t *size);

    error("FMI function not supportet")
end


"""
Function `fmi2SerializeFMUstate` not implemeted yet.
Probably not very usefull in Julia context for ModelExchange.
"""
function fmi2SerializeFMUstate(fmu::FMU)

    #fmi2Status fmi2SerializeFMUstate (fmi2Component c, fmi2FMUstate FMUstate, fmi2Byte serializedState[], size_t size);

    error("FMI function not supportet")
end


"""
Function `fmi2DeSerializeFMUstate` not implemeted yet.
Probably not very usefull in Julia context for ModelExchange.
"""
function fmi2DeSerializeFMUstate(fmu::FMU)

    #fmi2Status fmi2DeSerializeFMUstate (fmi2Component c, const fmi2Byte serializedState[], size_t size, fmi2FMUstate* FMUstate);

    error("FMI function not supportet")
end


# ##############################################################################
# Getting Partial Derivatives
# ##############################################################################

"""
Function `fmi2GetDirectionalDerivative` not implemeted yet.
Probably not very usefull in Julia context for ModelExchange.
"""
function fmi2GetDirectionalDerivative(fmu::FMU)

    #fmi2Status fmi2GetDirectionalDerivative(fmi2Component c,
    #    const fmi2ValueReference vUnknown_ref[], size_t nUnknown,
    #    const fmi2ValueReference vKnown_ref[] , size_t nKnown,
    #    const fmi2Real dvKnown[],
    #    fmi2Real dvUnknown[])

    error("FMI function not supportet")
end


# ##############################################################################
# Providing Independent Variables and Re-initialization of Caching
# ##############################################################################

"""
```
    fmi2SetTime(libHandle::Ptr{Nothing}, fmi2Component::Ptr{Nothing}, time::Float64)

    fmi2SetTime(fmu::FMU, time::Float64)
```
Set a new time instant and re-initialize caching of variables that depend on
time, provided the newly provided time value is different to the previously set
time value
"""
function fmi2SetTime(libHandle::Ptr{Nothing}, fmi2Component::Ptr{Nothing},
    time::Float64)

    func = dlsym(libHandle, :fmi2SetTime)

    status = ccall(
        func,
        Cuint,
        (Ptr{Cvoid}, Cdouble),
        fmi2Component, time
        )

    if status != 0
        throw(fmiError(status))
    end
end

function fmi2SetTime(fmu::FMU, time::Float64)
    fmi2SetTime(fmu.libHandle, fmu.fmi2Component, time)
end


"""
```
    fmi2SetContinuousStates(libHandle::Ptr{Nothing}, fmi2Component::Ptr{Nothing}, states::Array{Float64,1}, [n_states::Int])

    fmi2SetContinuousStates(fmu::FMU, states::Array{Float64,1}, [n_states::Int])
```
Set a new (continuous) state vector and re-initialize caching of variables that
depend on the states. Argument `n_states` is the length of vector `states`
and is provided for checking purposes.
"""
function fmi2SetContinuousStates(libHandle::Ptr{Nothing},
    fmi2Component::Ptr{Nothing}, states::Array{Float64,1}, n_states::Int)

    if length(states) != n_states
        throw(DimensionMismatch("Array states has not length $(length(states)).
            Expected $n_states."))
    end

    func = dlsym(libHandle, :fmi2SetContinuousStates)

    status = ccall(
        func,
        Cuint,
        (Ptr{Cvoid}, Ref{Cdouble}, Csize_t),
        fmi2Component, states, n_states
        )

    if status != 0
        throw(fmiError(status))
    end
end

function fmi2SetContinuousStates(libHandle::Ptr{Nothing},
    fmi2Component::Ptr{Nothing}, states::Array{Float64,1})

    fmi2SetContinuousStates(libHandle, fmi2Component, states, length(states))
end

function fmi2SetContinuousStates(fmu::FMU, states::Array{Float64,1},
    n_states::Int)

    fmi2SetContinuousStates(fmu.libHandle, fmu.fmi2Component, states, n_states)
end

function fmi2SetContinuousStates(fmu::FMU, states::Array{Float64,1})

    fmi2SetContinuousStates(fmu.libHandle, fmu.fmi2Component, states,
        length(states))
end


"""
```
    fmi2EnterEventMode(libHandle::Ptr{Nothing}, fmi2Component::Ptr{Nothing})

    fmi2EnterEventMode(fmu::FMU)
```
The model enters Event Mode from the Continuous-Time Mode.
"""
function fmi2EnterEventMode(libHandle::Ptr{Nothing}, fmi2Component::Ptr{Nothing})

    func = dlsym(libHandle, :fmi2EnterEventMode)

    status = ccall(
        func,
        Cuint,
        (Ptr{Cvoid},),
        fmi2Component,
        )

    if status != 0
        throw(fmiError(status))
    end
end

function fmi2EnterEventMode(fmu::FMU)

    fmi2EnterEventMode(fmu.libHandle, fmu.fmi2Component)
end


"""
```
    fmi2NewDiscreteStates!(libHandle::Ptr{Nothing}, fmi2Component::Ptr{Nothing}, fmi2EventInfo::EventInfo) -> fmi2EventInfo

    fmi2NewDiscreteStates!(fmu::FMU) -> fmi2EventInfo
```
The FMU is in Event Mode and the super dense time is incremented by this call.
"""
function fmi2NewDiscreteStates!(libHandle::Ptr{Nothing},
    fmi2Component::Ptr{Nothing}, fmi2EventInfo::EventInfo)

    func = dlsym(libHandle, :fmi2NewDiscreteStates)

    status = ccall(
        func,
        Cuint,
        (Ptr{Cvoid}, Ref{EventInfo}),
        fmi2Component, fmi2EventInfo
        )

    if status != 0
        throw(fmiError(status))
    end

    return fmi2EventInfo
end

function fmi2NewDiscreteStates!(fmu::FMU)

    return fmi2NewDiscreteStates!(fmu.libHandle, fmu.fmi2Component, fmu.eventInfo)
end


"""
```
    fmi2EnterContinuousTimeMode(libHandle::Ptr{Nothing}, fmi2Component::Ptr{Nothing})

    fmi2EnterContinuousTimeMode(fmu::FMU)
```
The model enters Continuous-Time Mode and all discrete-time equations become
inactive and all relations are "frozen".
This function has to be called when changing from Event Mode into
Continuous-Time Mode.
"""
function fmi2EnterContinuousTimeMode(libHandle::Ptr{Nothing},
    fmi2Component::Ptr{Nothing})

    func = dlsym(libHandle, :fmi2EnterContinuousTimeMode)

    status = ccall(
        func,
        Cuint,
        (Ptr{Cvoid},),
        fmi2Component
        )

    if status != 0
        throw(fmiError(status))
    end
end

function fmi2EnterContinuousTimeMode(fmu::FMU)

    fmu.modelState = modelContinuousTimeMode

    fmi2EnterContinuousTimeMode(fmu.libHandle, fmu.fmi2Component)
end


"""
```
    fmi2CompletedIntegratorStep(libHandle::Ptr{Nothing}, fmi2Component::Ptr{Nothing}, noSetFMUStatePriorToCurrentPoint::Bool) -> (enterEventMode, terminateSimulation)

    fmi2CompletedIntegratorStep(fmu::FMU, noSetFMUStatePriorToCurrentPoint::Bool) -> (enterEventMode, terminateSimulation)
```
This function must be called by the environment after every completed step of
the integrator provided the capability flag
`completedIntegratorStepNotNeeded = false`.
"""
function fmi2CompletedIntegratorStep(libHandle::Ptr{Nothing},
    fmi2Component::Ptr{Nothing}, noSetFMUStatePriorToCurrentPoint::Bool)

    func = dlsym(libHandle, :fmi2CompletedIntegratorStep)

    enterEventModeOut = Ref(UInt32(true))
    terminateSimulationOut = Ref(UInt32(true))

    status = ccall(
        func,
        Cuint,
        (Ptr{Cvoid}, Cuint, Ref{Cuint}, Ref{Cuint}),
        fmi2Component, noSetFMUStatePriorToCurrentPoint, enterEventModeOut,
        terminateSimulationOut
        )

    if status != 0
        throw(fmiError(status))
    end

    return (Bool(enterEventModeOut[]), Bool(terminateSimulationOut[]))
end

function fmi2CompletedIntegratorStep(fmu::FMU,
    noSetFMUStatePriorToCurrentPoint::Bool)

    return fmi2CompletedIntegratorStep(fmu.libHandle, fmu.fmi2Component,
        noSetFMUStatePriorToCurrentPoint)
end


"""
```
    fmi2GetDerivatives!(libHandle::Ptr{Nothing}, fmi2Component::Ptr{Nothing}, derivatives::Array{Float64,1}, [numberOfDerivatives::Int])

    fmi2GetDerivatives!(fmu::FMU, derivatives::Array{Float64,1}, [numberOfDerivatives::Int])
```
Compute state derivatives at the current time instant and for the current
states.
"""
function fmi2GetDerivatives!(libHandle::Ptr{Nothing},
    fmi2Component::Ptr{Nothing}, derivatives::Array{Float64,1},
    numberOfDerivatives::Int)

    if (length(derivatives) != numberOfDerivatives)
        throw(DimensionMismatch("Wrong numberOfDerivatives.
            Expected $(length(derivatives)) but got $numberOfDerivatives."))
    end

    func = dlsym(libHandle, :fmi2GetDerivatives)

    status = ccall(
        func,
        Cuint,
        (Ptr{Cvoid}, Ref{Cdouble}, Csize_t,),
        fmi2Component, derivatives, numberOfDerivatives
        )

    if status != 0
        throw(fmiError(status))
    end
end

function fmi2GetDerivatives!(libHandle::Ptr{Nothing},
    fmi2Component::Ptr{Nothing}, derivatives::Array{Float64,1})

    fmi2GetDerivatives!(libHandle, fmi2Component, derivatives,
        length(derivatives))
end

function fmi2GetDerivatives!(fmu::FMU, derivatives::Array{Float64,1},
    numberOfDerivatives::Int)

    fmi2GetDerivatives!(fmu.libHandle, fmu.fmi2Component, derivatives,
        numberOfDerivatives)
end

function fmi2GetDerivatives!(fmu::FMU, derivatives::Array{Float64,1})

    fmi2GetDerivatives!(fmu.libHandle, fmu.fmi2Component, derivatives,
        length(derivatives))
end


"""
```
    fmi2GetEventIndicators!(libHandle::Ptr{Nothing}, fmi2Component::Ptr{Nothing}, eventIndicators::Array{Float64,1}, [numberOfEventIndiactors::Int])

    fmi2GetEventIndicators!(fmu::FMU, eventIndicators::Array{Float64,1}, [numberOfEventIndiactors::Int])
```
Compute event indicators at the current time instant and for the current
states.
"""
function fmi2GetEventIndicators!(libHandle::Ptr{Nothing},
    fmi2Component::Ptr{Nothing}, eventIndicators::Array{Float64,1},
    numberOfEventIndiactors::Int)

    if (length(eventIndicators) != numberOfEventIndiactors)
        throw(DimensionMismatch("Wrong numberOfEventIndiactors.
            Expected $(length(eventIndicators)) but got $numberOfEventIndiactors."))
    end

    func = dlsym(libHandle, :fmi2GetEventIndicators)

    status = ccall(
        func,
        Cuint,
        (Ptr{Cvoid}, Ref{Cdouble}, Csize_t,),
        fmi2Component, eventIndicators, numberOfEventIndiactors
        )

    if status != 0
        throw(fmiError(status))
    end
end

function fmi2GetEventIndicators!(libHandle::Ptr{Nothing},
    fmi2Component::Ptr{Nothing}, eventIndicators::Array{Float64,1})

    fmi2GetEventIndicators!(libHandle, fmi2Component, eventIndicators,
        length(eventIndicators))
end

function fmi2GetEventIndicators!(fmu::FMU, eventIndicators::Array{Float64,1},
    numberOfEventIndiactors::Int)

    fmi2GetEventIndicators!(fmu.libHandle, fmu.fmi2Component, eventIndicators,
        numberOfEventIndiactors)
end

function fmi2GetEventIndicators!(fmu::FMU, eventIndicators::Array{Float64,1})

    fmi2GetEventIndicators!(fmu.libHandle, fmu.fmi2Component, eventIndicators,
        length(eventIndicators))
end


"""
```
    fmi2GetContinuousStates!(libHandle::Ptr{Nothing}, fmi2Component::Ptr{Nothing}, states::Array{Float64,1}, [n_states::Int]) -> states

    fmi2GetContinuousStates!(fmu::FMU, states::Array{Float64,1}, [n_states::Int]) -> states
```
Return the new (continuous) state vector `states`. Argument `n_states` is the
length of vector `states`and is provided for checking purposes.
This function has to be called directly after calling function
`fmi2EnterContinuousTimeMode` if it returns with
`eventInfo->valuesOfContinuousStatesChanged = true`.
"""
function fmi2GetContinuousStates!(libHandle::Ptr{Nothing},
    fmi2Component::Ptr{Nothing}, states::Array{Float64,1}, n_states::Int)

    if length(states) != n_states
        throw(DimensionMismatch("Wrong n_states.
            Expected $(length(states)) but got $n_states."))
    end

    func = dlsym(libHandle, :fmi2GetContinuousStates)

    status = ccall(
        func,
        Cuint,
        (Ptr{Cvoid}, Ref{Cdouble}, Csize_t),
        fmi2Component, states, n_states
        )

    if status != 0
        throw(fmiError(status))
    end

    return states
end

function fmi2GetContinuousStates!(libHandle::Ptr{Nothing},
    fmi2Component::Ptr{Nothing}, states::Array{Float64,1})

    return fmi2GetContinuousStates!(libHandle, fmi2Component, states, length(states))
end

function fmi2GetContinuousStates!(fmu::FMU, states::Array{Float64,1},
    n_states::Int)

    return fmi2GetContinuousStates!(fmu.libHandle, fmu.fmi2Component, states, n_states)
end

function fmi2GetContinuousStates!(fmu::FMU, states::Array{Float64,1})

    return fmi2GetContinuousStates!(fmu.libHandle, fmu.fmi2Component, states,
        length(states))
end


"""
```
    fmi2GetNominalsOfContinuousStates!(libHandle::Ptr{Nothing}, fmi2Component::Ptr{Nothing}, x_nominal::Array{Float64,1}, [n_nominal::Int]) -> x_nominal

    fmi2GetNominalsOfContinuousStates!(fmu::FMU, x_nominal::Array{Float64,1}, [n_nominal::Int]) -> x_nominal
```
Return the nominal values of the continuous states. This function should always
be called after calling function `fmi2NewDiscreteStates` if it returns with
`eventInfo->nominalsOfContinuousStatesChanged = true` since then the nominal
values of the continuous states have changed.
"""
function fmi2GetNominalsOfContinuousStates!(libHandle::Ptr{Nothing},
    fmi2Component::Ptr{Nothing}, x_nominal::Array{Float64,1}, n_nominal::Int)

    if length(x_nominal) != n_nominal
        throw(DimensionMismatch("Wrong n_nominal.
            Expected $(length(x_nominal)) but got $n_nominal."))
    end

    func = dlsym(libHandle, :fmi2GetNominalsOfContinuousStates)

    status = ccall(
        func,
        Cuint,
        (Ptr{Cvoid}, Ref{Cdouble}, Csize_t),
        fmi2Component, x_nominal, n_nominal
        )

    if status != 0
        throw(fmiError(status))
    end

    return x_nominal
end

function fmi2GetNominalsOfContinuousStates!(fmu::FMU,
    x_nominal::Array{Float64,1}, n_nominal::Int)

    return fmi2GetNominalsOfContinuousStates!(fmu.libHandle, fmu.fmi2Component,
        x_nominal, n_nominal)
end

function fmi2GetNominalsOfContinuousStates!(fmu::FMU,
    x_nominal::Array{Float64,1})

    return fmi2GetNominalsOfContinuousStates!(fmu.libHandle, fmu.fmi2Component,
        x_nominal, length(x_nominal))
end
