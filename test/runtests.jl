"""
Run all tests for simulating FMU's
    ToDo: Add a working simulator :-(
"""

include("..\\src\\FMUSimulator.jl")

thisDir = dirname(Base.source_path())
helloFMI20World = string(thisDir,"\\HelloFMI20World.fmu")
bouncingBall = string(thisDir,"\\BouncingBallFMI20.fmu")

# First simple test
main(helloFMI20World)
