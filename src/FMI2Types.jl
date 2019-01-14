"""
Declaration of FMI2 Types
"""

@enum fmi2Status begin
    fmi2OK
    fmi2Warning
    fmi2Discard
    fmi2Error
    fmi2Fatal
    fmi2Pending
end

@enum fmuType begin
    modelExchange
    coSimulation
end

@enum NamingConvention begin
    flat
    structured
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

mutable struct SimulationData
    time::AbstractFloat
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
    relativeQuantity::Boolean
    min::Real
    max::Real
    nominal::Real
    unbound::Boolean

    # Inner constructor
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
end


struct RealProperies
    declaredType::String
    variableAttributes::RealAttributes
    start::Real
    derivative::UInt
    reinit::Boolean

    RealProperties = new()
end

struct IntegerProperies
    declaredType::String
    variableAttributes::IntegerAttributes
    start::Int

    IntegerProperies = new()
end

struct BooleanProperies
    declaredType::String
    start::Int

    BooleanProperies = new()
end

struct ScalarVariable{T<:Union{Real, Int, Bool, String}}
    name::String
    valueReference::Unsigned

    # Optional
    description::String
    causality::String           # TODO: Change to enumeration??
    variability::String         # TODO: Change to enumeration??
    initial::String             # TODO: Change to enumeration??
    canHandleMultipleSetPerTimelnstant::Bool

    # Type specific properties of ScalarVariable
    typeSpecificProperties::Union{RealProperies, IntegerProperties, BooleanProperties, StringProperties}

    # Inner constructors
    function ScalarVariable(name, valueReference)
        if isempty(strip(name))
            errro("ScalarVariable not valid: name can't be empty or only whitespace")
        elseif valueReference < 0
            errro("ScalarVariable not valid: valueReference=$valueReference not unsigned")
        end
        new(name, Unsigned(valueReference), "local", "continous", "", "", false)
    end

    function ScalarVariable(name, valueReference, description, causality,
        variability, initial, canHandleMultipleSetPerTimelnstant)

        # Check name
        if isempty(strip(name))
            errro("ScalarVariable not valid: name can't be empty or only whitespace")
        end

        # Check valueReference
        if valueReference < 0
            errro("ScalarVariable not valid: valueReference=$valueReference not unsigned")
        end

        # Check causality
        if isempty(causality)
            causality = "local"
        elseif !in(causality,["parameter", "calculatedParameter","input", "output", "local", "independent"])
            errro("ScalarVariable not valid: causality has to be one of \"parameter\", \"calculatedParameter\", \"input\", \"output\", \"local\", \"independent\" but is \"$causality\"")
        elseif causality=="parameter"
            if (variability!="fixed" || variability!="tunable")
                errro("ScalarVariable not valid: causality is \"parameter\", so variability has to be \"fixed\" or \"tunable\" but is \"$causality\"")
            end
            if isempty(initial)
                initial = "exact"
            elseif initial!="exact"
                errro("ScalarVariable not valid: causality is \"parameter\", so initial has to be \"exact\" or empty but is \"$initial\"")
            end
        elseif causality=="calculatedParameter"
            if (variability!="fixed" || variability!="tunable")
                errro("ScalarVariable not valid: causality is \"calculatedParameter\", so variability has to be \"fixed\" or \"tunable\" but is \"$causality\"")
            end
            if isempty(initial)
                initial = "calculated"
            elseif !in(initial, ["approx", "calculated"])
                errro("ScalarVariable not valid: causality is \"calculatedParameter\", so initial has to be \"approx\", \"calculated\" or empty but is \"$initial\"")
            end
        elseif causality=="input"
            if !isempty(initial)
                errro("ScalarVariable not valid: causality is \"input\", so initial has to be empty but is \"$initial\"")
            end
        elseif causality=="independent"
            if variability!="continuous"
                errro("ScalarVariable not valid: causality is \"independent\", so variability has to be \"continuous\" but is \"$causality\"")
            end
        end

        # Check variability
        if isempty(variability)
            variability = "continous"
        elseif !in(causvariabilityality, ["constant", "fixed","tunable", "discrete", "continuous"])
            errro("ScalarVariable not valid: variability has to be one of \"constant\", \"fixed\",\"tunable\", \"discrete\" or \"continuous\" but is \"$variability\"")
        end

        new(name, Unsigned(valueReference), causality, variability, initial, canHandleMultipleSetPerTimelnstant)
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
    modelVariables::Array{ScalarVariable}

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

    simulationData::SimulationData

    experimentData::ExperimentData

    status

    # Other stuff
    libHandle::Ptr{Nothing}
    tmpFolder::String
    fmuType::fmuType
    fmiCallbackFunctions::CallbackFunctions
    fmi2Component::Ptr{Nothing}

    # Constructor
    FMU() = new()
end
