# This file is part of JuliaFMI.
# Licensed under MIT: https://github.com/AnHeuermann/JuliaFMI/blob/master/LICENSE.txt

# This file contains functions to be exported for JuliaFMI package.

module JuliaFMI

# Dependecies
using Libdl                     # For using dlopen, dlclose and so on
using LightXML                  # For parsing XML files
using DifferentialEquations     # For Integrators
using Sundials                  # For IDA Solver

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
    main(pathToFMU, IDA())
end

function simulateFMU(pathToFMU::String, intergrator::Function)
    main(pathToFMU, intergrator)
end

end # module
