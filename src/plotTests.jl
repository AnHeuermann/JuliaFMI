# This file is part of JuliaFMI.
# Licensed under MIT: https://github.com/AnHeuermann/JuliaFMI/blob/master/LICENSE.txt

# This file contains functionalities to show simulation results of a FMU.

using Plots, CSV

function plotTests(csvfile::String)
    if !isfile(csvfile)
        error("File $csvfile does not exist.")
    end

    def = CSV.read(csvfile, delim=",")
    plotdatanames = names(def)
    plotlyjs()
    plt = plot()
    for i in 2:length(plotdatanames)
            plot!(def.time, def[Symbol(plotdatanames[i])], label=plotdatanames[i] )
    end
    gui(plt)
end
