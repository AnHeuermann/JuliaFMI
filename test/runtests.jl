"""
Run all tests for simulating FMU's
    ToDo: Add a working simulator :-(
"""

thisDir = dirname(Base.source_path())

include("$(dirname(thisDir))/src/FMUSimulator.jl")

# First simple test
function testHelloFMI20World()
    helloFMI20World = string(thisDir,"\\HelloFMI20World.fmu")
    main(helloFMI20World)
end

function testBouncingBall()
    bouncingBall = string(thisDir,"\\BouncingBallFMI20.fmu")
    main(bouncingBall)
end
