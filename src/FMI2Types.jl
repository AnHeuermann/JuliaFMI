"""
Declaration of FMI2 Types
"""

@enum fmuType begin
    modelExchange
    coSimulation
end

@enum NamingConvention begin
    flat
    structured
end
function NamingConvention(in::String)
    if in=="flat"
        return flat
    elseif in == "structured"
        return structured
    else
        error("Can not convert String \"$in\" to NamingConvention.")
    end
end

@enum ModelState begin
    modelUninstantiated
    modelInstantiated
    modelInitializationMode
    modelContinuousTimeMode
    modelEventMode
    modelTerminated
    modelError
    modelFatal
end

# FMI2 Errors
struct FMI2Warning <: Exception
    msg::String
end
FMI2Warning() = FMI2Warning("")
Base.showerror(io::IO, e::FMI2Warning) = print(io, "fmi2Warning", isempty(e.msg) ? "" : ": ", e.msg)

struct FMI2Discard <: Exception
    msg::String
end
FMI2Discard() = FMI2Discard("")
Base.showerror(io::IO, e::FMI2Discard) = print(io, "fmi2Discard", isempty(e.msg) ? "" : ": ", e.msg)

struct FMI2Error <: Exception
    msg::String
end
FMI2Error() = FMI2Error("")
Base.showerror(io::IO, e::FMI2Error) = print(io, "fmi2Error", isempty(e.msg) ? "" : ": ", e.msg)

struct FMI2Fatal <: Exception
    msg::String
end
FMI2Fatal() = FMI2Fatal("")
Base.showerror(io::IO, e::FMI2Fatal) = print(io, "fmi2Fatal", isempty(e.msg) ? "" : ": ", e.msg)

struct FMI2Pending <: Exception
    msg::String
end
FMI2Pending() = FMI2Pending("")
Base.showerror(io::IO, e::FMI2Pending) = print(io, "fmi2Pending", isempty(e.msg) ? "" : ": ", e.msg)

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
struct CallbackFunctions
    callbackLogger::Ptr{Nothing}
    allocateMemory::Ptr{Nothing}
    freeMemory::Ptr{Nothing}
    stepFinished::Ptr{Nothing}

    componentEnvironmendt::Ptr{Nothing}
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
    value::Bool
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
    #TODO Add

    EnumerationVariable() = new()
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
    relativeQuantity::Bool
    min::Real
    max::Real
    nominal::Real
    unbound::Bool

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


struct RealProperties
    declaredType::String
    variableAttributes::RealAttributes
    start::Float64
    derivative::UInt
    reinit::Bool

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
    start::Bool

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
    canHandleMultipleSetPerTimelnstant::Bool

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
    isModelExchange::Bool
    # Co-Simulation
    isCoSimulation::Bool
    modelIdentifier::String

    # Unit definitions
    # Type definitions
    # TODO: add here

    logCategories::Array{LogCategory}

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
    newDiscreteStatesNeeded::Bool
    terminateSimulation::Bool
    nominalsOfContinuousStatesChanged::Bool
    valuesOfContinuousStatesChanged::Bool
    nextEventTimeDefined::Bool
    nextEventTime::Float64

    EventInfo() = new(true, true, true, true, true, -1.0)
end


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
    fmuType::fmuType
    fmiCallbackFunctions::CallbackFunctions
    fmi2Component::Ptr{Nothing}

    # Constructor
    FMU() = new()
end
