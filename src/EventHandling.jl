# This file is part of JuliaFMI.
# Licensed under MIT: https://github.com/AnHeuermann/JuliaFMI/blob/master/LICENSE.txt

# This file contains functions for event handling.


"""
    handleEvent!(fmu::FMU)

Handles events of a FMU.

The function stops the continuous simualtion and enters event mode. Then an
event iteration is started and states and derivates get updated. Afet that the
simulation gets started again.
"""
function handleEvent!(fmu::FMU)

    # Save variable values to csv
    writeValuesToCSV(fmu)

    fmi2EnterEventMode(fmu)

    # Event iteration
    fmu.eventInfo = eventIteration!(fmu)

    # Update changed continuous states and derivatives
    getContinuousStates!(fmu)
    getDerivatives!(fmu)

    # Enter continuous-time mode
    fmi2EnterContinuousTimeMode(fmu)
    getEventIndicators!(fmu)

    # Retrieve solution at simulation restart
    getAllVariables!(fmu)
    if fmu.eventInfo.valuesOfContinuousStatesChanged
        getContinuousStates!(fmu)
    end

    # Check if nominals changed
    if fmu.eventInfo.nominalsOfContinuousStatesChanged
        error("Nominals not handled at the moment")
        # TODO handle nominals
        # getNominalsOfContinuousStates(fmu)
    end

    if fmu.eventInfo.nextEventTimeDefined
        nextTime = min(fmu.eventInfo.nextEventTime, fmu.experimentData.stopTime)
    else
        nextTime = fmu.experimentData.stopTime + fmu.experimentData.stepSize
    end
end


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


function eventIteration!(fmu::FMU)

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
