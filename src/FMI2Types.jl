"""
Declaration of FMI2 Types
"""


abstract type fmi2Status <: Integer end
primitive type fmi2OK <: fmi2Status 8 end
primitive type fmi2Warning <: fmi2Status 8 end
primitive type fmi2Discard <: fmi2Status 8 end
primitive type fmi2Error <: fmi2Status 8 end
primitive type fmi2Fatal <: fmi2Status 8 end
primitive type fmi2Pending <: fmi2Status 8 end

mutable struct fmi2ComponentEnvironment
    logFile::String     # if not empty location of file to write logger messages
                        # defaults to stderr ??
    numWarnings::Int
    numErrors::Int
    numFatals::Int
end


@enum fmuType begin
    modelExchange
    coSimulation
end
