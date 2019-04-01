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
