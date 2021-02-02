# This file is part of JuliaFMI.
# Licensed under MIT: https://github.com/AnHeuermann/JuliaFMI/blob/master/LICENSE.txt

# This file contains the unit testing.

"""
Run all tests for simulating FMU's
"""

using Test

include("tests.jl")
include("fmi-cross-check-tests.jl")

GC.enable(false)

@testset "All Tests" begin
    @testset "Simulating simple FMUs" begin
        @testset "Without events" begin
            testHelloFMI20World()
            GC.safepoint()
            if Sys.islinux()
                testCauerLowPassAnalog()
                GC.safepoint()
            end
        end
        @testset "With events" begin
            testBouncingBall()
            GC.safepoint()
        end
    end

    GC.safepoint()
    runFMICrossTests()
end
