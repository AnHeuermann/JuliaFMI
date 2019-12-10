# This file is part of JuliaFMI.
# Licensed under MIT: https://github.com/AnHeuermann/JuliaFMI/blob/master/LICENSE.txt

# This file contains functions to check results of tests.

using OMJulia
using OMJulia: sendExpression


"""
```
diffSimulationResults(actualFile::String,
                      expectedFile::String,
                      diffPrefix::String,
                      relTol::Real=1e-3,
                      relTolDiffMinMax::Real=1e-4,
                      rangeDelta::Real=0.002,
                      vars::Array{String,1}=Array{String}(undef,0),
                      keepEqualResults::Bool=false)
```
Takes two result files and compares them using OMJulia.

By default, all selected variables that are not equal in the two files are
output to diffPrefix.varName.csv.
The output is the names of the variables for which files were generated.
"""
function diffSimulationResults(actualFile::String, expectedFile::String,
    diffPrefix::String, relTol::Real=1e-3, relTolDiffMinMax::Real=1e-4,
    rangeDelta::Real=0.002, vars::Array{String,1}=Array{String}(undef,0),
    keepEqualResults::Bool=false)

    # Check if files are found
    if !isfile(actualFile)
        error("File $actualFile not found.")
    end
    if !isfile(expectedFile)
        error("File $expectedFile not found.")
    end

    omc=OMJulia.OMCSession()

    if length(vars) > 0
        vars_string = "{"
        for var in vars
           vars_string = hcat(vars_string, "\"", var, "\"")
        end
        vars_string = hcat(vars_string, "}")
    else
        vars_string = "fill(\"\",0)"
    end

    expression = "diffSimulationResults(actualFile=\"$actualFile\", expectedFile=\"$expectedFile\", diffPrefix=\"$diffPrefix\", relTol=$relTol, relTolDiffMinMax=$relTolDiffMinMax, rangeDelta=$rangeDelta,  vars=$vars_string, keepEqualResults=$keepEqualResults)"

    (isEqual, diffVars) = sendExpression(omc, expression)

    if !isEqual
        println("Simulation results wrong for variables: $diffVars")
        # Remove diffPrefix.varName.csv
        for varName in diffVars
            rm("$diffPrefix.$varName.csv")
        end
    end

    return isEqual
end
