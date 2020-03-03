# This file is part of JuliaFMI.
# Licensed under MIT: https://github.com/AnHeuermann/JuliaFMI/blob/master/LICENSE.txt

# This file contains functions to be exported for JuliaFMI package.

module JuliaFMI

include("FMI2Types.jl")
include("FMICallbackFunctions.jl")
include("modelDescriptionParsing.jl")
include("FMIWrapper.jl")
include("EventHandling.jl")
include("FMUSimulator.jl")
include("compare_CSV.jl")

"""
Main function to simulate a FMU
"""
function simulateFMU(pathToFMU::String)
    main(pathToFMU)
end

export simulateFMU
export csvFilesEqual


end # module
