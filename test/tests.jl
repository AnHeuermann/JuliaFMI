# This file is part of JuliaFMI.
# Licensed under MIT: https://github.com/AnHeuermann/JuliaFMI/blob/master/LICENSE.txt

# This file contains simple tests to validate JuliaFMI simulations.

"""
Define tests for unit testing
"""

thisDir = dirname(Base.source_path())
include("$(dirname(thisDir))/src/FMUSimulator.jl")
include("checkResults.jl")


if Sys.iswindows()
    fmuTestDir = joinpath(thisDir, "winFMU")
elseif Sys.islinux()
    fmuTestDir = joinpath(thisDir, "linuxFMU")
elseif Sys.isapple()
    fmuTestDir = joinpath(thisDir, "darwinFMU")
else
    error("OS not supported for this tests.")
end

"""
    testHelloFMI20World()

Run most basic simulation test.

FMU generated for Modelica model:
```
    model HelloFMI20World
      Real x(start=1);
      parameter Real a=2;
    equation
      der(x) = a * x;
    end HelloFMI20World;
```
"""
function testHelloFMI20World()
    helloFMI20World = joinpath(fmuTestDir,"HelloFMI20World.fmu")
    main(helloFMI20World)
    referenceFile = joinpath(fmuTestDir,"$(dirname(thisDir))//test//modelicaSource//HelloFMI20World_ref.csv")
    return diffSimulationResults("HelloFMI20World_results.csv", referenceFile, "HelloFMI20World")
end


"""
    testBouncingBall()

Run simple test simulating a bouncing ball.

FMU generated from Modelica model:
```
    model BouncingBallFMI20
      parameter Real e=0.7 \"coefficient of restitution\";
      parameter Real g=9.81 \"gravity acceleration\";
      Real h(start=1) \"height of ball\";
      Real v \"velocity of ball\";
      Real v_new;
    equation
      der(v) = -g;
      der(h) = v;

      when h <= 0.0 then
        v_new = -e*pre(v);
        reinit(v, v_new);
      end when;
    end BouncingBallFMI20;
```
"""
function testBouncingBall()
    bouncingBall = joinpath(fmuTestDir,"BouncingBallFMI20.fmu")
    main(bouncingBall)
    referenceFile = joinpath(fmuTestDir,"$(dirname(thisDir))//test//modelicaSource//BouncingBallFMI20_ref.csv")
    return diffSimulationResults("BouncingBallFMI20_results.csv", referenceFile, "BouncingBallFMI20")
end


"""
    testCauerLowPassAnalog()

Run test simulating Modelica.Electrical.Analog.Examples.CauerLowPassAnalog of
Modelica Standard Library 3.2.3
"""
function testCauerLowPassAnalog()
    cauerLowPass = joinpath(fmuTestDir,"Modelica_Electrical_Analog_Examples_CauerLowPassAnalog.fmu")
    main(cauerLowPass)
    referenceFile = joinpath(fmuTestDir,"$(dirname(thisDir))//test//modelicaSource//CauerLowPass_ref.csv")
    return diffSimulationResults("Modelica.Electrical.Analog.Examples.CauerLowPassAnalog_results.csv", referenceFile, "Modelica_Electrical_Analog_Examples_CauerLowPassAnalog")
end
