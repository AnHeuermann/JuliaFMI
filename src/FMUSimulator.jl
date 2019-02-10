"""
Simulator for FMUs of
FMI 2.0 for Model Exchange Standard
"""

using Libdl         # For using dlopen, dlclose and so on
using LightXML      # For parsing XML files

include("FMIWrapper.jl")


"""
Parse modelDescription.xml
"""
function readModelDescription(pathToModelDescription::String)

    md = ModelDescription()

    if !isfile(pathToModelDescription)
        error("File $pathToModelDescription does not exist.")
    elseif last(split(pathToModelDescription, "/")) != "modelDescription.xml"
        error("File name is not equal to \"modelDescription.xml\" but $(last(split(pathToModelDescription, "/")))" )
    end

    # Parse modelDescription
    xdoc = parse_file(pathToModelDescription)

    # Check root tag
    xroot = root(xdoc)
    if name(xroot)!="fmiModelDescription"
        error("modelDescription.xml root is not \"fmiModelDescription\".")
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
                stepSize = 2e-3
            end

            md.defaultExperiment = ExperimentData(startTime, stopTime, tolerance, stepSize)
        else
            md.defaultExperiment = ExperimentData()
        end

        # ToDo: Add stuff for tag VendorAnnotations

        # Get attributes of tag ModelVariables
        elementModelVariables = find_element(xroot, "ModelVariables")
        if elementModelVariables == nothing
            error("modelDescription.xml is missing ModelVariables tag")
        end

        numberOfVariables = 0
        for element in get_elements_by_tagname(elementModelVariables, "ScalarVariable")
            numberOfVariables += 1
        end
        scalarVariables = Array{ScalarVariable}(undef, numberOfVariables)

        for (index, element) in enumerate(get_elements_by_tagname(elementModelVariables, "ScalarVariable"))
            # Get attributes name, valueReference, variability, causality, initial
            tmp_name = attribute(element, "name"; required=true)
            tmp_valueReference = parse(Int, attribute(element, "valueReference"; required=true))

            tmp_description = attribute(element, "description"; required=false)
            if tmp_description == nothing
                tmp_description=""
            end
            tmp_variability = attribute(element, "variability"; required=false)
            if tmp_variability == nothing
                tmp_variability=""
            end
            tmp_causality = attribute(element, "causality"; required=false)
            if tmp_causality == nothing
                tmp_causality=""
            end
            tmp_initial = attribute(element, "initial"; required=false)
            if tmp_initial == nothing
                tmp_initial=""
            end
            tmp_canHandleMultipleSetPerTimelnstant = attribute(element, "canHandleMultipleSetPerTimelnstant"; required=false)
            if tmp_canHandleMultipleSetPerTimelnstant == nothing
                tmp_canHandleMultipleSetPerTimelnstant = false
            else
                tmp_canHandleMultipleSetPerTimelnstant = parse(Bool,
                    tmp_canHandleMultipleSetPerTimelnstant)
            end

            # Get child node for typeSpecificProperties
            tmp_typeSpecificProperties = nothing
            for child in child_elements(element)
                if is_elementnode(child)
                    if name(child)=="Real"
                        tmp_declaredType = "Real"
                        tmp_variableAttributes = RealAttributes()   # TODO implement
                        tmp_start = attribute(child, "start"; required=false)
                        if tmp_start == nothing
                            tmp_start = Float64(0)
                        else
                            tmp_start = parse(Float64, tmp_start)
                        end
                        tmp_derivative = attribute(child, "derivative"; required=false)
                        if tmp_derivative == nothing
                            tmp_derivative = UInt(0)
                        else
                            tmp_derivative = parse(UInt, tmp_derivative)
                        end
                        tmp_reinit = attribute(child, "reinit"; required=false)
                        if tmp_reinit == nothing
                            tmp_reinit = false
                        end
                        tmp_typeSpecificProperties = RealProperties(tmp_declaredType, tmp_variableAttributes, tmp_start, tmp_derivative, tmp_reinit)
                    elseif name(child)=="Integer"
                        tmp_declaredType = "Integer"
                        tmp_variableAttributes = IntegerAttributes()   # TODO implement
                        tmp_start = attribute(child, "start"; required=false)
                        if tmp_start == nothing
                            tmp_start = Int(0)
                        else
                            tmp_start = parse(Int, tmp_start)
                        end
                        tmp_typeSpecificProperties = IntegerProperties(tmp_declaredType, tmp_variableAttributes, tmp_start)
                    elseif name(child)=="Boolean"
                        tmp_declaredType = "Boolean"
                        tmp_start = attribute(child, "start"; required=false)
                        if tmp_start == nothing
                            tmp_start = false
                        else
                            tmp_start = parse(Bool, tmp_start)
                        end
                        tmp_typeSpecificProperties = BooleanProperties(tmp_declaredType, tmp_start)
                    else
                        error("Unknown type of ScalarVariable")
                    end
                end
            end

            scalarVariables[index] = ScalarVariable(tmp_name,
                tmp_valueReference, tmp_description, tmp_causality,
                tmp_variability, tmp_initial,
                tmp_canHandleMultipleSetPerTimelnstant,
                tmp_typeSpecificProperties)
        end
        md.modelVariables = scalarVariables

        # Get attributes of tag ModelStructure


    catch err
        if isa(err, KeyError)
            error("While parsing modelDescription: Non-optinal element \"$(err.key)\" not found")
        else
            rethrow(err)
        end
    end

    # Free memory
    LightXML.free(xdoc)

    return md
end


function modelDescriptionToModelData(modelDescription::ModelDescription)

    modelData = ModelData()

    for var in modelDescription.modelVariables
        if typeof(var.typeSpecificProperties)==RealProperties
            modelData.numberOfReals += 1
        elseif typeof(var.typeSpecificProperties)==IntegerProperties
            modelData.numberOfInts += 1
        elseif typeof(var.typeSpecificProperties)==BooleanProperties
            modelData.numberOfBools += 1
        elseif typeof(var.typeSpecificProperties)==StringProperties
            modelData.numberOfStrings += 1
        else
            error()
        end
    end

    return modelData
end


"""
Helper function to initialize modelVars in simulationData with start values from
modelDescription and set valueReference and name.
"""
function initializeSimulationData(modelDescription::ModelDescription,
    modelData::ModelData)

    prevVars=0

    simulationData = SimulationData(modelData.numberOfReals,
        modelData.numberOfInts, modelData.numberOfBools,
        modelData.numberOfStrings, 0)

    # Fill real simulation data with start value, value reference and name
    for (i,scalarVar) in enumerate(modelDescription.modelVariables[1:modelData.numberOfReals])
        simulationData.modelVariables.reals[i] =
            RealVariable(scalarVar.typeSpecificProperties.start,
                         scalarVar.valueReference,
                         scalarVar.name)
    end
    prevVars += modelData.numberOfReals

    # Fill integer simulation data
    if (modelData.numberOfInts > 0)
        for (i,scalarVar) in enumerate(modelDescription.modelVariables[prevVars:prevVars+modelData.numberOfInts])
            simulationData.modelVariables.ints[i] =
                IntVariable(scalarVar.typeSpecificProperties.start,
                            scalarVar.valueReference,
                            scalarVar.name)
        end
        prevVars += modelData.numberOfInts
    end

    # Fill boolean simulation data
    if (modelData.numberOfInts > 0)
        for (i,scalarVar) in enumerate(modelDescription.modelVariables[prevVars:prevVars+modelData.numberOfBools])
            println(scalarVar)
            simulationData.modelVariables.bools[i] =
                BoolVariable(scalarVar.typeSpecificProperties.start,
                             scalarVar.valueReference,
                             scalarVar.name)
        end
        prevVars += modelData.numberOfBools
    end

    # Fill string simulation data
    if (modelData.numberOfInts > 0)
        for (i,scalarVar) in enumerate(modelDescription.modelVariables[prevVars:prevVars+modelData.numberOfStrings])
            simulationData.modelVariables.strings[i] =
                StringVariable(scalarVar.typeSpecificProperties.start,
                               scalarVar.valueReference,
                               scalarVar.name)
        end
    end

    return simulationData
end


"""
`loadFMU(pathToFMU::String, useTemp::Bool=false, overWriteTemp::Bool=true)`

Unzips an FMU and returns handle to dynamic library containing FMI functions.

## Example calls
```
julia> fmu=loadFMU("path/to/fmu/helloWorld.fmu")
```
"""
function loadFMU(pathToFMU::String, useTemp::Bool=false, overWriteTemp::Bool=true)
    # Create uninitialized FMU
    fmu=FMU()

    # Split path
    fmu.FMUPath = pathToFMU
    name = last(split(pathToFMU, "/"))

    # Create temp folder
    if useTemp
        fmu.tmpFolder = string(tempdir(), "/FMU_", name[1:end-4], "_", floor(Int, 10000*rand()), "/")
    else
        fmu.tmpFolder = string(pathToFMU[1:end-length(name)], "FMU_", name[1:end-4],  "/")
    end
    if isdir(fmu.tmpFolder)
        if !overWriteTemp
            error("Folder $tmpFolder already exists but overwriting of temp
            folder is prohibited.")
        end
    end

    # unzip FMU to tmp folder
    my_unzip(pathToFMU, fmu.tmpFolder)

    # parse modelDescription.xml
    fmu.modelDescription = readModelDescription(string(fmu.tmpFolder, "modelDescription.xml"))
    fmu.modelName = fmu.modelDescription.modelName
    fmu.instanceName = fmu.modelDescription.modelName
    if (fmu.modelDescription.isModelExchange)
        fmu.fmuType = modelExchange
    else
        error("FMU does not support modelExchange")
    end

    # pathToDLL
    if Sys.iswindows()
        if ispath(string(fmu.tmpFolder, "binaries/win64/")) && Sys.WORD_SIZE==64
            pathToDLL = string(fmu.tmpFolder, "binaries/win64/", name[1:end-4], ".dll")
        elseif ispath(string(fmu.tmpFolder, "binaries/win32/"))
            pathToDLL = string(fmu.tmpFolder, "binaries/win32/", name[1:end-4], ".dll")
        else
            error("No DLL found matching Windows OS and word size.")
        end

    elseif Sys.islinux()
        if ispath(string(fmu.tmpFolder, "binaries/linux64/")) && Sys.WORD_SIZE==64
            pathToDLL = string(fmu.tmpFolder, "binaries/linux64/", name[1:end-4], ".so")
        elseif ispath(string(fmu.tmpFolder, "binaries/linux32/"))
            pathToDLL = string(fmu.tmpFolder, "binaries/linux32/", name[1:end-4], ".so")
        else
            error("No shared object file found in $(string(fmu.tmpFolder, "binaries/linux$(Sys.WORD_SIZE)/")) matching Unix OS and word size.")
        end
    end

    # Fill model data
    fmu.modelData = modelDescriptionToModelData(fmu.modelDescription)

    # Fill Simulation Data
    fmu.simulationData = initializeSimulationData(fmu.modelDescription, fmu.modelData)

    # Set default experiment
    fmu.experimentData = deepcopy(fmu.modelDescription.defaultExperiment)

    fmu.eventInfo = EventInfo()

    # Open result and log file
    fmu.csvFile = open("$(fmu.modelName)_results.csv", "w")
    fmu.logFile = open("$(fmu.modelName).log", "w")

    # load dynamic library
    # TODO export DL_LOAD_PATH="/usr/lib/x86_64-linux-gnu" on unix systems
    # push!(DL_LOAD_PATH, "/usr/lib/x86_64-linux-gnu") maybe???
    fmu.libHandle = dlopen(pathToDLL)

    # Fill FMU with remaining data
    fmu.fmuResourceLocation = string("file:///", fmu.tmpFolder,"resources")
    fmu.fmuGUID = fmu.modelDescription.guid
    fmu.fmiCallbackFunctions = fmi2Functions

    fmu.modelState = modelUninstantiated

    return fmu
end


"""
Unload dynamic library and if `deleteTmpFolder=true` remove tmp files.
"""
function unloadFMU(fmu::FMU)
    unloadFMU(fmu.libHandle, fmu.tmpFolder)

    # Close result and log file
    close(fmu.csvFile)
    close(fmu.logFile)
end

function unloadFMU(libHandle::Ptr{Nothing}, tmpFolder::String,
    deleteTmpFolder=true::Bool)

    # unload FMU dynamic library
    dlclose(libHandle)

    # unload C logger
    dlclose(libLoggerHandle)

    # delete tmp folder
    if deleteTmpFolder
        rm(tmpFolder, recursive=true);
    end
end


"""
Helper function to unzip file using installed tools.
Overwrites `destiantionDir`
"""
function my_unzip(target::String, destinationDir::String)

    if !isfile(target)
        error("Could not find file \"$target\"")
    end

    if !ispath(destinationDir)
        mkpath(destinationDir)
    end

    try
        #use unzip
        run(Cmd(`unzip -qo $target`, dir = destinationDir))
        println("Extracted FMU to $destinationDir")
    catch
        try
            #use 7-zip
            run(Cmd(`"C:\\Program Files\\7-Zip\\7z.exe" x $target -aoa -o$destinationDir`));
            println("Extracted FMU to $destinationDir")
        catch
            error("Could not unzip file \"$target\"")
        end
    end
end


"""
Gets values of all states of a FMU.
Helper function for main.
"""
function getContinuousStates!(fmu::FMU)

    if fmu.modelState != modelContinuousTimeMode
        error("Function call only allowed in modelContinuousTimeMode but model is in mode: $(fmu.modelState)")
    end

    states = Array{Float64}(undef,fmu.modelData.numberOfStates)
    fmi2GetContinuousStates!(fmu, states)

    println("states : $states")

    for i=1:fmu.modelData.numberOfStates
        fmu.simulationData.modelVariables.reals[i].value = states[i]
    end
end


function getDerivatives!(fmu::FMU)

    if fmu.modelState != modelContinuousTimeMode
        error("Function call only allowed in modelContinuousTimeMode but model is in mode: $(fmu.modelState)")
    end

    derivatives = Array{Float64}(undef,fmu.modelData.numberOfStates)
    fmi2GetDerivatives!(fmu, derivatives)

    println("derivatives : $derivatives")

    for i=1:fmu.modelData.numberOfDerivatives
        fmu.simulationData.modelVariables.reals[i+fmu.modelData.numberOfStates].value = derivatives[i]
    end
end


"""
Sets continous states in `FMU`
"""
function setContinuousStates!(fmu::FMU)

    if fmu.modelState != modelContinuousTimeMode
        error("Function call only allowed in modelContinuousTimeMode but model is in mode: $(fmu.modelState)")
    end

    states = Array{Float64}(undef,fmu.modelData.numberOfStates)

    for i=1:fmu.modelData.numberOfStates
        states[i] = fmu.simulationData.modelVariables.reals[i].value
    end

    println("states: $states")
    fmi2SetContinuousStates(fmu, states)

end

function getVariable!(fmu::FMU, variable::RealVariable)

    fmi2GetReal!(fmu, [variable.valueReference], [variable.value])
    return variable.value
end

function getVariable!(fmu::FMU, variable::IntVariable)

    fmi2GetInteger!(fmu, [variable.valueReference], [variable.value])
    return variable.value
end

function getVariable!(fmu::FMU, variable::BoolVariable)

    fmi2GetBoolean!(fmu, [variable.valueReference], [variable.value])
    return variable.value
end

function getVariable!(fmu::FMU, variable::StringVariable)

    fmi2GetString!(fmu, [variable.valueReference], [variable.value])
    return variable.value
end

function getAllVariables!(fmu::FMU)

    for realVar in fmu.simulationData.modelVariables.reals
        realVar.value = getVariable!(fmu, realVar)
    end
    for intVar in fmu.simulationData.modelVariables.ints
        intVar.value = getVariable!(fmu, intVar)
    end
    for boolVar in fmu.simulationData.modelVariables.bools
        boolVar.value = getVariable!(fmu, boolVar)
    end
    for stringVar in fmu.simulationData.modelVariables.strings
        stringVar.value = getVariable!(fmu, stringVar)
    end
end

function setTime!(fmu::FMU, time::Float64)

    fmu.simulationData.time = time
    fmi2SetTime(fmu, fmu.simulationData.time)
end

function writeNamesToCSV(fmu::FMU)

    write(fmu.csvFile, "\"time\"")
    for realVar in fmu.simulationData.modelVariables.reals
        write(fmu.csvFile, ",\"$(realVar.name)\"")
    end
    for intVar in fmu.simulationData.modelVariables.ints
        write(fmu.csvFile, ",\"$(intVar.name)\"")
    end
    for boolVar in fmu.simulationData.modelVariables.bools
        write(fmu.csvFile, ",\"$(boolVar.name)\"")
    end
    for stringVar in fmu.simulationData.modelVariables.strings
        write(fmu.csvFile, ",\"$(stringVar.name)\"")
    end
    write(fmu.csvFile, "\r\n")
end


function writeValuesToCSV(fmu::FMU)

    write(fmu.csvFile, "$(fmu.simulationData.time)")
    for realVar in fmu.simulationData.modelVariables.reals
        write(fmu.csvFile, ",$(realVar.value)")
    end
    for intVar in fmu.simulationData.modelVariables.ints
        write(fmu.csvFile, ",$(intVar.value)")
    end
    for boolVar in fmu.simulationData.modelVariables.bools
        write(fmu.csvFile, ",$(boolVar.value)")
    end
    for stringVar in fmu.simulationData.modelVariables.strings
        write(fmu.csvFile, ",$(stringVar.value)")
    end
    write(fmu.csvFile,"\r\n")
end


"""
Main function to simulate a FMU
"""
function main(pathToFMU::String)
    # load FMU
    fmu = loadFMU(pathToFMU)
    writeNamesToCSV(fmu)

    try
        # Instantiate FMU
        fmi2Instantiate!(fmu)
        fmu.modelState = modelInstantiated

        fmu.modelData.numberOfStates = 1    # TODO do automatically
        fmu.modelData.numberOfDerivatives = fmu.modelData.numberOfStates

        # Set debug logging to true for all categories
        fmi2SetDebugLogging(fmu, true)

        # Get types platform
        typesPlatform = fmi2GetTypesPlatform(fmu)
        println("typesPlatform: $typesPlatform")

        # Get version of fmi
        fmiVersion = fmi2GetVersion(fmu)
        println("FMI version: $fmiVersion")

        # Set up experiment
        fmi2SetupExperiment(fmu, 0)

        # Set start time
        setTime!(fmu, 0.0)

        # Set initial variables with intial="exact" or "approx"

        # Initialize FMU
        fmi2EnterInitializationMode(fmu)

        # Exit Initialization
        fmi2ExitInitializationMode(fmu)

        # Event iteration
        fmu.eventInfo.newDiscreteStatesNeeded = true
        while fmu.eventInfo.newDiscreteStatesNeeded
            fmi2NewDiscreteStates!(fmu)
            if fmu.eventInfo.terminateSimulation
                error()
            end
        end

        # Enter Continuous time mode
        fmi2EnterContinuousTimeMode(fmu)

        # retrieve initial states
        getContinuousStates!(fmu)

        # retrive solution
        getAllVariables!(fmu)           # TODO Is not returning der(x) correctly
        writeValuesToCSV(fmu)

        # Iterate with explicit euler method
        k = 0
        k_max = 1000
        while (fmu.simulationData.time < fmu.experimentData.stopTime) && (k < k_max)
            k += 1
            getDerivatives!(fmu)
            println("reals: ", fmu.simulationData.modelVariables.reals)

            # Compute next step size
            if fmu.eventInfo.nextEventTimeDefined
                h = min(fmu.experimentData.stepSize, fmu.eventInfo.nextEventTime - fmu.simulationData.time)
            else
                h = min(fmu.experimentData.stepSize, fmu.experimentData.stopTime - fmu.simulationData.time)
            end

            # Update time
            setTime!(fmu, fmu.simulationData.time + h)

            # Set states and perform euler step (x_k+1 = x_k + d/dx x_k*h)
            for i=1:fmu.modelData.numberOfStates
                println("x_$i = $(fmu.simulationData.modelVariables.reals[i].value) + $h * $(fmu.simulationData.modelVariables.reals[i+fmu.modelData.numberOfStates].value)")
                fmu.simulationData.modelVariables.reals[i].value = fmu.simulationData.modelVariables.reals[i].value + h*fmu.simulationData.modelVariables.reals[i+fmu.modelData.numberOfStates].value
            end
            setContinuousStates!(fmu)

            # Get event indicators and check for events

            # Inform the model abaut an accepred step
            (enterEventMode, terminateSimulation) = fmi2CompletedIntegratorStep(fmu, true)
            if enterEventMode
                error("Should now enter Event mode...")
            end

            if terminateSimulation
                error("Solution got terminated bevore reaching end time.")
            end

            # save results
            getAllVariables!(fmu)
            writeValuesToCSV(fmu)

            # Handle events
        end

        # Terminate Simulation
        fmi2Terminate(fmu)

        # Free FMU
        # ToDo: Fix function
        #fmi2FreeInstance(fmu)
    finally
        # Unload FMU
        println("Unload FMU")
        unloadFMU(fmu)
    catch
        rethrow()
    end
end
