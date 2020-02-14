# This file is part of JuliaFMI.
# Licensed under MIT: https://github.com/AnHeuermann/JuliaFMI/blob/master/LICENSE.txt

# This file contains functions to be exported for JuliaFMI package.

module JuliaFMI

# Dependecies
using Libdl         # For using dlopen, dlclose and so on
using LightXML      # For parsing XML files

include("FMI2Types.jl")
include("FMICallbackFunctions.jl")
include("modelDescriptionParsing.jl")
include("FMIWrapper.jl")
include("FMUSimulator.jl")

export simulateFMU


"""
Main function to simulate a FMU
"""
function simulateFMU(pathToFMU::String)
    main(pathToFMU)
end

end # module
