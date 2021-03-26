# This file is part of JuliaFMI.
# Licensed under MIT: https://github.com/AnHeuermann/JuliaFMI/blob/master/LICENSE.txt

# This file contains the main function to simulate a FMU.

"""
Simulator for FMUs of
FMI 2.0 for Model Exchange Standard
"""


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
        modelData.numberOfInts, modelData.numberOfBools,
        modelData.numberOfStrings, modelData.numberOfEnumerations,
        modelData.numberOfEventIndicators)

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
            i_enumertion += 1
            simulationData.modelVariables.enumerations[i_enumertion] =
                EnumerationVariable(scalarVar.typeSpecificProperties.start,
                                    scalarVar.valueReference,
                                    scalarVar.name)
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
    elseif i_enumertion != modelData.numberOfEnumerations
        error("Counted number of enumeration scalar variables $i_enumertion didn't matched expeted $(modelData.numberOfEnumerations)")
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
function loadFMU(pathToFMU::String; fmi2Functions=CallbackFunctions(), fmuResourceLocation=nothing,
    useTemp::Bool=false, overWriteTemp::Bool=true)

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
    if (fmu.modelDescription.isModelExchange == true)
        fmu.fmuType = modelExchange
    elseif (fmu.modelDescription.isCoSimulation == true)
        fmu.fmuType = coSimulation
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
    # TODO export DL_LOAD_PATH="/usr/lib/x86_64-linux-gnu" on unix systems
    # push!(DL_LOAD_PATH, "/usr/lib/x86_64-linux-gnu") maybe???
    fmu.libHandle = dlopen(pathToDLL)

    # Load hared library with logger function
    fmu.libLoggerHandle = dlopen(@libLogger)

    # Fill FMU with remaining data # TODO correct paths for portibility
    fmu.fmuResourceLocation = if isnothing(fmuResourceLocation)
        joinpath(string("file:///", fmu.tmpFolder), "resources")
    else
        fmuResourceLocation
    end
    fmu.fmuGUID = fmu.modelDescription.guid
    fmu.fmi2CallbackFunctions = fmi2Functions

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
        run(`unzip -qo $target -d $destinationDir`)
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

"""
Checks if signs of two arrays are different component-wise.
Helper function for bisection.
"""
function arrayDiffSign(array1::Array{Float64,1}, array2::Array{Float64,1})

    if length(array1) != length(array2)
        throw(DimensionMismatch("Left and right array of event indicators have different sizes."))
    end

    for i in 1:length(array1)
        if sign(array1[i]) != sign(array2[i])
            return true
        end
    end

    return false
end

"""
Find event time with bisection method for `eventIndicators` for given `fmu`.
"""
function findEvent(fmu::FMU)

    leftTime = fmu.simulationData.lastStepTime
    rightTime = fmu.simulationData.time

    leftEventIndicators = copy(fmu.simulationData.eventIndicators)
    getEventIndicators!(fmu)
    rightEventIndicators = copy(fmu.simulationData.eventIndicators)

    # Check if there are any events
    if !arrayDiffSign(leftEventIndicators, rightEventIndicators)
        return (false, 0)
    end

    steps = 0
    minimumStepSize = 1e-8      # TODO: Read mimimumStepSize from fmu experiment data
    maxSteps = ceil(log2((rightTime-leftTime)/minimumStepSize)) + 1
    centerTime = 0

    while rightTime - leftTime > minimumStepSize && steps < maxSteps
        steps += 1

        # Evaluate eventIndicators in center of intervall
        centerTime = 0.5*(rightTime - leftTime)
        setTime!(fmu, centerTime, false)
        getEventIndicators!(fmu)
        centerEventIndicators = copy(fmu.simulationData.eventIndicators)     # TODO Do I need to copy here?

        # TODO Check what happens when event is on leftTime, centerTime or rightTime
        # Check for event in first half of intervall [leftTime, centerTime]
        if arrayDiffSign(leftEventIndicators, centerEventIndicators)
            rightTime = centerTime
            rightEventIndicators = centerEventIndicators        # This does not copy memory, right?

        # Check for event in second half of intervall [centerTime, rightTime]
        else
            leftTime = centerTime
            leftEventIndicators = centerEventIndicators
        end
    end

    if steps == maxSteps
        error("Event was not found in maximum number of Steps!")
    end

    return (true, centerTime)
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
        fmu.eventInfo.newDiscreteStatesNeeded = true
        while fmu.eventInfo.newDiscreteStatesNeeded == true
            fmi2NewDiscreteStates!(fmu)
            if fmu.eventInfo.terminateSimulation == true
                error("FMU was terminated in Event at time $(fmu.simulationData.time)")
            end
        end
        # Initialize event indicators
        getEventIndicators!(fmu)

        # Enter Continuous time mode
        fmi2EnterContinuousTimeMode(fmu)

        # retrieve initial states
        getContinuousStates!(fmu)
        getDerivatives!(fmu)

        # retrive solution
        getAllVariables!(fmu)
        writeValuesToCSV(fmu)

        # Iterate with explicit euler method
        k = 0
        k_max = 1000
        while (fmu.simulationData.time < fmu.experimentData.stopTime) && (k < k_max)
            k += 1
            getDerivatives!(fmu)

            # Compute next step size
            if fmu.eventInfo.nextEventTimeDefined == true
                h = min(fmu.experimentData.stepSize, fmu.eventInfo.nextEventTime - fmu.simulationData.time)
            else
                h = min(fmu.experimentData.stepSize, fmu.experimentData.stopTime - fmu.simulationData.time)
            end

            # Update time
            setTime!(fmu, fmu.simulationData.time + h)

            # Set states and perform euler step (x_k+1 = x_k + d/dx x_k*h)
            for i=1:fmu.modelData.numberOfStates
                fmu.simulationData.modelVariables.reals[i].value = fmu.simulationData.modelVariables.reals[i].value + h*fmu.simulationData.modelVariables.reals[i+fmu.modelData.numberOfStates].value
            end
            setContinuousStates!(fmu)

            # Get event indicators and check for events

            # Inform the model abaut an accepted step
            (enterEventMode, terminateSimulation) = fmi2CompletedIntegratorStep(fmu, true)
            if enterEventMode
                error("Should now enter Event mode...")
            end

            if terminateSimulation
                error("Solution got terminated before reaching end time.")
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
    catch e
        rethrow(e)
    finally
        # Unload FMU
        println("Unload FMU")
        unloadFMU(fmu)
    end

    return true
end
