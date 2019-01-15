"""
Run all tests for simulating FMU's
    ToDo: Add a working simulator :-(
"""

include("../src/FMUSimulator.jl")

fmuTestDir = dirname(Base.source_path())
if Sys.iswindows()
    fmuTestDir = string(fmuTestDir, "/winFMU")
elseif Sys.islinux()
    fmuTestDir = string(fmuTestDir, "/linuxFMU")
else
    error("OS not supportet for this tests.")
end

include("$(dirname(thisDir))/src/FMUSimulator.jl")

# First simple test
function testHelloFMI20World()
    helloFMI20World = string(fmuTestDir,"/HelloFMI20World.fmu")
    main(helloFMI20World)
end

function testBouncingBall()
    bouncingBall = string(fmuTestDir,"/BouncingBallFMI20.fmu")
    main(bouncingBall)
end
