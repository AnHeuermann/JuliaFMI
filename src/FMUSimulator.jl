# This file is part of JuliaFMI.
# License is MIT: https://servant-om.fh-bielefeld.de/gitlab/AnHeuermann/FMU_JL_Simulator/blob/master/LICENSE.txt

# This file contains thhe main simulator routine

"""
Simulator for FMUs of
FMI 2.0 for Model Exchange Standard
"""

using Libdl         # For using dlopen, dlclose and so on
using LightXML      # For parsing XML files

include("FMIWrapper.jl")
include("EventHandling.jl")

"""
Parse modelDescription.xml
"""
function readModelDescription(pathToModelDescription::String)

    md = ModelDescription()

    if !isfile(pathToModelDescription)
        error("File $pathToModelDescription does not exist.")
    elseif basename(pathToModelDescription) != "modelDescription.xml"
        error("File name is not equal to \"modelDescription.xml\" but $(basename(pathToModelDescription))" )
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
        md.variableNamingConvention = NamingConvention(get(attributes, "variableNamingConvention", "flat"))
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

        if elementCoSimulation === nothing && elementModelExchange === nothing
            error("modelDescription.xml is missing ModelExchange and CoSimulation tags.")
        end

        # TODO: Add stuff for tag UnitDefinitions

        # TODO: Add stuff for tag TypeDefinitions

        # Get attributes of tag LogCategories
        elementLogCategories = find_element(xroot, "LogCategories")
        if elementLogCategories != nothing
            numCategories = 0
            for element in child_elements(elementLogCategories)
                numCategories += 1
            end
            md.logCategories = Array{LogCategory}(undef, numCategories)

            for (index, element) in enumerate(child_elements(elementLogCategories))
                tmp_name = attribute(element, "name"; required=true)
                tmp_description = attribute(element, "description"; required=false)
                if tmp_description === nothing
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

        # TODO: Add stuff for tag VendorAnnotations

        # Get attributes of tag ModelVariables
        elementModelVariables = find_element(xroot, "ModelVariables")
        if elementModelVariables === nothing
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
            if tmp_description === nothing
                tmp_description=""
            end
            tmp_variability = attribute(element, "variability"; required=false)
            if tmp_variability === nothing
                tmp_variability=""
            end
            tmp_causality = attribute(element, "causality"; required=false)
            if tmp_causality === nothing
                tmp_causality=""
            end
            tmp_initial = attribute(element, "initial"; required=false)
            if tmp_initial === nothing
                tmp_initial=""
            end
            tmp_canHandleMultipleSetPerTimelnstant = attribute(element, "canHandleMultipleSetPerTimelnstant"; required=false)
            if tmp_canHandleMultipleSetPerTimelnstant === nothing
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
                        if tmp_start === nothing
                            tmp_start = Float64(0)
                        else
                            tmp_start = parse(Float64, tmp_start)
                        end
                        tmp_derivative = attribute(child, "derivative"; required=false)
                        if tmp_derivative === nothing
                            tmp_derivative = UInt(0)
                        else
                            tmp_derivative = parse(UInt, tmp_derivative)
                        end
                        tmp_reinit = attribute(child, "reinit"; required=false)
                        if tmp_reinit === nothing
                            tmp_reinit = false
                        end
                        tmp_typeSpecificProperties = RealProperties(tmp_declaredType, tmp_variableAttributes, tmp_start, tmp_derivative, tmp_reinit)
                    elseif name(child)=="Integer"
                        tmp_declaredType = "Integer"
                        tmp_variableAttributes = IntegerAttributes()   # TODO implement
                        tmp_start = attribute(child, "start"; required=false)
                        if tmp_start === nothing
                            tmp_start = Int(0)
                        else
                            tmp_start = parse(Int, tmp_start)
                        end
                        tmp_typeSpecificProperties = IntegerProperties(tmp_declaredType, tmp_variableAttributes, tmp_start)
                    elseif name(child)=="Boolean"
                        tmp_declaredType = "Boolean"
                        tmp_start = attribute(child, "start"; required=false)
                        if tmp_start === nothing
                            tmp_start = false
                        else
                            tmp_start = parse(Bool, tmp_start)
                        end
                        tmp_typeSpecificProperties = BooleanProperties(tmp_declaredType, tmp_start)
                    elseif name(child)=="String"
                        tmp_declaredType = "String"
                        tmp_start = attribute(child, "start"; required=false)
                        if tmp_start === nothing
                            tmp_start = ""
                        end
                        tmp_typeSpecificProperties = StringProperties(tmp_declaredType, tmp_start)
                    elseif name(child)=="Enumeration"
                        tmp_declaredType = "Enumeration"
                        tmp_quantity = attribute(child, "quantity"; required=false)
                        if tmp_quantity === nothing
                            tmp_quantity = ""
                        end
                        tmp_min = attribute(child, "min"; required=false)
                        if tmp_min === nothing
                            tmp_min = Int(0)
                        else
                            tmp_min = parse(Int, tmp_min)
                        end
                        tmp_max = attribute(child, "max"; required=false)
                        if tmp_max === nothing
                            tmp_max = Int(0)
                        else
                            tmp_max = parse(Int, tmp_max)
                        end
                        tmp_start = attribute(child, "start"; required=false)
                        if tmp_start === nothing
                            tmp_start = Int(0)
                        else
                            tmp_start = parse(Int, tmp_start)
                        end
                        tmp_typeSpecificProperties = EnumerationProperties(tmp_declaredType, tmp_quantity, tmp_min, tmp_max, tmp_start)
                    else
                        error("Unknown type \"$(name(child))\" of ScalarVariable")
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
            error("While parsing modelDescription: Non-optional element \"$(err.key)\" not found")
        else
            rethrow(err)
        end
    end

    # Free memory
    LightXML.free(xdoc)

    return md
end


"""
    function createEmptyModelData(modelDescription::ModelDescription)

Create empty `modelData::ModelData`.
Use numbers of variables from `modelDescription`.
"""
function createEmptyModelData(modelDescription::ModelDescription)

    modelData = ModelData()

    for var in modelDescription.modelVariables
        if typeof(var.typeSpecificProperties)==RealProperties
            if var.typeSpecificProperties.derivative > 0
                modelData.numberOfStates += 1
                modelData.numberOfDerivatives += 1
            end
            modelData.numberOfReals += 1
        elseif typeof(var.typeSpecificProperties)==IntegerProperties
            modelData.numberOfInts += 1
        elseif typeof(var.typeSpecificProperties)==BooleanProperties
            modelData.numberOfBools += 1
        elseif typeof(var.typeSpecificProperties)==StringProperties
            modelData.numberOfStrings += 1
        elseif typeof(var.typeSpecificProperties)==EnumerationProperties
            modelData.numberOfEnumerations += 1
        else
            error()
        end

    modelData.numberOfEventIndicators = modelDescription.numberOfEventIndicators
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
        modelData.numberOfStates, modelData.numberOfInts,
        modelData.numberOfBools, modelData.numberOfStrings, 0,
        modelData.numberOfEventIndicators)    # TODO Add number of enumerations here!

    i_real = i_int = i_bool = i_string = i_enumertion = 0

    # Fill simulation data with start value, value reference and name for all
    # scalar variables
    for scalarVar in modelDescription.modelVariables
        if typeof(scalarVar.typeSpecificProperties) == RealProperties
            i_real += 1
            simulationData.modelVariables.reals[i_real] =
                RealVariable(scalarVar.typeSpecificProperties.start,
                             scalarVar.valueReference,
                             scalarVar.name)
        elseif typeof(scalarVar.typeSpecificProperties) == IntegerProperties
            i_int += 1
            simulationData.modelVariables.ints[i_int] =
                IntVariable(scalarVar.typeSpecificProperties.start,
                            scalarVar.valueReference,
                            scalarVar.name)
        elseif typeof(scalarVar.typeSpecificProperties) == BooleanProperties
            i_bool += 1
            simulationData.modelVariables.bools[i_bool] =
                BoolVariable(scalarVar.typeSpecificProperties.start,
                             scalarVar.valueReference,
                             scalarVar.name)
        elseif typeof(scalarVar.typeSpecificProperties) == StringProperties
            i_string += 1
            simulationData.modelVariables.strings[i_string] =
                StringVariable(scalarVar.typeSpecificProperties.start,
                               scalarVar.valueReference,
                               scalarVar.name)
        elseif typeof(scalarVar.typeSpecificProperties) == EnumerationProperties
            error("Enumeration variables not implemeted!")
            #i_enumertion += 1
            # TODO add enumerations here
            #simulationData.modelVariables.enumerations[i_enumertion] =
            #    EnumerationVariable()
        else
            error("Unknown scalar variable type $(typeof(scalarVar.typeSpecificProperties)).")
        end
    end

    if i_real != modelData.numberOfReals
        error("Counted number of real scalar variables $i_real didn't matched expeted $(modelData.numberOfReals + modelData.numberOfEventIndicators)")
    elseif i_int != modelData.numberOfInts
        error("Counted number of integer scalar variables $i_int didn't matched expeted $(modelData.numberOfInts)")
    elseif i_bool != modelData.numberOfBools
        error("Counted number of boolean scalar variables $i_bool didn't matched expeted $(modelData.numberOfBools)")
    elseif i_string != modelData.numberOfStrings
        error("Counted number of string scalar variables $i_string didn't matched expeted $(modelData.numberOfStrings)")
    elseif i_enumertion != 0
        error("Counted number of enumeration scalar variables $i_enumertion didn't matched expeted 0")
    end

    return simulationData
end


"""
`loadFMU(pathToFMU::String, useTemp::Bool=false, overWriteTemp::Bool=true)`

Unzips a FMU and returns handle to dynamic library containing FMI functions.

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
    name = splitext(basename(pathToFMU))[1]

    # Create temp folder
    if useTemp
        fmu.tmpFolder = joinpath(tempdir(), string("FMU_", name, "_", floor(Int, 10000*rand())))
    else
        fmu.tmpFolder = joinpath(dirname(pathToFMU), string("FMU_", name))
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
    fmu.modelDescription = readModelDescription(joinpath(fmu.tmpFolder, "modelDescription.xml"))
    fmu.modelName = fmu.modelDescription.modelName
    fmu.instanceName = fmu.modelDescription.modelName
    if (fmu.modelDescription.isModelExchange)
        fmu.fmuType = modelExchange
    else
        error("FMU does not support modelExchange")
    end

    modelIdentifier = fmu.modelDescription.modelIdentifier

    # pathToDLL
    if Sys.iswindows()
        pathToDLL = joinpath(fmu.tmpFolder, "binaries", "win$(Sys.WORD_SIZE)", string(modelIdentifier, ".dll"))
    elseif Sys.islinux()
        pathToDLL = joinpath(fmu.tmpFolder, "binaries", "linux$(Sys.WORD_SIZE)", string(modelIdentifier, ".so"))
    elseif Sys.isapple()
        pathToDLL = joinpath(fmu.tmpFolder, "binaries", "darwin$(Sys.WORD_SIZE)", string(modelIdentifier, ".dylib"))
        println(pathToDLL)
    else
        error("OS not supported!")
    end

    if !isfile(pathToDLL)
        if Sys.iswindows()
            error("No shared library found matching $(Sys.WORD_SIZE) bit Windows.\n Looking for $pathToDLL.")
        elseif Sys.islinux()
            error("No shared library found matching $(Sys.WORD_SIZE) bit Linux.\n Looking for $pathToDLL.")
        elseif Sys.isapple()
            error("No shared library found matching $(Sys.WORD_SIZE) bit macOS.\n Looking for $pathToDLL.")
        end
    end

    # Create empty model data
    fmu.modelData = createEmptyModelData(fmu.modelDescription)

    # Fill Simulation Data
    fmu.simulationData = initializeSimulationData(fmu.modelDescription, fmu.modelData)

    # Set default experiment
    fmu.experimentData = deepcopy(fmu.modelDescription.defaultExperiment)

    fmu.eventInfo = EventInfo()

    # Open result and log file
    fmu.csvFile = open("$(fmu.modelName)_results.csv", "w")
    fmu.logFile = open("$(fmu.modelName).log", "w")

    # load shared library with FMU
    fmu.libHandle = dlopen(pathToDLL)

    # Load hared library with logger function
    fmu.libLoggerHandle = dlopen(@libLogger)
    fmi2CallbacLogger_Cfunc = dlsym(fmu.libLoggerHandle, :logger)
    # fmi2CallbacLogger_funcWrapC = @cfunction(fmi2CallbackLogger, Cvoid,
    #    (Ptr{Cvoid}, Cstring, Cuint, Cstring, Tuple{Cstring}))
    fmi2AllocateMemory_funcWrapC = @cfunction(fmi2AllocateMemory, Ptr{Cvoid}, (Csize_t, Csize_t))
    fmi2FreeMemory_funcWrapC = @cfunction(fmi2FreeMemory, Cvoid, (Ptr{Cvoid},))

    fmi2Functions = CallbackFunctions(
        #fmi2CallbacLogger_funcWrapC,       # Logger in Julia
        fmi2CallbacLogger_Cfunc,            # Logger in C
        fmi2AllocateMemory_funcWrapC,
        fmi2FreeMemory_funcWrapC,
        C_NULL,
        C_NULL)

    # Fill FMU with remaining data
    fmu.fmuResourceLocation = joinpath(string("file:///", fmu.tmpFolder), "resources")
    fmu.fmuGUID = fmu.modelDescription.guid
    fmu.fmiCallbackFunctions = fmi2Functions

    fmu.modelState = modelUninstantiated

    return fmu
end


"""
```
    unloadFMU(fmu::FMU, [deleteTmpFolder=true::Bool])
```
Unload FMU and if `deleteTmpFolder=true` remove tmp files.
"""
function unloadFMU(fmu::FMU, deleteTmpFolder=true::Bool)

    # unload FMU dynamic library
    dlclose(fmu.libHandle)

    # unload C logger
    dlclose(fmu.libLoggerHandle)

    # delete tmp folder
    if deleteTmpFolder
        rm(fmu.tmpFolder, recursive=true, force=true);
    end

    # Close result and log file
    close(fmu.csvFile)
    close(fmu.logFile)
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

    fmi2SetContinuousStates(fmu, states)

end

"""
Get eventIndicators from FMU and update saved values.
"""
function getEventIndicators!(fmu::FMU)

    fmi2GetEventIndicators!(fmu, fmu.simulationData.eventIndicators)
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

"""
Get all variables from FMU and update saved falues in fmu.simulationData.modelVariables

Get all real, integer, boolean and string variables by calling the appropiate
fmi2GetXXX! function.
"""
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

function setTime!(fmu::FMU, time::Float64, saveLastStepTime=true::Bool)

    if saveLastStepTime
        fmu.simulationData.lastStepTime = fmu.simulationData.time
    end
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
        write(fmu.csvFile, ",$(Int(boolVar.value))")
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

    # Convert path to absolute path
    pathToFMU = abspath(pathToFMU)

    # load FMU
    fmu = loadFMU(pathToFMU)
    writeNamesToCSV(fmu)

    try
        # Instantiate FMU
        fmi2Instantiate!(fmu)
        fmu.modelState = modelInstantiated

        # Set debug logging to false for all categories
        fmi2SetDebugLogging(fmu, false)

        # Get types platform
        typesPlatform = fmi2GetTypesPlatform(fmu)
        println("typesPlatform: $typesPlatform")

        # Get version of fmi
        fmiVersion = fmi2GetVersion(fmu)
        println("FMI version: $fmiVersion")

        # Set up experiment
        fmi2SetupExperiment(fmu, true, fmu.experimentData.tolerance, fmu.experimentData.startTime, true, fmu.experimentData.stopTime)
        nextTime = fmu.experimentData.stopTime

        # Set initial variables with intial="exact" or "approx"

        # Initialize FMU
        fmi2EnterInitializationMode(fmu)

        # Exit Initialization
        fmi2ExitInitializationMode(fmu)

        # Event iteration
        fmu.eventInfo = eventIteration!(fmu)

        # Initialize event indicators
        getEventIndicators!(fmu)

        # Enter Continuous time mode
        fmi2EnterContinuousTimeMode(fmu)

        # retrieve initial states
        getContinuousStates!(fmu)
        getDerivatives!(fmu)

        # retrive solution
        getAllVariables!(fmu)       # TODO Is not returning der(x) correctly
                                    # Needs to call fmi2GetXXX of course...
        writeValuesToCSV(fmu)

        # Iterate with explicit euler method
        k = 0
        k_max = 1000
        while (fmu.simulationData.time < fmu.experimentData.stopTime) && (k < k_max)
            k += 1

            # Compute next step size and update time
            h = min(fmu.experimentData.stepSize, nextTime - fmu.simulationData.time)
            setTime!(fmu, fmu.simulationData.time + h)

            # Set states and perform euler step (x_k+1 = x_k + d/dx x_k*h)
            for i=1:fmu.modelData.numberOfStates
                fmu.simulationData.modelVariables.oldStates[i] = fmu.simulationData.modelVariables.reals[i].value
                fmu.simulationData.modelVariables.reals[i].value = fmu.simulationData.modelVariables.reals[i].value + h*fmu.simulationData.modelVariables.reals[i+fmu.modelData.numberOfStates].value
            end
            setContinuousStates!(fmu)
            getDerivatives!(fmu)

            # Detect time events
            timeEvent = abs(fmu.simulationData.time - nextTime) <= fmu.experimentData.stepSize       # TODO add handling of time events

            # Detect events
            #(eventFound, eventTime, leftStates) = findEvent(fmu)   #TODO: Bisection is getting stuck at first event
            eventFound = findEventSimple(fmu)
            eventTime = fmu.simulationData.time

            # Inform the model abaut an accepted step
            (enterEventMode, terminateSimulation) = fmi2CompletedIntegratorStep(fmu, true)
            if terminateSimulation
                error("FMU was terminated after completed integrator step at time $(fmu.simulationData.time)")
            end

            # Handle events
            # TODO: With findEventSimple every event is found twice. This can be done better.
            if timeEvent || eventFound || enterEventMode
                if timeEvent
                    eventName = "time"
                elseif eventFound
                    eventName = "state"
                else
                    eventName = "step"
                end

                # Save variable values to csv
                # TODO Add

                fmi2EnterEventMode(fmu)

                # Event iteration
                fmu.eventInfo = eventIteration!(fmu)

                # Update changed continuous states
                getContinuousStates!(fmu)

                # Enter continuous-time mode
                fmi2EnterContinuousTimeMode(fmu)
                getEventIndicators!(fmu)

                # Retrieve solution at simulation restart
                getAllVariables!(fmu)
                if fmu.eventInfo.valuesOfContinuousStatesChanged
                    # TODO check if this is working correctly
                    getContiuousStates(fmu)
                end

                # Check if nominals changed
                if fmu.eventInfo.nominalsOfContinuousStatesChanged
                    error("Nominals not handled at the moment")
                    # getNominalsOfContinuousStates(fmu)
                end

                if fmu.eventInfo.nextEventTimeDefined
                    println("Next event time defined")
                    nextTime = min(fmu.eventInfo.nextEventTime, fmu.experimentData.stopTime)
                else
                    nextTime = fmu.experimentData.stopTime + fmu.experimentData.stepSize
                end
                println("fmu.simulationData.time = $(fmu.simulationData.time)")
                println("eventTime = $eventTime")
                println("nextTime = $nextTime")

            end

            # save results
            getAllVariables!(fmu) # TODO check if this is working correctly
            writeValuesToCSV(fmu)
        end

        # Terminate Simulation
        fmi2Terminate(fmu)

        # Free FMU
        # TODO: Fix function
        #fmi2FreeInstance(fmu)
    finally
        # Unload FMU
        println("Unload FMU")
        unloadFMU(fmu)
    catch
        rethrow()
    end

    return true
end
