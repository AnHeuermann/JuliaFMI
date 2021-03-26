# This file is part of JuliaFMI.
# Licensed under MIT: https://github.com/AnHeuermann/JuliaFMI/blob/master/LICENSE.txt

# This file contains functions to be exported for JuliaFMI package.

module JuliaFMI

include("FMICallbackFunctions.jl")
include("FMI2CTypes.jl")
include("FMI2Types.jl")
include("HelperFunctions.jl")
include("modelDescriptionParsing.jl")
include("FMIWrapper.jl")
include("FMUSimulator.jl")

"""
Main function to simulate a FMU
"""
function simulateFMU(pathToFMU::String)
    main(pathToFMU)
end

export simulateFMU


end # module
