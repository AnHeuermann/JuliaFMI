# This file is part of JuliaFMI.
# License is MIT: https://servant-om.fh-bielefeld.de/gitlab/AnHeuermann/FMU_JL_Simulator/blob/master/LICENSE.txt

# This file contains functions for handling events

include("FMI2Types.jl")
include("FMICallbackFunctions.jl") # Callbacks for logging and memory handling


"""
    arrayDiffSign(array1::Array{Float64,1}, array2::Array{Float64,1})

Checks if signs of two arrays are different component-wise and returns index of difference.
Helper function for bisection.
"""
function arrayDiffSign(array1::Array{Float64,1}, array2::Array{Float64,1})

    if length(array1) != length(array2)
        throw(DimensionMismatch("Left and right array of event indicators have different sizes."))
    end

    for i in 1:length(array1)
        if (array1[i] > 0 && array2[i] <= 0) || (array1[i] <= 0 && array2[i] > 0)
            return (true,i)
        end
    end

    return (false,-1)
end


function eventIteration!(fmu)

    k = 0
    max_k = 100

    fmu.eventInfo.newDiscreteStatesNeeded = true
    fmu.eventInfo.terminateSimulation = false
    while fmu.eventInfo.newDiscreteStatesNeeded && k < max_k
        k += 1
        # Update discrete states
        fmu.eventInfo = fmi2NewDiscreteStates!(fmu)
        if fmu.eventInfo.terminateSimulation
            error("FMU was terminated in event at time $(fmu.simulationData.time)")
        end
    end

    if k == max_k
        error("FMU reached maximum number of iterations in event iteration.")
    end

    return fmu.eventInfo
end


"""
    findEventSimple(fmu::FMU)

Returns `true` if an event occured in last step, othwerwise `false`.
"""
function findEventSimple(fmu::FMU)

    leftEventIndicators = copy(fmu.simulationData.eventIndicators)
    getEventIndicators!(fmu)
    rightEventIndicators = copy(fmu.simulationData.eventIndicators)
    (hasDiffSigns, index) = arrayDiffSign(leftEventIndicators, rightEventIndicators)
    if hasDiffSigns
        return true
    else
        return false
    end
end


"""
    findEvent(fmu::FMU)

Checks if an event occured and find event time.

Uses bisection method for `eventIndicators` for given `fmu` to find event time.
"""
function findEvent(fmu::FMU)

    leftTime = fmu.simulationData.lastStepTime
    rightTime = fmu.simulationData.time

    leftEventIndicators = copy(fmu.simulationData.eventIndicators)
    getEventIndicators!(fmu)
    rightEventIndicators = copy(fmu.simulationData.eventIndicators)

    # Check if there are any events
    if !arrayDiffSign(leftEventIndicators, rightEventIndicators)
        return (false, 0, nothing)
    end

    # Copy left and right states
    leftStates = copy(fmu.simulationData.modelVariables.oldStates)
    rightStates = Array{Float64}(undef, fmu.modelData.numberOfStates)
    for i=1:fmu.modelData.numberOfStates
        rightStates[i] = fmu.simulationData.modelVariables.reals[i].value
    end

    # Call bisection
    (leftStates, rightTime) = bisection(fmu, leftTime, rightTime, leftStates,
        rightStates, leftEventIndicators, rightEventIndicators)

    # Set FMU states to left states
    for i=1:fmu.modelData.numberOfStates
        fmu.simulationData.modelVariables.reals[i].value =leftStates[i]
    end
    setContinuousStates!(fmu)
    setTime!(fmu, rightTime, false)


    return (true, rightTime, rightStates)
end


"""
    bisection(fmu, leftTime, rightTime, leftStates, rightStates, leftEventIndicators, rightEventIndicators)

Helper function for function `findEvent`.
"""
function bisection(fmu, leftTime, rightTime, leftStates, rightStates,
    leftEventIndicators, rightEventIndicators)

    debug = true

    steps = 0
    minimumStepSize = 1e-8      # TODO: Read mimimumStepSize from fmu experiment data
    maxSteps = ceil(log2((rightTime-leftTime)/minimumStepSize)) + 1
    centerTime = 0

    if debug
        println("Bisection method starts in interval [$leftTime, $rightTime].")
        println("Tolerance is set to $minimumStepSize and maximum number of steps is $maxSteps.")
    end

    while rightTime - leftTime > minimumStepSize && steps < maxSteps
        steps += 1

        # Evaluate eventIndicators in center of intervall
        centerTime = 0.5*(rightTime + leftTime)
        setTime!(fmu, centerTime, false)

        # Interpolate states at centerTime
        for i=1:fmu.modelData.numberOfStates
            fmu.simulationData.modelVariables.reals[i].value = 0.5 * (leftStates[i] + rightStates[i])
        end
        setContinuousStates!(fmu)

        # Compute values of dependent of new states
        getEventIndicators!(fmu)
        centerEventIndicators = copy(fmu.simulationData.eventIndicators)     # TODO Do I need to copy here?

        # TODO Check what happens when event is on leftTime, centerTime or rightTime
        # Check for event in first half of intervall [leftTime, centerTime]
        if arrayDiffSign(leftEventIndicators, centerEventIndicators)
            rightTime = centerTime
            rightEventIndicators = centerEventIndicators        # This does not copy memory, right?
            getContinuousStates!(fmu)
            for i=1:fmu.modelData.numberOfStates
                rightStates[i] = fmu.simulationData.modelVariables.reals[i].value
            end

        # Check for event in second half of intervall [centerTime, rightTime]
        else
            leftTime = centerTime
            leftEventIndicators = centerEventIndicators
            getContinuousStates!(fmu)
            for i=1:fmu.modelData.numberOfStates
                leftStates[i] = fmu.simulationData.modelVariables.reals[i].value
            end
        end

        if debug
            println("Bisection method $steps-th step in interval [$leftTime, $rightTime].")
        end
    end

    if steps == maxSteps
        error("Event was not found in maximum number of Steps!")
    end

    return (leftStates, rightTime)
end
