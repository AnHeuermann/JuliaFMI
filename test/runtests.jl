# This file is part of JuliaFMI.
# Licensed under MIT: https://github.com/AnHeuermann/JuliaFMI/blob/master/LICENSE.txt

# This file contains does the unit testing.

"""
Run all tests for simulating FMU's
"""

using Test

include("tests.jl")
include("fmi-cross-check-tests.jl")

if !isdir("runtests")
    mkdir("runtests")
end
cd("runtests")

@testset "All Tests" begin
    @testset "Simulating simple FMUs" begin
        @testset "Without events" begin
            @test testHelloFMI20World()
            if Sys.islinux()
                @test testCauerLowPassAnalog()
            end
        end;
        @testset "With events" begin
            @test testBouncingBall()
        end;
    end;

    runFMICrossTests()
end;

cd("..")
rm("runtests", true, true)
