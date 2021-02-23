# This file is part of JuliaFMI.
# Licensed under MIT: https://github.com/AnHeuermann/JuliaFMI/blob/master/LICENSE.txt

# This file contains the unit testing.

"""
Run all tests for simulating FMU's
"""

using JuliaFMI, Test

include("compare_CSV.jl")
include("tests.jl")
include("fmi-cross-check-tests.jl")


@testset "All Tests" begin
    @testset "Simulating simple FMUs" begin
        @testset "Without events" begin
            testHelloFMI20World()
            if Sys.islinux()
                testCauerLowPassAnalog()
            end
        end
        @testset "With events" begin
            testBouncingBall()
        end
    end

    runFMICrossTests()
end
