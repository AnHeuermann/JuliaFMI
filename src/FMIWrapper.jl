"""
Wrapper to call FMI functions from Julia
"""

include("FMI2Types.jl")
include("FMICallbackFunctions.jl") # Callbacks for logging and memory handling


function fmi2Instantiate(libHandle::Ptr{Nothing}, instanceName::String,
    fmuType::fmuType, fmuGUID::String, fmuResourceLocation::String,
    functions::CallbackFunctions, visible::Bool=true, loggingOn::Bool=false)

    func = dlsym(libHandle, :fmi2Instantiate)

    fmi2Component = ccall(
      func,
      Ptr{Cvoid},
      (Cstring, Cint, Cstring, Cstring,
      Ref{CallbackFunctions}, Cint, Cint),
      instanceName, fmuType, fmuGUID, fmuResourceLocation,
      Ref(functions), visible, loggingOn
      )

    if fmi2Component == C_NULL
      error("fmi2Instantiate: Returned NULL.")
    end
end
