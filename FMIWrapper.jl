"""
Wrapper to call FMI functions from Julia
"""

include("FMI2Types.jl")
include("FMICallbackFunctions.jl") # Callbacks for logging and memory handling


function fmi2Instantiate(libHandle::Ptr{Nothing}, instanceName::String,
    fmuType::Int, fmuGUID::String, fmuResourceLocation::String,
    functions::CallbackFunctions, visible::Bool, loggingOn::Bool)

    func = dlsym(libHandle, :fmi2Instantiate)

    fmi2Componente = ccall(
      func,
      Ref{Cvoid},
      (Cstring, Cint, Cstring, Cstring,
      Ref{CallbackFunctions}, Cint, Cint),
      instanceName, fmuType, fmuGUID, fmuResourceLocation,
      Ref(functions), visible, loggingOn
      )

    if fmi2Component == C_NULL
      error("fmi2Instantiate: Returned NULL.")
    end
end
