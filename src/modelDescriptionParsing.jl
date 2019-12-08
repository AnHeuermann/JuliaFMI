# This file is part of JuliaFMI.
# Licensed under MIT: https://github.com/AnHeuermann/JuliaFMI/blob/master/LICENSE.txt

# This file contains function to parse the modelDecription.xml of a FMU.

"""
Dynamicaly create symbols from array of EnumerationItemAttribute
"""
function createEnumMacro(enumerationItemAttribute::Array{EnumerationItemAttribute,1})

    enumNames = Set([Symbol(item.name) for item in enumerationItemAttribute])
    enumValue = Set([item.value for item in enumerationItemAttribute])

    # ToDo: Doing nothing at the moment
    #print
end


"""
Get typeDefinitions of fmiModelDescription.
Returns Array{SimpleType} with typeDefinitions
"""
function getTypeDefinitions(xroot::XMLElement)

    elementTypeDefinitions = find_element(xroot, "TypeDefinitions")
    if elementTypeDefinitions != nothing
        # Loop over tag <SimpleType name="name" description="description">
        num_typeDefinitions = 0
        for element in child_elements(elementTypeDefinitions)
            num_typeDefinitions += 1
        end
        tmp_simpleTypes = Array{SimpleType}(undef,num_typeDefinitions)
        for (index,element) in enumerate(child_elements(elementTypeDefinitions))
            # ToDo AHeu: Add stuff
            tmp_name = attribute(element, "name"; required=true)
            tmp_description = attribute(element, "description"; required=false)

            # Loop over children of tag <SimpleType>
            tmp_attributes = nothing
            for children in child_nodes(element)
                if is_elementnode(children)
                    elementAttributeType = XMLElement(children)

                    # Attribute is Enumeration
                    if name(elementAttributeType) == "Enumeration"
                        # Check quantity
                        tmp_quantity = attribute(elementAttributeType, "quantity"; required=false)
                        if tmp_quantity === nothing
                            tmp_quantity = ""
                        end

                        # Count number of items
                        num_items = 0
                        for enumElem in child_elements(elementAttributeType)
                            num_items += 1
                        end
                        tmp_items = Array{EnumerationItemAttribute}(undef, num_items)

                        # Loop over <Item ...> tags of <Enumeration>
                        for (index, enumElem) in enumerate(child_elements(elementAttributeType))
                            tmp_attr_name = attribute(enumElem, "name"; required=true)
                            tmp_attr_value = parse(Int64, attribute(enumElem, "value"; required=true))
                            tmp_attr_description = attribute(enumElem, "description"; required=false)
                            if tmp_attr_description === nothing
                                tmp_attr_description = ""
                            end
                            tmp_items[index] = EnumerationItemAttribute(tmp_attr_name, tmp_attr_value, tmp_attr_description)
                        end
                        tmp_attributes = EnumerationAttributes(tmp_quantity, tmp_items)

                        # ToDo: Create Julia enum to use in EnumerationVariables
                        # createEnumMacro(tmp_items)

                    # ToDo: Add Real attributes, Integer attributes, Boolean attributes, String attributes
                    elseif name(elementAttributeType) == "Real"
                        @warn("SimpleType \"$(name(elementAttributeType))\" not implemented")
                        return nothing
                    elseif name(elementAttributeType) == "Integer"
                        @warn("SimpleType \"$(name(elementAttributeType))\" not implemented")
                        return nothing
                    elseif name(elementAttributeType) == "Boolean"
                        @warn("SimpleType \"$(name(elementAttributeType))\" not implemented")
                        return nothing
                    elseif name(elementAttributeType) == "String"
                        @warn("SimpleType \"$(name(elementAttributeType))\" not implemented")
                        return nothing

                    # Attribute is unknown
                    else
                        error("Parsing of modelDescription.xml failed: SimpleType \"$(name(elementAttributeType))\" unknown")
                    end
                end
            end

            if tmp_description === nothing
                tmp_simpleTypes[index] = SimpleType(tmp_name, "", tmp_attributes)
            else
                tmp_simpleTypes[index] = SimpleType(tmp_name, tmp_description, tmp_attributes)
            end
        end

        return tmp_simpleTypes
    # No TypeDefinitions found in XML
    else
        return nothing
    end
end


"""
Get log categories from fmiModelDescription.
Returns Array{LogCategory} with logCategories if found, otherwise nothing.
"""
function getLogCategories(xroot::XMLElement)

    elementLogCategories = find_element(xroot, "LogCategories")
    if elementLogCategories != nothing
        numCategories = 0
        for element in child_elements(elementLogCategories)
            numCategories += 1
        end
        logCategories = Array{LogCategory}(undef, numCategories)

        for (index, element) in enumerate(child_elements(elementLogCategories))
            tmp_name = attribute(element, "name"; required=true)
            tmp_description = attribute(element, "description"; required=false)
            if tmp_description === nothing
                logCategories[index] = LogCategory(tmp_name)
            else
                logCategories[index] = LogCategory(tmp_name, tmp_description)
            end
        end
        return logCategories

    # No LogCategories found
    else
        return nothing
    end
end


"""
Get default experiment from fmiModelDescription.
Returns ExperimentData.
"""
function getDefaultExperiment(xroot::XMLElement)
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

        defaultExperiment = ExperimentData(startTime, stopTime, tolerance, stepSize)
    else
        defaultExperiment = ExperimentData()
    end

    return defaultExperiment
end


"""
Get model variables from fmiModelDescription.
Returns Array{ScalarVariable}.
"""
function getModelVariables(xroot::XMLElement)

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

    return scalarVariables
end


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

        # ToDo: Add stuff for tag UnitDefinitions

        # Get attributes of tag TypeDefinitions
        md.typeDefinitions = getTypeDefinitions(xroot)

        # Get attributes of tag LogCategories
        md.logCategories = getLogCategories(xroot)

        # Get attributes of tag DefaultExperiment
        md.defaultExperiment = getDefaultExperiment(xroot)

        # ToDo: Add stuff for tag VendorAnnotations

        # Get attributes of tag ModelVariables
        md.modelVariables = getModelVariables(xroot)

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
