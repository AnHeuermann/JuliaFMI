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
    elseif last(split(pathToModelDescription, "\\")) != "modelDescription.xml"
        error("File name is not equal to \"modelDescription.xml\" but $(last(split(pathToModelDescription, "\\")))" )
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
        for element in child_nodes(elementModelVariables)
            numberOfVariables += 1
        end
        #md.modelVariables

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

"""
Load DLL containing FMU functions and return handle to DLL
"""
function loadFMU(pathToFMU::String)
    loadFMU(pathToFMU, false, true)
end

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
    end

    # unzip FMU to tmp folder
    my_unzip(pathToFMU, tmpFolder)

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

    return(libHandle, md, tmpFolder)
end



"""
Unload dynamic library and remove tmp files
"""
function unloadFMU(libHandle::Ptr{Nothing}, tmpFolder::String,
    deleteTmpFolder=true::Bool)

    # unload dynamic library
    dlclose(libHandle)

    try
        dlclose(libLoggerHandle)
    catch
        rethrow()
    end

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

    try
        #use unzip
        run(Cmd(`unzip -qo $target`, dir = destinationDir))
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
    # Create uninitialized FMU
    fmu = FMU()

    # load FMU
    (fmu.libHandle, fmu.modelDescription, fmu.tmpFolder) = loadFMU(pathToFMU, false, true)
    fmu.FMUPath = pathToFMU
    fmu.modelName = fmu.modelDescription.modelName
    fmu.instanceName = fmu.modelDescription.modelName
    fmu.fmuResourceLocation = string(fmu.tmpFolder,"\\resources")
    fmu.fmuGUID = fmu.modelDescription.guid

    try
        # Instantiate FMU
        # ToDo: gives segmentation fault --> fix
        fmi2Instantiate(fmu.libHandle, fmu.instanceName,
            modelExchange, fmu.fmuGUID, fmu.fmuResourceLocation,
            fmi2Functions, true, true)
    finally
        # Unload FMU
        unloadFMU(fmu.libHandle, fmu.tmpFolder, false)
    catch
        rethrow()
    end
end
