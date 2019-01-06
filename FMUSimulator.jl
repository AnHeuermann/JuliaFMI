"""
Simulator for FMUs of
FMI 2.0 for Model Exchange Standard
"""

using Libdl         # For using dlopen, dlclose and so on
using InfoZIP       # For unzipping FMU
using LightXML      # For parsing XML files

include("FMIWrapper.jl")


@enum NamingConvention begin
    flat
    structured
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

abstract type VariableType end
abstract type RealType <: VariableType end
abstract type IntegerType <: VariableType end
abstract type BooleanType <: VariableType end
abstract type StringType <: VariableType end
abstract type EnumerationType <: VariableType end

struct AbstractVariable
    type::VariableType
end


struct ScalarVariable
    name::String
    valueReference::Unsigned

    # Optional
    description::String
    causality::String           # ToDo: Change to enumeration??
    variability::String         # ToDo: Change to enumeration??
    initial::String             # ToDo: Change to enumeration??
    canHandleMultipleSetPerTimelnstant::Bool

    # Type specific properties of ScalarVariable
    variableProperties::AbstractVariable

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
    # ToDo: add here

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
    FMUPath::String       # ToDo: find better type for path
    fmuResourceLocation::String
    fmuGUUID::String

    modelDescription::ModelDescription

    simulationData::SimulationData

    experimentData::ExperimentData

    status
end


"""
Parse modelDescription.xml
"""
function readModelDescription(pathToModelDescription::String)

    md = ModelDescription()

    # Parse modelDescription
    xdoc = parse_file(pathToModelDescription)

    # Check root tag
    xroot = root(xdoc)
    if name(xroot)!="fmiModelDescription"
        error("While parsing modelDescription:
            modelDescription-XML not correct.")
    end

    # Get attributes of tag <fmiModelDescription>
    attributes = attributes_dict(xroot)
    try
        md.fmiVersion = attributes["fmiVersion"]
        md.modelName = attributes["modelName"]
        md.guid = attributes["guid"]

        md.description = get(attributes, "description", "")
        md.author = get(attributes, "author", "")
        md.version = get(attributes, "version", "")
        md.copyright = get(attributes, "copyright", "")
        md.license = get(attributes, "license", "")
        md.generationTool = get(attributes, "generationTool", "")
        md.generationDateAndTime = get(attributes, "generationDateAndTime", "")

        if attributes["variableNamingConvention"]=="flat"
            md.variableNamingConvention =  flat
        elseif attributes["variableNamingConvention"]=="structured"
            md.variableNamingConvention =  structured
        else
            error("Unknown variableNamingConvention")
        end
        md.numberOfEventIndicators = parse(Int, attributes["numberOfEventIndicators"])

        # Get attributes of tag <ModelExchange>
        elementModelExchange = find_element(xroot, "ModelExchange")

        # Get attributes of tag <CoSimulation>
        elementCoSimulation = find_element(xroot, "CoSimulation")

        try
            if elementModelExchange != nothing
                md.isModelExchange = true
                md.modelIdentifier = attribute(elementModelExchange, "modelIdentifier"; required=true)
            else
                md.isModelExchange = false
                error("While parsing modelDescription: Only ModelExchange is supported yet but
                    FMU does not support ModelExchange.")
            end

            if elementCoSimulation != nothing
                md.isCoSimulation = true
                md.modelIdentifier = attribute(elementModelExchange, "modelIdentifier"; required=true)
            else
                md.isCoSimulation = false
            end
        catch err
            if isa(err, LightXML.XMLAttributeNotFound)
                error("While parsing modelDescription: Non-optinal element \"modelIdentifier\" not found")
            else
                rethrow(err)
            end
        end

        if elementCoSimulation == nothing && elementModelExchange == nothing
            error("modelDescription.xml is missing ModelExchange and CoSimulation tags.")
        end

        # ToDo: Add stuff for tag UnitDefinitions

        # ToDo: Add stuff for tag TypeDefinitions

        # Get attributes of tag LogCategories
        elementLogCategories = find_element(xroot, "LogCategories")
        if elementLogCategories != nothing
            numCategories = 0
            for element in child_elements(elementLogCategories)
                numCategories += 1
            end
            md.logCategories = Array{LogCategory}(undef, numCategories)

            for (index, element) in enumerate(child_elements(elementLogCategories))
                tmp_name = attribute(element, "name"; required=false)
                tmp_description = attribute(element, "description"; required=false)
                if tmp_description == nothing
                    md.logCategories[index] = LogCategory(tmp_name)
                else
                    md.logCategories[index] = LogCategory(tmp_name, tmp_description)
                end
            end
        end

        # Get attributes of tag DefaultExperiment
        elementDefaultExperiment = find_element(xroot, "DefaultExperiment")
        if elementDefaultExperiment != nothing
            startTime = attribute(elementDefaultExperiment, "startTime"; required=false)
            if startTime != nothing
                startTime = parse(Float64, startTime)
            else
                startTime = 0
            end

            stopTime = attribute(elementDefaultExperiment, "stopTime"; required=false)
            if startTime != nothing
                stopTime = parse(Float64, stopTime)
            else
                stopTime = startTime+1
            end

            tolerance = attribute(elementDefaultExperiment, "tolerance"; required=false)
            if tolerance != nothing
                tolerance = parse(Float64, tolerance)
            else
                tolerance = 1e-6
            end

            stepSize = attribute(elementDefaultExperiment, "stepSize"; required=false)
            if stepSize != nothing
                stepSize = parse(Float64, stepSize)
            else
                stepSize = 1e-6/4
            end

            md.defaultExperiment = ExperimentData(startTime, stopTime, tolerance, stepSize)
        else
            md.defaultExperiment = ExperimentData()
        end

        # ToDo: Add stuff for tag VendorAnnotations

        # Get attributes of tag ModelVariables
        elementModelVariables = find_element(xroot, "ModelVariables")
        if ModelVariables == nothing
            error("modelDescription.xml is missing ModelVariables tag")
        end

        numberOfVariables = 0
        for element in child_nodes(x)
            numberOfVariables += 1
        end
        md.modelVariables

        # Get attributes of tag ModelStructure


    catch err
        if isa(err, KeyError)
            error("While parsing modelDescription: Non-optinal element \"$(err.key)\" not found")
        else
            rethrow(err)
        end
    end

    # Free memory
    free(xdoc)

    return md
end


function loadFMU(pathToFMU::String)
    loadFMU(pathToFMU, false, true)
end


"""
Load DLL containing FMU functions and return handle to DLL
"""
function loadFMU(pathToFMU::String, useTemp::Bool, overWriteTemp::Bool)

    # Split path
    name = last(split(pathToFMU, "\\"))

    # Create temp folder
    if useTemp
        tmpFolder = string(tempdir(), "FMU_", name[1:end-4], "_", floor(Int, 10000*rand()), "\\")
    else
        tmpFolder = string(pathToFMU[1:end-length(name)], "FMU_", name[1:end-4],  "\\")
    end
    if isdir(tmpFolder)
        if !overWriteTemp
            error("Folder $tmpFolder already exists but overwriting of temp
            folder is prohibited.")
        end
    else
        mkdir(tmpFolder)
    end

    # unzip FMU to tmp folder
    InfoZIP.unzip("helloWorldOMSI.fmu", tmpFolder)

    # parse modelDescription.xml
    md = readModelDescription(string(tmpFolder, "modelDescription.xml"))

    # pathToDLL
    if Sys.iswindows()
        if ispath(string(tmpFolder, "binaries\\win64\\")) && Sys.WORD_SIZE==64
            pathToDLL = string(tmpFolder, "binaries\\win64\\", name[1:end-4], ".dll")
        elseif ispath(string(tmpFolder, "binaries\\win32\\"))
            pathToDLL = string(tmpFolder, "binaries\\win32\\", name[1:end-4], ".dll")
        else
            error("No DLL found matching Windows OS and word size.")
        end

    elseif Sys.islinux()
        error("Linux not supported yet.")
    end

    # load dynamic library
    libHandle = dlopen(pathToDLL)

    return(libHandle, tmpFolder)
end



"""
Unload dynamic library and remove tmp files
"""
function unloadFMU(libHandle::Ptr{Nothing}, tmpFolder::String)

    # unload dynamic library
    dlclose(libHandle)

    # delete tmp folder
    rm(tmpFolder, recursive=true);
end



"""
Main function to simulate a FMU
"""
function main(pathToFMU::String)

    # load FMU
    (libHandle, tmpFolder) = loadFMU(pathToFMU)

    # instantiate FMU




    # unloadFMU
    unloadFMU(libHandle, tmpFolder)
end
