"""
Run all tests for simulating FMU's
    ToDo: Add a working simulator :-(
"""

include("../src/FMUSimulator.jl")

thisDir = dirname(Base.source_path())
include("$(dirname(thisDir))/src/FMUSimulator.jl")


if Sys.iswindows()
    fmuTestDir = string(thisDir, "/winFMU")
elseif Sys.islinux()
    fmuTestDir = string(thisDir, "/linuxFMU")
else
    error("OS not supportet for this tests.")
end

# First simple test
function testHelloFMI20World()
    helloFMI20World = string(fmuTestDir,"/HelloFMI20World.fmu")
    main(helloFMI20World)
end

function testBouncingBall()
    bouncingBall = string(fmuTestDir,"/BouncingBallFMI20.fmu")
    main(bouncingBall)
end
