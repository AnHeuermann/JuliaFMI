"""
Run all tests for simulating FMU's
    ToDo: Add a working simulator :-(
"""

include("..\\src\\FMUSimulator.jl")

thisDir = dirname(Base.source_path())

# First simple test
main(string(thisDir,"\\helloFMI20World.fmu"))
