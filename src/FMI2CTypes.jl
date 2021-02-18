# This file is part of JuliaFMI.
# Licensed under MIT: https://github.com/AnHeuermann/JuliaFMI/blob/master/LICENSE.txt

# This file contains type definitions and constructores for those types.


using CBinding

"""
Declaration of FMI2 Types
"""

@cenum FMUType {
    modelExchange,
    coSimulation
}

@cenum ModelState {
    modelUninstantiated,
    modelInstantiated,
    modelInitializationMode,
    modelEventMode,
    modelContinuousTimeMode,
    modelStepComplete,
    modelStepProgress,
    modelStepFailed,
    modelStepCancelled,
    modelTerminated,
    modelError,
    modelFatal
}

@cenum FMI2Status {
    fmi2OK,
    fmi2Warning,
    fmi2Discard,
    fmi2Error,
    fmi2Fatal,
    fmi2Pending
}


@ctypedef DynamicPointersCTypedef @cstruct DynamicPointers {
    realValues::Ptr{Nothing} # Vector of Float64
    instanceName::Ptr{Nothing} # Vector of Char
    eventIndicators::Ptr{Nothing} # Vector of CintThatIsActuallyABoolean
    # A lookup that checks if the inputted index (corresponding to a category)
    # is checked for logging.
    categoriesToLogLookup::Ptr{Nothing} # Vector of CintThatIsActuallyABoolean
}
DynamicPointers() = DynamicPointers(zero)

@ctypedef CallbackFunctionsCTypedef @cstruct CallbackFunctions {
    logger::Ptr{Nothing}
    allocateMemory::Ptr{Nothing}
    freeMemory::Ptr{Nothing}
    stepFinished::Ptr{Nothing}
    componentEnvironment::Ptr{Nothing}
}

function CallbackFunctions(;stepFinished::Ptr=C_NULL, componentEnvironment::Ptr=C_NULL)

    fmi2CallbacLogger_Cfunc = dlsym(dlopen(@libLogger), :logger)
    fmi2AllocateMemory_funcWrapC = @cfunction(fmi2AllocateMemory, Ptr{Cvoid}, (Csize_t, Csize_t))
    fmi2FreeMemory_funcWrapC = @cfunction(fmi2FreeMemory, Cvoid, (Ptr{Cvoid},))

    return CallbackFunctions(
        fmi2CallbacLogger_Cfunc,
        fmi2AllocateMemory_funcWrapC,
        fmi2FreeMemory_funcWrapC,
        stepFinished,
        componentEnvironment)
end

function CallbackFunctions(a::Ptr, b::Ptr, c::Ptr, d::Ptr, e::Ptr)
    functions = CallbackFunctions(zero)
    functions.logger = a
    functions.allocateMemory = b
    functions.freeMemory = c
    functions.stepFinished = d
    functions.componentEnvironment = e
    return functions
end



@ctypedef EventInfoCTypedef @cstruct EventInfo {
    newDiscreteStatesNeeded::Cint
    terminateSimulation::Cint
    nominalsOfContinuousStatesChanged::Cint
    valuesOfContinuousStatesChanged::Cint
    nextEventTimeDefined::Cint
    nextEventTime::Cdouble
}
function EventInfo()
    ceventinfo = EventInfo(zero)
    ceventinfo.newDiscreteStatesNeeded = 1
    ceventinfo.terminateSimulation = 1
    ceventinfo.nominalsOfContinuousStatesChanged = 1
    ceventinfo.valuesOfContinuousStatesChanged = 1
    ceventinfo.nextEventTimeDefined = 1
    ceventinfo.nextEventTime = -1.0
    return ceventinfo
end


## Forward reference to FMI2Component
## Pointed to by the fmi2Component void pointer.
@ctypedef FMI2ComponentCType @cstruct FMI2Component {

    functions::Cconst{Ptr{CallbackFunctions}}

   (dynPtrs)::@cstruct {
        realValues::Ptr{Cdouble} # Vector of Float64
        instanceName::Ptr{Cchar} # Vector of Char
        eventIndicators::Ptr{Cint} # Vector of CintThatIsActuallyABoolean
        # A lookup that checks if the inputted index (corresponding to a category)
        # is checked for logging.
        categoriesToLogLookup::Ptr{Cint} # Vector of CintThatIsActuallyABoolean
    }

    eventInfo::EventInfo

    # Caches the status of the do step routines

    doStepStatus::FMI2Status;

    time::Cdouble
    startTime::Cdouble

    stopTime::Cdouble
    stopTimeDefinedFlag::Cint

    tolerance::Cdouble
    toleranceDefinedFlag::Cint

    computeVarFlag::Cint
    loggingOnFlag::Cint

    state::ModelState
    type::FMUType
}

@cenum NamingConvention {
    flat
    structured
}
function str2NamingConvention(inStr::String)
    if inStr =="flat"
        return flat
    elseif inStr == "structured"
        return structured
    else
        error("Can not convert String \"$in\" to NamingConvention.")
    end
end


