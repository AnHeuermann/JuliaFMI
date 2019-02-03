# This file is part of JuliaFMI.
# License is MIT: https://servant-om.fh-bielefeld.de/gitlab/AnHeuermann/FMU_JL_Simulator/blob/master/LICENSE.txt

# This file contains wrapper to call FMI functions

include("FMI2Types.jl")
include("FMICallbackFunctions.jl") # Callbacks for logging and memory handling


# ##############################################################################
# Inquire Platform and Version Number of Header Files
# ##############################################################################

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

    fmi2Instantiate(libHandle::Ptr{Nothing}, instanceName::String, fmuType::fmuType, fmuGUID::String, fmuResourceLocation::String, functions::CallbackFunctions, visible::Bool, loggingOn::Bool)
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
    fmuType::fmuType, fmuGUID::String, fmuResourceLocation::String,
    functions::CallbackFunctions, visible::Bool=true, loggingOn::Bool=false)

    func = dlsym(libHandle, :fmi2Instantiate)

    fmi2Component = ccall(
      func,
      Ptr{Cvoid},
      (Cstring, Cint, Cstring, Cstring,
      Ref{CallbackFunctions}, Cint, Cint),
      instanceName, fmuType, fmuGUID, fmuResourceLocation,
      Ref(functions), visible, loggingOn
      )

    if fmi2Component == C_NULL
        throw(FMI2Error("Could not instantiate FMU"))
    end

    return fmi2Component
end

function fmi2Instantiate!(fmu::FMU)
    fmu.fmi2Component = fmi2Instantiate(fmu.libHandle, fmu.instanceName,
        fmu.fmuType, fmu.fmuGUID, fmu.fmuResourceLocation,
        fmu.fmiCallbackFunctions, true, true)

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
        fmi2Component, valueReference, numberOfValeReference, value
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
        fmi2Component, valueReference, numberOfValeReference, value
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
    numberOfValueReference::Int, value::Array{Int32,1})

    return fmi2GetBoolean!(fmu.libHandle, fmu.fmi2Component,
        convert(Array{UInt32,1},valueReference), numberOfValueReference, value)
end

function fmi2GetBoolean!(fmu::FMU, valueReference::Union{Array{UInt32,1}, Array{UInt64,1}, Array{Int,1}},
    value::Array{Int32,1})

    return fmi2GetBoolean!(fmu.libHandle, fmu.fmi2Component,
        convert(Array{UInt32,1},valueReference), length(valueReference), value)
end

function fmi2GetBoolean!(fmu::FMU, valueReference::Union{Array{UInt32,1}, Array{UInt64,1}, Array{Bool,1}},
    value::Array{Int32,1})

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
        fmi2Component, valueReference, numberOfValeReference, value
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

function fmi2GetString!(fmu::FMU, valueReference::Array{UInt32,1},
    value::Array{String,1})

    return fmi2GetString!(fmu.libHandle, fmu.fmi2Component, valueReference,
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
        fmi2Component, valueReference, numberOfValeReference, value
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
        fmi2Component, valueReference, numberOfValeReference, value
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

    fmiSGetBoolean(fmu.libHandle, fmu.fmi2Component,
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
        fmi2Component, valueReference, numberOfValeReference, value
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
