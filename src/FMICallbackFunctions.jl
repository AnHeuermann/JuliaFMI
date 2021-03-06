# This file is part of JuliaFMI.
# Licensed under MIT: https://github.com/AnHeuermann/JuliaFMI/blob/master/LICENSE.txt

# This file contains callback functions to be used from a C FMU.

"""
Callback functions for logging and memory managment passed to FMU instance.
"""

# Logger for error and information messages
function fmi2CallbackLogger(componentEnvironment,
    instanceName, status, category, message...)

    try
        println("[", string(status), "][", unsafe_string(category), "] ", unsafe_string(message))
    catch
        println("Error trying to log message from FMU!")
    end
end

# Allocate with zeroes initialized memory
function fmi2AllocateMemory(nitems::Csize_t, size::Csize_t)
    print("Allocate Memory: ")
    ptr = Libc.calloc(nitems, size)
    println("Returned pointer $ptr.")
    return ptr
end


# Free memory allocated with fmi2AllocateMemory
function fmi2FreeMemory(ptr::Ptr{Nothing})
    println("Freeing pointer $ptr.")
    Libc.free(ptr)
end


"""
Helper functions
"""
function fmi2StatusToString(status::Real)
    if(fmi2OK)
        "fmi2OK"
    elseif(fmi2Warning)
        "fmi2Warning"
    elseif(fmi2Discard)
        "fmi2Discard"
    elseif(fmi2Error)
        "fmi2Error"
    elseif(fmi2Fatal)
        "fmi2Fatal"
    elseif(fmi2Pending)
        "fmi2Pending"
    else
        "Unknown fmi2Status"
    end
end

# Macro to identify logger library
macro libLogger()
    if Sys.iswindows()
        return joinpath(dirname(dirname(Base.source_path())),"bin", "win64", "logger.dll")
    elseif Sys.islinux()
        return joinpath(dirname(dirname(Base.source_path())),"bin", "unix64", "logger.so")
    elseif Sys.isapple()
        return joinpath(dirname(dirname(Base.source_path())),"bin", "darwin64", "logger.dylib")
    else
        error("OS not supported")
    end
end


