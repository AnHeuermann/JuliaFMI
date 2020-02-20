# This file is part of JuliaFMI.
# Licensed under MIT: https://github.com/AnHeuermann/JuliaFMI/blob/master/LICENSE.txt

# This file contains functions to be exported for JuliaFMI package.

module JuliaFMI

# Dependecies
using Libdl         # For using dlopen, dlclose and so on
using LightXML      # For parsing XML files
using DifferentialEquations

export simulateFMU

function simulateFMU(pathToFMU::String)
    main(pathToFMU, Euler())
end

function simulateFMU(pathToFMU::String, intergrator::String)
    main(pathToFMU, intergrator)
end

end # module
