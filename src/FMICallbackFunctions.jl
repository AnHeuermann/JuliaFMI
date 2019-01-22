"""
Callback functions for logging and memory managment passed to FMU instance.
"""

include("FMI2Types.jl")

using Libdl         # For using dlopen, dlclose and so on

# Macro to identify logger library
macro libLogger()
    if Sys.iswindows()
        return string(dirname(dirname(Base.source_path())),"\\bin\\win64\\logger.dll")
    elseif Sys.islinux()
        return string(dirname(dirname(Base.source_path())),"/bin/unix64/logger.so")
    end
end

# Logger for error and information messages
function fmi2CallbackLogger(componentEnvironment,
    instanceName, status, category,
    message...)

    try
        println("[", string(status), "][", unsafe_string(category), "] ", unsafe_string(message))
    catch
        println("Error trying to log message from FMU!")
    end
end
const fmi2CallbacLogger_funcWrapC = @cfunction(fmi2CallbackLogger, Cvoid,
(Ptr{Cvoid}, Cstring, Cuint, Cstring, Tuple{Cstring}))

# Allocate with zeroes initialized memory
function fmi2AllocateMemory(nitems::Csize_t, size::Csize_t)
    print("Allocate Memory: ")
    ptr = Libc.calloc(nitems, size)
    println("Returned pointer $ptr.")
    return ptr
end
const fmi2AllocateMemory_funcWrapC = @cfunction(fmi2AllocateMemory, Ptr{Cvoid}, (Csize_t, Csize_t))


# Free memory allocated with fmi2AllocateMemory
function fmi2FreeMemory(ptr::Ptr{Nothing})
    println("Freeing pointer $ptr.")
    Libc.free(ptr)
end
const fmi2FreeMemory_funcWrapC = @cfunction(fmi2FreeMemory, Cvoid, (Ptr{Cvoid},))


# open shared library with logger function
libLoggerHandle = dlopen(@libLogger)
fmi2CallbacLogger_Cfunc = dlsym(libLoggerHandle, :logger)

const fmi2Functions = CallbackFunctions(
    #fmi2CallbacLogger_funcWrapC,       # Logger in Julia
    fmi2CallbacLogger_Cfunc,            # Logger in C
    fmi2AllocateMemory_funcWrapC,
    fmi2FreeMemory_funcWrapC,
    C_NULL,
    C_NULL)



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
