"""
Define tests for unit testing
"""

thisDir = dirname(Base.source_path())
include("$(dirname(thisDir))/src/FMUSimulator.jl")


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
    return true
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
    return true
end

function testCauerLowPassAnalog()
    cauerLowPass = joinpath(fmuTestDir,"Modelica_Electrical_Analog_Examples_CauerLowPassAnalog.fmu")
    main(cauerLowPass)
    return true
end
