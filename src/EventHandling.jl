# This file is part of JuliaFMI.
# License is MIT: https://servant-om.fh-bielefeld.de/gitlab/AnHeuermann/FMU_JL_Simulator/blob/master/LICENSE.txt

# This file contains functions for handling events

include("FMI2Types.jl")
include("FMICallbackFunctions.jl") # Callbacks for logging and memory handling


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


function findEventSimple(fmu::FMU)

    leftEventIndicators = copy(fmu.simulationData.eventIndicators)
    getEventIndicators!(fmu)
    rightEventIndicators = copy(fmu.simulationData.eventIndicators)
    if arrayDiffSign(leftEventIndicators, rightEventIndicators)
        return true
    else
        return false
    end
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
        centerTime = 0.5*(rightTime + leftTime)
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
