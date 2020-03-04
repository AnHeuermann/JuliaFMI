# This file is part of JuliaFMI.
# Licensed under MIT: https://github.com/AnHeuermann/JuliaFMI/blob/master/LICENSE.txt

# This file contains the main function to simulate a FMU.

"""
Simulator for FMUs of
FMI 2.0 for Model Exchange Standard
"""


# Macro to identify logger library
macro libLogger()
    if Sys.iswindows()
        return joinpath(dirname(dirname(Base.source_path())),"bin", "win64", "logger.dll")
    elseif Sys.islinux()
        return joinpath(dirname(dirname(Base.source_path())),"bin", "unix64", "logger.so")
    elseif Sys.isapple()
        return joinpath(dirname(dirname(Base.source_path())),"bin", "darwin64", "logger.dylib")
    else
        error("OS not supported")
    end
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
        nextTimeEventDefined = false

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
        getAllVariables!(fmu)
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
                fmu.simulationData.modelVariables.reals[i].value = fmu.simulationData.modelVariables.reals[i].value + h*fmu.simulationData.modelVariables.reals[i+fmu.modelData.numberOfStates].value
            end
            setContinuousStates!(fmu)
            getDerivatives!(fmu)

            # Detect time events
            timeEvent = nextTimeEventDefined && (abs(fmu.simulationData.time - nextTime) <= fmu.experimentData.stepSize)        # TODO add handling of time events

            # Detect events
            eventFound = findEventSimple(fmu)
            eventTime = fmu.simulationData.time

            # Inform the model abaut an accepted step
            (enterEventMode, terminateSimulation) = fmi2CompletedIntegratorStep(fmu, true)
            if terminateSimulation
                error("FMU was terminated after completed integrator step at time $(fmu.simulationData.time)")
            end

            # Handle events
            if timeEvent || eventFound || enterEventMode
                handleEvent!(fmu)
            end

            # save results
            getAllVariables!(fmu) # TODO check if this is working correctly. Maybe add getDerivatives!(fmu)
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
