"""
Simulator for FMUs of
FMI 2.0 for Model Exchange Standard
"""

using(Libdl)      # For using dlopen and so on

include("FMIWrapper.jl")


mutable struct SimulationData
    time::AbstractFloat
end

mutable struct ExperimentData
    startTime::AbstractFloat
    stopTime::AbstractFloat

    stepSize::AbstractFloat

    maximumNumberOfSteps::Unsigned
end



"""
Containing all informations from modelDescription.xml
"""
@enum NamingConvention begin
    flat
    structured
end

mutable struct VariableNamingConvention
    type::String
    enum::NamingConvention               # flat or structured
end

mutable struct ModelVariable{T<:Real}
    name::String
    valueReference::Integer
    variability::String
    causality::String
    initial::String

    type::String                # real, int, bool, string, enumeration
    start::T
    derivative::T
end

mutable struct Derivatives
    index::Integer
    dependencies::Array{Integer,1}          # indices of all dependencies
    dependenciesKind::Array{String,1}       # e.g "dependent"
end

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
    variableNamingConvention::VariableNamingConvention
    numberOfEventIndicators::Integer

    # Model exchange
    isModelExchange::Bool
    # Co-Simulation
    isCoSimulation::Bool
    modelIdentifier::String

    # Unit definitions
    # Type definitions
    # ToDo: add here

    logCategories::Array{String,1}

    # Default experiment
    startTime::Real
    stopTime::Real
    tolerance::Real

    # Vendor annotations

    # Model variables
    variables::Array{ModelVariable,1}

    # Model structure
    dependencies::Array{Derivatives,1}
end

"""
Functional Mockupt Unit (FMU) struct.
"""
mutable struct FMU
    modelName::String
    instanceName::String
    FMUPath::String       # ToDo: find better type for path
    fmuResourceLocation::String
    fmuGUUID::String

    modelDescription::ModelDescription

    simulationData::SimulationData

    experimentData::ExperimentData

    status
end









function loadFMU(pathToFMU::String)

    # Name of tmp folder
    tmpFolder = "tmp"

    # unzip FMU to tmp folder
    run("unzip $tmpFolder/$pathToFMU");

    # parse modelDescription.xml


    # load dynamic library
    libHandle = dlopen(tmpFolder)
end



function unloadFMU(libHandle::Ptr{Nothing})

    # unload dynamic library
    dlclose(libHandle)

    # delete tmp folder
end


function readModelDescription(pathToModelDescription::String)

    md = ModelDescription

    md.fmiVersion

    return md
end
