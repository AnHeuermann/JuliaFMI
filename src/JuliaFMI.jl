# This file is part of JuliaFMI.
# Licensed under MIT: https://github.com/AnHeuermann/JuliaFMI/blob/master/LICENSE.txt

# This file contains functions to be exported for JuliaFMI package.

module JuliaFMI

include("FMUSimulator.jl")

# Dependecies
using Libdl         # For using dlopen, dlclose and so on
using LightXML      # For parsing XML files

export simulateFMU


"""
Main function to simulate a FMU
"""
function simulateFMU(pathToFMU::String)
    main(pathToFMU)
end

end # module
