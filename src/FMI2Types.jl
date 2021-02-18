# This file is part of JuliaFMI.
# Licensed under MIT: https://github.com/AnHeuermann/JuliaFMI/blob/master/LICENSE.txt

# This file contains type definitions and constructores for those types.

# The Spec talks about Booleans, which are implemented in c as
#   `#DEFINE FALSE = 0`
#   `#DEFINE TRUE = 1`
# Which are 32 bit integers. Hence the c code expects Booleans to take up 32 bits of space
# The Julia codebase so far has implemented Bools (1 bit integers) and uses them as such.
# Swap out Bools for Cints, but make it obvious so it can be refactored later; TODO!
const CintThatIsActuallyABoolean = Cint

"""
Declaration of FMI2 Types
"""


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


@ctypedef DynamicPointersCTypedef @cstruct DynamicPointersC {
    realValues::Ptr{Nothing} # Vector of Float64
    instanceName::Ptr{Nothing} # Vector of Char
    eventIndicators::Ptr{Nothing} # Vector of CintThatIsActuallyABoolean
    # A lookup that checks if the inputted index (corresponding to a category)
    # is checked for logging.
    categoriesToLogLookup::Ptr{Nothing} # Vector of CintThatIsActuallyABoolean
}
DynamicPointersC() = DynamicPointersC(zero)

@ctypedef CallbackFunctionsCTypedef @cstruct CallbackFunctionsC {
    logger::Ptr{Nothing}
    allocateMemory::Ptr{Nothing}
    freeMemory::Ptr{Nothing}
    stepFinished::Ptr{Nothing}

    componentEnvironment::Ptr{Nothing}
}
CallbackFunctionsC() = CallbackFunctionsC(zero)

@ctypedef EventInfoCTypedef @cstruct EventInfoC {
    newDiscreteStatesNeeded::Cint
    terminateSimulation::Cint
    nominalsOfContinuousStatesChanged::Cint
    valuesOfContinuousStatesChanged::Cint
    nextEventTimeDefined::Cint
    nextEventTime::Cdouble
}
function EventInfoC()
  ceventinfo = EventInfoC(zero)
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
    #const fmi2CallbackFunctions* functions;
    functions::Cconst{Ptr{CallbackFunctionsC}}

    # A structure containing all the pointers
    # that point to dynamically allocated memory.
    # struct {
    #     fmi2Real* realValues;
    #     fmi2Char* instanceName;
    #     fmi2Boolean* eventIndicators;
    #     # A lookup that checks if the inputted index (corresponding to a category)
    #     # is checked for logging.
    #     fmi2Boolean* categoriesToLogLookup;
    # } dynPtrs;

   (dynPtrs)::@cstruct {
        realValues::Ptr{Cdouble} # Vector of Float64
        instanceName::Ptr{Cchar} # Vector of Char
        eventIndicators::Ptr{Cint} # Vector of CintThatIsActuallyABoolean
        # A lookup that checks if the inputted index (corresponding to a category)
        # is checked for logging.
        categoriesToLogLookup::Ptr{Cint} # Vector of CintThatIsActuallyABoolean
    }

    #= Commented out in the c
    # A list of real values of size NUMBER_REALS
    #fmi2Real* realValues;
    realValues::Ptr{Cdouble}

    # A null terminated char string of the instance name
    #fmi2Char* instanceName;
    instanceName::Ptr{Cchar}
    #fmi2Boolean* eventIndicators; // Indicates whether an event has occured.
    eventIndicators::Ptr{Cint}
    =#

    #fmi2EventInfo eventInfo;
    eventInfo::EventInfoC

    # Caches the status of the do step routines
    #fmi2Status doStepStatus;
    doStepStatus::FMI2Status;

    #fmi2Real time;
    time::Cdouble
    #fmi2Real startTime;
    startTime::Cdouble

    #fmi2Real stopTime;
    stopTime::Cdouble
    #fmi2Boolean stopTimeDefinedFlag;
    stopTimeDefinedFlag::Cint

    #fmi2Real tolerance;
    tolerance::Cdouble
    #fmi2Boolean toleranceDefinedFlag;
    toleranceDefinedFlag::Cint

    #fmi2Boolean computeVarFlag; # A flag that when true, updates the variables. e.g calculates all the derivatives
    computeVarFlag::Cint
    #fmi2Boolean loggingOnFlag;
    loggingOnFlag::Cint

    #enum FMUMode state;
    state::ModelState
    #fmi2Type type;
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

#@enum ModelState begin
#    modelUninstantiated
#    modelInstantiated
#    modelInitializationMode
#    modelEventMode
#    modelContinuousTimeMode
#    modelStepComplete
#    modelStepProgress
#    modelStepFailed
#    modelStepCancelled
#    modelTerminated
#    modelError
#    modelFatal
#end

# FMU_MODE_START_END = 1,
# FMU_MODE_INSTANTIATED = 1 << 1,
# FMU_MODE_INITIALISED = 1 << 2,
#
# // Model Exchange
# FMU_MODE_EVENT = 1 << 3,
# FMU_MODE_CONTINUOUS_TIME = 1 << 4,
#
# // Cosim
# FMU_MODE_STEP_COMPLETE = 1 << 5,
# FMU_MODE_STEP_PROGRESS = 1 << 6,
# FMU_MODE_STEP_FAILED = 1 << 7,
# FMU_MODE_STEP_CANCELLED = 1 << 8,
#
# FMU_MODE_TERMINATED = 1 << 9,
# FMU_MODE_ERROR = 1 << 10,
# FMU_MODE_FATAL = 1 << 11,

# FMI2 Errors
struct FMI2Warning <: Exception
    msg::AbstractString
end
function Base.showerror(io::IO, e::FMI2Warning)
    print(io, "fmi2Warning", isempty(e.msg) ? "" : ": ", e.msg)
end

struct FMI2Discard <: Exception
    msg::AbstractString
end
function Base.showerror(io::IO, e::FMI2Discard)
    print(io, "fmi2Discard", isempty(e.msg) ? "" : ": ", e.msg)
end

struct FMI2Error <: Exception
    msg::AbstractString
end
function Base.showerror(io::IO, e::FMI2Error)
    print(io, "fmi2Error", isempty(e.msg) ? "" : ": ", e.msg)
end

struct FMI2Fatal <: Exception
    msg::AbstractString
end
function Base.showerror(io::IO, e::FMI2Fatal)
    print(io, "fmi2Fatal", isempty(e.msg) ? "" : ": ", e.msg)
end

struct FMI2Pending <: Exception
    msg::AbstractString
end
function Base.showerror(io::IO, e::FMI2Pending)
    print(io, "fmi2Pending", isempty(e.msg) ? "" : ": ", e.msg)
end

function fmiError(fmi2Status::Union{Unsigned, Integer}, message::String="")
    if fmi2Status == 1
        return FMI2Warning(message)
    elseif fmi2Status == 2
        return FMI2Discard(message)
    elseif fmi2Status == 3
        return FMI2Error(message)
    elseif fmi2Status ==  4
        return FMI2Fatal(message)
    elseif fmi2Status == 5
        return FMI2Pending(message)
    else
        return FMI2Error("Unknown error code")
    end
end


# Pointers to functions provided by the environment to be used by the FMU
mutable struct CallbackFunctions
    logger::Ptr{Nothing}
    allocateMemory::Ptr{Nothing}
    freeMemory::Ptr{Nothing}
    stepFinished::Ptr{Nothing}

    componentEnvironment::Ptr{Nothing}
end

function CallbackFunctions()
    fmi2CallbacLogger_Cfunc = dlsym(dlopen(@libLogger), :logger)
    fmi2AllocateMemory_funcWrapC = @cfunction(fmi2AllocateMemory, Ptr{Cvoid}, (Csize_t, Csize_t))
    fmi2FreeMemory_funcWrapC = @cfunction(fmi2FreeMemory, Cvoid, (Ptr{Cvoid},))
    return CallbackFunctions(
        fmi2CallbacLogger_Cfunc,            # Logger in C
        fmi2AllocateMemory_funcWrapC,
        fmi2FreeMemory_funcWrapC,
        C_NULL,
        C_NULL)
end


mutable struct fmi2ComponentEnvironment
    logFile::String     # if not empty location of file to write logger messages
                        # defaults to stderr ??
    numWarnings::Int
    numErrors::Int
    numFatals::Int
end

mutable struct RealVariable
    value::Float64
    valueReference::UInt
    name::String

    # attributes
    min::Float64
    max::Float64

    # Inner constructors
    RealVariable()=new()
    function RealVariable(value, valueReference, name)
        new(value, valueReference, name, -Inf64, Inf64)
    end
end

mutable struct IntVariable
    value::Int64
    valueReference::UInt
    name::String

    # attributes
    min::Int64
    max::Int64

    # Inner constructors
    IntVariable()=new()
    function IntVariable(value, valueReference, name)
        new(value, valueReference, name, -(2^63 - 1), 2^63 - 1)
    end
end

mutable struct BoolVariable
    value::CintThatIsActuallyABoolean
    valueReference::UInt
    name::String

    # Inner Constructors
    BoolVariable() = new()
    function BoolVariable(value, valueReference, name)
        new(value, valueReference, name)
    end
end

mutable struct StringVariable
    value::String
    valueReference::UInt
    name::String

    # Inner constructors
    StringVariable() = new()
    function StringVariable(value, valueReference, name)
        new(value, valueReference, name)
    end
end

mutable struct EnumerationVariable
    value::UInt     # Holds a number representig an enumeration
    valueReference::UInt
    name::String

    # Inner constructors
    EnumerationVariable() = new()
    function EnumerationVariable(value, valueReference, name)
        new(value, valueReference, name)
    end
end

mutable struct ModelVariables
    reals::Array{RealVariable,1}
    ints::Array{IntVariable,1}
    bools::Array{BoolVariable,1}
    strings::Array{StringVariable,1}
    enumerations::Array{EnumerationVariable,1}

    function ModelVariables(n_reals, n_ints, n_bools, n_strings, n_enumerations)

        reals = Array{RealVariable}(undef, n_reals)
        ints = Array{IntVariable}(undef, n_ints)
        bools = Array{BoolVariable}(undef, n_bools)
        strings = Array{StringVariable}(undef, n_strings)
        enumerations = Array{EnumerationVariable}(undef, n_enumerations)

        new(reals, ints, bools, strings, enumerations)
    end
end

mutable struct SimulationData
    time::AbstractFloat
    lastStepTime::AbstractFloat
    modelVariables::ModelVariables
    eventIndicators::Array{Float64}

    SimulationData()=new()
    function SimulationData(n_reals, n_ints, n_bools, n_strings, n_enumerations,
        numberOfEventIndicators)

        modelVariables=ModelVariables(n_reals, n_ints, n_bools, n_strings,
            n_enumerations)
        eventIndicators = Array{Float64}(undef, numberOfEventIndicators)
        new(0, 0, modelVariables, eventIndicators)
    end
end

mutable struct ModelData
    numberOfStates::Int
    numberOfDerivatives::Int    # Is always numberOfStates

    numberOfReals::Int
    numberOfInts::Int
    numberOfBools::Int
    numberOfStrings::Int
    numberOfEnumerations::Int
    numberOfExterns::Int

    numberOfEventIndicators::Int

    ModelData() = new(0,0,0,0,0,0,0,0)
end

mutable struct ExperimentData
    startTime::AbstractFloat
    stopTime::AbstractFloat
    tolerance::AbstractFloat
    stepSize::AbstractFloat

    # Inner constructors
    ExperimentData() = new(0, 1, 1e-6, 1e-6/4)
    function ExperimentData(startTime, stopTime, tolerance, stepSize)
        if startTime >= stopTime
            error("ExperimentData not valid: startTime=$startTime >= stopTime=$stopTime")
        elseif tolerance <= 0
            error("ExperimentData not valid: tolerance=$tolerance not greater than zero")
        elseif stepSize <= 0
            error("ExperimentData not valid: stepSize=$stepSize not greater than zero")
        end
        new(startTime, stopTime, tolerance, stepSize)
    end
end


struct RealAttributes
    quantity::String
    unit::String            # TODO: make types for Units and functions
    displayUnit::String     #       for unit conversion
    relativeQuantity::CintThatIsActuallyABoolean
    min::Real
    max::Real
    nominal::Real
    unbound::CintThatIsActuallyABoolean

    # Inner constructor
    RealAttributes() = new()

    function RealAttributes(quantity, unit, displayUnit, relativeQuantity,
        min, max, nominal, unbound)

        if nominal <= 0
            error("Nominal > 0.0 required")
        elseif min > max
            error("Minimum is greater than maximum")
        end

        new(quantity, unit, displayUnit, relativeQuantity, min, max, nominal,
            unbound)
    end

    function RealAttributes(quantity, unit, displayUnit, min, max, nominal)

        if nominal <= 0
            error("Nominal > 0.0 required")
        elseif min > max
            error("Minimum is greater than maximum")
        end

        new(quantity, unit, displayUnit, false, min, max, nominal, false)
    end
end

struct IntegerAttributes
    quantity::String
    min::Int
    max::Int

    # Inner constructors
    IntegerAttributes()=new()
    IntegerAttributes(quantity, min, max)=new(quantity, min, max)
end

"""
Item of an enumeartion attribute
"""
struct EnumerationItemAttribute
    name::String
    "Unique number in the same enumeration"
    value::Int
    description::String

    # Constructor
    EnumerationItemAttribute() = new()
    EnumerationItemAttribute(name, value, description) = new(name, value, description)
end

"""
Attributes for simpleType enumeration
"""
struct EnumerationAttributes
    "Physical quantity of the variable"
    quantity::String
    "Items of an enumeration"
    items::Array{EnumerationItemAttribute}

    # Constructor
    EnumerationAttributes() = new()
    EnumerationAttributes(quantity, items) = new(quantity, items)
end


struct RealProperties
    declaredType::String
    variableAttributes::RealAttributes
    start::Float64
    derivative::UInt
    reinit::CintThatIsActuallyABoolean

    # Inner constructors
    RealProperties() = new()
    RealProperties(declaredType, variableAttributes, start, derivative, reinit) = new(declaredType, variableAttributes, start, derivative, reinit)
    function RealProperties(declaredType, variableAttributes, start, derivative, reinit_in::String)
        if reinit_in == "true"
            reinit = true
        elseif reinit_in == "false"
            reinit = false
        else
            error("Could not parste input reinit=$reinit_in to Bool.")
        end

        return new(declaredType, variableAttributes, start, derivative, reinit)
    end
end

struct IntegerProperties
    declaredType::String
    variableAttributes::IntegerAttributes
    start::Int

    # Inner constructors
    IntegerProperies() = new()
    IntegerProperties(declaredType, variableAttributes, start) = new(declaredType, variableAttributes, start)
end

struct BooleanProperties
    declaredType::String
    start::CintThatIsActuallyABoolean

    BooleanProperties() = new()
    BooleanProperties(declaredType, start) = new(declaredType, start)
end

struct StringProperties
    declaredType::String
    start::String

    StringProperties() = new()
    StringProperties(declaredType, start) = new(declaredType, start)
end

struct EnumerationProperties
    declaredType::String
    quantity::String
    min::Int
    max::Int
    start::Int

    EnumerationProperties() = new()
    EnumerationProperties(declaredType, quantity, min, max, start) = new(declaredType, quantity, min, max, start)
end

struct ScalarVariable
    name::String
    valueReference::Unsigned

    # Optional
    description::String
    causality::String           # TODO: Change to enumeration??
    variability::String         # TODO: Change to enumeration??
    initial::String             # TODO: Change to enumeration??
    canHandleMultipleSetPerTimelnstant::CintThatIsActuallyABoolean

    # Type specific properties of ScalarVariable
    typeSpecificProperties::Union{RealProperties, IntegerProperties, BooleanProperties, StringProperties, EnumerationProperties}

    # Inner constructors
    function ScalarVariable(name, valueReference, description, typeSpecificProperties)
        if isempty(strip(name))
            error("ScalarVariable $name not valid: name can't be empty or only whitespace")
        elseif valueReference < 0
            error("ScalarVariable $name not valid: valueReference=$valueReference not unsigned")
        end
        new(name, Unsigned(valueReference), description, "local", "continous", "", false, typeSpecificProperties)
    end

    function ScalarVariable(name, valueReference, description, causality,
        variability, initial, canHandleMultipleSetPerTimelnstant, typeSpecificProperties)

        # Check name
        if isempty(strip(name))
            error("ScalarVariable $name not valid: name can't be empty or only whitespace")
        end

        # Check valueReference
        if valueReference < 0
            error("ScalarVariable $name not valid: valueReference=$valueReference not unsigned")
        end

        #check if causality and variability are correct
        if isempty(variability)
            variability = "continuous"
        elseif !in(variability, ["constant", "fixed", "tunable", "discrete", "continuous"])
            error("ScalarVariable $name not valid: variability has to be one of \"constant\", \"fixed\", \"tunable\", \"discrete\" or \"continuous\" but is \"$variability\"")
        end

        if isempty(causality)
            causality = "local"
        elseif !in(causality,["parameter", "calculatedParameter","input", "output", "local", "independent"])
          error("ScalarVariable $name not valid: causality has to be one of \"parameter\", \"calculatedParameter\", \"input\", \"output\", \"local\", \"independent\" but is \"$causality\"")
        elseif causality == "parameter"
            if (variability!="fixed" && variability!="tunable" && variability!="constant")
                error("ScalarVariable $name not valid: causality is \"parameter\", so variability has to be \"fixed\" or \"tunable\" but is \"$variability\"")
            end
            if isempty(initial)
                initial = "exact"
            elseif initial!="exact"
                error("ScalarVariable $name not valid: causality is \"parameter\", so initial has to be \"exact\" or empty but is \"$initial\"")
            end
        elseif causality=="calculatedParameter"
            if (variability!="fixed" && variability!="tunable")
                error("ScalarVariable $name not valid: causality is \"calculatedParameter\", so variability has to be \"fixed\" or \"tunable\" but is \"$variability\"")
            end
            if isempty(initial)
                initial = "calculated"
            elseif !in(initial, ["approx", "calculated"])
                error("ScalarVariable $name not valid: causality is \"calculatedParameter\", so initial has to be \"approx\", \"calculated\" or empty but is \"$initial\"")
            end
        elseif causality=="input"
            if !isempty(initial)
                error("ScalarVariable $name not valid: causality is \"input\", so initial has to be empty but is \"$initial\"")
            end
        elseif causality=="independent"
            if variability!="continuous"
                error("ScalarVariable $name not valid: causality is \"independent\", so variability has to be \"continuous\" but is \"$causality\"")
            end
        end

        new(name, Unsigned(valueReference), description, causality, variability, initial, canHandleMultipleSetPerTimelnstant, typeSpecificProperties)
    end
end

"""
Definition of a simple type according to fmi2SimpleType
"""
struct SimpleType
    "Unique name with respect to all other element of TypeDefinitions in ModelDescription"
    name::String
    description::String

    # ToDo: Add Bool and String to this, maybe as empty Attributes?
    attributes::Union{RealAttributes, IntegerAttributes, EnumerationAttributes}

    # Constructor
    SimpleType() = new()
    SimpleType(name, description, attributes)=new(name, description, attributes)
end

struct LogCategory
    name::String
    description::String

    LogCategory(name) = new(name, "")
    LogCategory(name, description) = new(name, description)
end

"""
Containing all informations from modelDescription.xml
"""
mutable struct ModelDescription
    # FMI model description
    fmiVersion::String
    modelName::String
    guid::String
    description::String
    author::String
    version::String
    copyright::String
    license::String
    generationTool::String
    generationDateAndTime::String
    variableNamingConvention::NamingConvention
    numberOfEventIndicators::Int

    # Model exchange
    isModelExchange::CintThatIsActuallyABoolean
    # Co-Simulation
    isCoSimulation::CintThatIsActuallyABoolean
    modelIdentifier::String

    # Unit definitions
    # Type definitions
    typeDefinitions::Union{Array{SimpleType}, Nothing}

    logCategories::Union{Array{LogCategory}, Nothing}

    # Default experiment
    defaultExperiment::ExperimentData

    # Vendor annotations

    # Model variables
    modelVariables::Array{ScalarVariable,1}

    # Model structure
    modelStructure

    # Constructor for uninitialized struct
    function ModelDescription()
        md = new()
        md.isModelExchange = false
        md.isCoSimulation = false
        return md
    end
end


mutable struct EventInfo
    newDiscreteStatesNeeded::CintThatIsActuallyABoolean
    terminateSimulation::CintThatIsActuallyABoolean
    nominalsOfContinuousStatesChanged::CintThatIsActuallyABoolean
    valuesOfContinuousStatesChanged::CintThatIsActuallyABoolean
    nextEventTimeDefined::CintThatIsActuallyABoolean
    nextEventTime::Float64

    EventInfo() = new(true, true, true, true, true, -1.0)
end
struct DynamicPointers
    realValues::Ptr{Cdouble} # Vector of Float64
    instanceName::Ptr{Cchar} # Vector of Char
    eventIndicators::Ptr{Cint} # Vector of CintThatIsActuallyABoolean
    # A lookup that checks if the inputted index (corresponding to a category)
    # is checked for logging.
    categoriesToLogLookup::Ptr{Cint} # Vector of CintThatIsActuallyABoolean

    DynamicPointers() = new()
end


#mutable struct FMI2Component
#    # Pointers to functions in the sim environment that we can call from the
#    # fmu environment.
#    functions::Ptr{Nothing}
#
#    # A structure containing all the pointers
#    # that point to dynamically allocated memory.
#    dynPtrs::DynamicPointers
#
#    # A list of real values of size NUMBER_REALS
#    #fmi2Real* realValues; # this is commented out in the c
#
#    # A null terminated char string of the instance name
#    #fmi2Char* instanceName; # this is commented out in the c
#    #fmi2Boolean* eventIndicators; // Indicates whether an event has occured. # this is commented out in the c
#
#    eventInfo::EventInfo
#
#    # Caches the status of the do step routines
#    doStepStatus::FMI2Warning
#
#    time::Float64
#    startTime::Float64
#
#    stopTime::Float64
#    stopTimeDefinedFlag::CintThatIsActuallyABoolean
#
#    tolerance::Float64
#    toleranceDefinedFlag::CintThatIsActuallyABoolean
#
#    # A flag that when true, updates the variables. e.g calculates all the derivatives
#    computeVarFlag::CintThatIsActuallyABoolean
#    loggingOnFlag::CintThatIsActuallyABoolean
#
#    state::ModelState
#    type::FMUType
#
#    FMI2Component() = new()
#end


"""
Functional Mockupt Unit (FMU) struct.
"""
mutable struct FMU
    modelName::String
    instanceName::String
    FMUPath::String                     # TODO: find better type for paths
    fmuResourceLocation::String         # is URI
    fmuGUID::String

    modelDescription::ModelDescription

    modelData::ModelData

    simulationData::SimulationData

    experimentData::ExperimentData

    eventInfo::EventInfo

    modelState::ModelState

    # CSV and log file
    csvFile::IOStream
    logFile::IOStream

    # Other stuff
    libHandle::Ptr{Nothing}
    libLoggerHandle::Ptr{Nothing}
    tmpFolder::String
    fmuType::FMUType
    functions::CallbackFunctions
    fmi2Component::Ptr{Nothing}

    # Constructor
    FMU() = new()
end
