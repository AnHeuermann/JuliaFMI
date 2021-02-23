# This file is part of JuliaFMI.
# Licensed under MIT: https://github.com/AnHeuermann/JuliaFMI/blob/master/LICENSE.txt

# This file contains simple tests to validate JuliaFMI simulations.

using JuliaFMI

include("compare_CSV.jl")

thisDir = dirname(Base.source_path())

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
    @testset "Simulation" begin
        @info("simulatin model: helloFMI20World")
        helloFMI20World = joinpath(fmuTestDir,"HelloFMI20World.fmu")
        @test simulateFMU(helloFMI20World)
    end
    @testset "Verify Results" begin
        @info("compare results of model: HelloFMI20World")
        @test csvFilesEqual("HelloFMI20World_results.csv", joinpath("modelicaSource", "HelloFMI20World_ref.csv"))
    end
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
    @testset "Simulation" begin
        @info("simulatin model: BouncingBallFMI20")
        bouncingBall = joinpath(fmuTestDir,"BouncingBallFMI20.fmu")
        @test simulateFMU(bouncingBall)
    end
    @testset "Verify Results" begin
        @info("compare results of model: BouncingBallFMI20")
        @test csvFilesEqual("BouncingBallFMI20_results.csv", joinpath("modelicaSource", "BouncingBallFMI20_ref.csv"))
    end
end

function testCauerLowPassAnalog()
    @testset "Simulation" begin
        @info("simulatin model: Modelica_Electrical_Analog_Examples_CauerLowPassAnalog")
        cauerLowPass = joinpath(fmuTestDir,"Modelica_Electrical_Analog_Examples_CauerLowPassAnalog.fmu")
        @test simulateFMU(cauerLowPass)
    end
    @testset "Verify Results" begin
        @test_broken false
    end
end
