# This file is part of JuliaFMI.
# License is MIT: https://servant-om.fh-bielefeld.de/gitlab/AnHeuermann/FMU_JL_Simulator/blob/master/LICENSE.txt

# This file contains wrapper to call FMI functions

include("FMI2Types.jl")
include("FMICallbackFunctions.jl") # Callbacks for logging and memory handling


# ##############################################################################
# Creation, Destruction and Logging of FMU Instances
# ##############################################################################

"""
```
fmi2Instantiate(fmu::FMU)

fmi2Instantiate(libHandle::Ptr{Nothing}, instanceName::String,
                fmuType::fmuType, fmuGUID::String, fmuResourceLocation::String,
                functions::CallbackFunctions, visible::Bool, loggingOn::Bool)
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
      error("fmi2Instantiate: Returned NULL.")
    end

    return fmi2Component
end

function fmi2Instantiate!(fmu::FMU)
    fmu.fmi2Component = fmi2Instantiate(fmu.libHandle, fmu.instanceName,
        fmu.fmuType, fmu.fmuGUID, fmu.fmuResourceLocation,
        fmu.fmiCallbackFunctions, true, true)
end

"""
    `fmi2FreeInstance(libHandle::Ptr{Nothing}, fmi2Component::Ptr{Nothing})`
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

    if status != UInt(fmi2OK)
        error("fmi2SetDebugLogging returned not status \"fmiOk\"")
    end
end

function fmi2SetDebugLogging(libHandle::Ptr{Nothing},
    fmi2Component::Ptr{Nothing}, loggingOn::Bool, nCategories::UInt,
    categories::Array{String,1})

    if nCategories > 0
        error("\"nCategories\" has to be positive but is $nCategories")
    elseif length(categories) != nCategories
        error("nCategories=$nCategories does not match length(categories)=$(length(categories))")
    end

    func = dlsym(libHandle, :fmi2SetDebugLogging)

    status = ccall(
        func,
        Cuint,
        (Ptr{Cvoid}, Cint, Csize_t, Ptr{Cstring}),
        fmi2Component, loggingOn, nCategories, categories
        )

    if status != UInt(fmi2OK)
        println(status)
        println(typeof(status))
        error("fmi2SetDebugLogging returned not status \"fmiOk\"")
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
