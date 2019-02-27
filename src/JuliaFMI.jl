module JuliaFMI

# Dependecies
using Libdl         # For using dlopen, dlclose and so on
using LightXML      # For parsing XML files

export simulateFMU

function simulateFMU(pathToFMU::String)
    main(pathToFMU)
end

end # module
