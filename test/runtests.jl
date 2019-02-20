"""
Run all tests for simulating FMU's
"""

using Test

include("tests.jl")

@testset "Simulating simple FMUs" begin
    @testset "Without events" begin
        @test testHelloFMI20World()
    end;
    @testset "With events" begin
        @test testBouncingBall()
    end;
end;
