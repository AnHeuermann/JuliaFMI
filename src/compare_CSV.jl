# This file is part of JuliaFMI.
# Licensed under MIT: https://github.com/AnHeuermann/JuliaFMI/blob/master/LICENSE.txt

# This file contains tools to verify results from a csv file.

import DataFrames
import Trajectories
import CSV

"""
    csvFilesEqual(csvFile1Path::String, csvFile1Path::String, epsilon::Real)

Checks if trajectories of variables in two CSV files are equal.
"""
function csvFilesEqual(csvFile1Path::String, csvFile2Path::String,
    epsilon::Real)

    # Load csv files
    csvData1 = CSV.read(csvFile1Path)
    csvData2 = CSV.read(csvFile2Path)

    # Compare trajectories for all variables
    allVars = setdiff(names(csvData1), [:time])

    # grep only those variables that are in both csv files
    checkvars = intersect(allVars, names(csvData2))

    return csvCompareVars(csvData1, csvData2, checkvars, epsilon)
end


"""
    csvFilesEqual(csvFile1Path::String, csvFile2Path::String, checkVars::Array{String,1}, epsilon::Real)

Checks if trajectories of variables `checkVars` in two CSV files are equal.
"""
function csvFilesEqual(csvFile1Path::String, csvFile2Path::String,
    checkVars::Array{String,1}, epsilon::Real)

    # Load csv files
    csvData1 = CSV.read(csvFile1Path)
    csvData2 = CSV.read(csvFile2Path)

    # Compare trajectories for specified variables
    return csvCompareVars(csvData1, csvData2, checkVars, epsilon)
end


"""
    csvFilesEqual(csvFile1Path::String, csvFile2Path::String, checkVars::Array{String,1})

Checks if trajectories of variables `checkVars` in two CSV files are equal for nonspecific epsilon.
"""
function csvFilesEqual(csvFile1Path::String, csvFile2Path::String,
    checkVars::Array{String,1})

    # Load csv files
    csvData1 = CSV.read(csvFile1Path)
    csvData2 = CSV.read(csvFile2Path)
    epsilon = 0.118

    # Compare trajectories for specified variables
    return csvCompareVars(csvData1, csvData2, checkVars, epsilon)
end


"""
    csvFilesEqual(csvFile1Path::String, csvFile2Path::String)

Checks if trajectories in two CSV files are equal for nonspecific epsilon.
"""
function csvFilesEqual(csvFile1Path::String, csvFile2Path::String)

    # Load csv files
    csvData1 = CSV.read(csvFile1Path)
    csvData2 = CSV.read(csvFile2Path)
    epsilon = 0.118

    # Compare trajectories for all variables
    allVars = setdiff(names(csvData1), [:time])

    # grep only those variables that are in both csv files
    checkvars = intersect(allVars, names(csvData2))

    # Compare trajectories for specified variables
    return csvCompareVars(csvData1, csvData2, checkvars, epsilon)
end


"""
    csvCompareVars(csvData1:::DataFrames.DataFrame, csvData2:::DataFrames.DataFrame, checkVars::Array{Symbol,1}, epsilon::Real)

Helper function to check if trajectories of variables `checkVars` in two
DataFrames are equal.
"""
function csvCompareVars(csvData1::DataFrames.DataFrame,
    csvData2::DataFrames.DataFrame, checkVars::Array{Symbol,1},
    epsilon::Real)

    isEqual = true

    if  isempty(checkVars)
        @error "Cannot compare Files. They not have any same Variables."
        return false
    end

    # rename variables like der(x) to der_x_
    newNames = [replaceNames!(names(csvData1)), replaceNames!(names(csvData2))]
    for (i, t) in enumerate(newNames[1])
        rename!(csvData1, names(csvData1)[i] => newNames[1][i])
    end
    for (i, t) in enumerate(newNames[2])
        rename!(csvData2, names(csvData2)[i] => newNames[2][i])
    end
    checkVars = replaceNames!(checkVars)

    # Check if comparable
    if unique(names(csvData1)) != names(csvData1)
        @error "Got duplicate names in csv file. Can't compare."
        return false
    end

    # Compare trajectories for each specified variables
    for varName in checkVars
        infoStr = "Checking Trajectories for Variable: $varName  \t"
        trajectory1 = Trajectories.trajectory(csvData1.time, csvData1[!,Symbol(varName)])
        trajectory2 = Trajectories.trajectory(csvData2.time, csvData2[!,Symbol(varName)])

        try
            if trajectoriesEqual(trajectory1::Trajectories.Trajectory, trajectory2::Trajectories.Trajectory, epsilon)
                infoStr *= "true"
            else
                infoStr *= "false"
                isEqual = false
            end

        catch
            infoStr *= "false"
            isEqual = false
        end
        @info infoStr
    end

    @info "Check complete."
    return isEqual
end


"""
    function trajectoriesEqual(trajectory1::Trajectory, trajectory2::Trajectory, epsilon)

Compares if two trajectories are equal by linear interpolation and comparing to
definded error ϵ.
"""
function trajectoriesEqual(trajectory1::Trajectories.Trajectory, trajectory2::Trajectories.Trajectory,
    epsilon::Real)

    time1 = trajectory1.t
    values1 = trajectory1.x
    time2 = trajectory2.t
    values2 = trajectory2.x

    intersectionTime = vcat(max(time1[1], time2[1]), time1[max(time1[1], time2[1]) .< time1 .< min(time1[end], time2[end])], min(time1[end], time2[end]))
    if intersectionTime[1] >= intersectionTime[end]
        error("Can't compare trajectories. Time intervalls not intersecting")
    end

    #find Events and check if equal in both files
    events_1 = []
    for (i, t) in enumerate(time1)
        if i != 1
            if time1[i - 1] == time1[i]
                append!(events_1, time1[i])
            end
        end
    end
    events_1 = unique(events_1)
    events_2 = []
    for (i, t) in enumerate(time2)
        if i != 1
            if time2[i - 1] == time2[i]
                append!(events_2, time2[i])
            end
        end
    end
    events_2 = unique(events_2)

    if length(events_1) != length(events_2)
        error("Files have not the same number of events")
    elseif length(events_1) != 0
        for i in 1:lastindex(events_1)
            if abs(events_1[i] - events_2[i]) > epsilon
                error("Events have not the same timestamps.")
            end
        end
    end
    # filter values
    intersection_time_values1 = values1[findall(x->x == intersectionTime[1], time1)[1]:findall(x->x == intersectionTime[end], time1)[1]]
    for (i, t) in enumerate(intersectionTime)
        if intersectionTime[i] in events_1
                continue
        end
        if abs(Trajectories.interpolate(Trajectories.Linear(), trajectory2, t) - intersection_time_values1[i]) > epsilon
            return false
        end
    end

    return true
end


"""
Helper function to replace brackets in DataFrames names.
"""
function replaceNames!(data::Array{Symbol,1})

    newNames = Array{String}(undef, length(data))
    for (i, name) in enumerate(data)
        newNames[i] = String(data[i])
        newNames[i] = replace(newNames[i], "(" => "_")
        newNames[i] = replace(newNames[i], ")" => "_")
    end

    return Symbol.(newNames)
end
