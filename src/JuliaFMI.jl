# This file is part of JuliaFMI.
# License is MIT: https://servant-om.fh-bielefeld.de/gitlab/AnHeuermann/FMU_JL_Simulator/blob/master/LICENSE.txt

# This file contains the module JuliaFMI and exports functions for users

"""
# JuliaFMI
Julia simulator for 2.0 ModelExchange Functional Mockup Units (FMUs)

## Documentation
Can be found at ...

## Usage
```
JuliaFMI.simulate(pathToFMU)
```
"""
module JuliaFMI


# Dependecies
using Libdl         # For using dlopen, dlclose and so on
using LightXML      # For parsing XML files

export simulate


"""
    function simulate(pathToFMU::String)

Simulates a FMU and saves results in CSV file.

## Example
```
julia> pathToFMU = joinpath(\"path\", \"to\", \"myFMU.fmu\")
julia> JuliaFMI.simulate(pathToFMU)
```
"""
function simulate(pathToFMU::String)
    main(pathToFMU)
end

end # module
