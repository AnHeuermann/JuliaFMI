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
                stepSize = 1e-6/4
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

    # load dynamic library
    # TODO export DL_LOAD_PATH="/usr/lib/x86_64-linux-gnu" on unix systems
    # push!(DL_LOAD_PATH, "/usr/lib/x86_64-linux-gnu") maybe???
    fmu.libHandle = dlopen(pathToDLL)

    # Fill FMU with remaining data
    fmu.fmuResourceLocation = string("file:///", fmu.tmpFolder,"resources")
    fmu.fmuGUID = fmu.modelDescription.guid
    fmu.fmiCallbackFunctions = fmi2Functions

    return fmu
end


"""
Unload dynamic library and if `deleteTmpFolder=true` remove tmp files.
"""
function unloadFMU(fmu::FMU)
    unloadFMU(fmu.libHandle, fmu.tmpFolder)
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
Main function to simulate a FMU
"""
function main(pathToFMU::String)
    # load FMU
    fmu = loadFMU(pathToFMU)

    try
        # Instantiate FMU
        fmi2Instantiate!(fmu)

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

        # Initialize FMU
        fmi2EnterInitializationMode(fmu)

        # Exit Initialization
        fmi2ExitInitializationMode(fmu)

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
