"""
Run tests from fmi-cross-check Git repository.
"""

using Test
using LibGit2
using DataFrames

thisDir = dirname(Base.source_path())
fmiCrossCheckDir = joinpath(thisDir,"fmi-cross-check")

include("$(dirname(thisDir))/src/FMUSimulator.jl")

if Sys.iswindows()
    fmiCrossCheckFMUDir = joinpath(thisDir, "fmi-cross-check", "fmus", "2.0", "me", "win$(Sys.WORD_SIZE)")
elseif Sys.islinux()
    fmiCrossCheckFMUDir = joinpath(thisDir, "fmi-cross-check", "fmus", "2.0", "me", "linux$(Sys.WORD_SIZE)")
elseif Sys.isapple()
    fmiCrossCheckFMUDir = joinpath(thisDir, "fmi-cross-check", "fmus", "2.0", "me", "darwin$(Sys.WORD_SIZE)")
else
    error("OS not supported for this tests.")
end


"""
    updateFMICrossTest()

Clone or fetch and pull modelica/fmi-cross-check repository from
https://github.com/modelica/fmi-cross-check.git.
"""
function updateFmiCrossCheck()

    if isdir(fmiCrossCheckDir)
        # Update repository
        println("Updating repository modelica/fmi-cross-check.")
        repo = GitRepo(fmiCrossCheckDir)
        LibGit2.fetch(repo)
        LibGit2.merge!(repo, fastforward=true)

    else
        # Clone repository
        println("Cloning repository modelica/fmi-cross-check.")
        println("This may take some minutes.")
        LibGit2.clone("https://github.com/modelica/fmi-cross-check.git", fmiCrossCheckDir )
        println("Cloned modelica/fmi-cross-check successfully.")
    end
end

"""
    cleanFmiCrossCheck()

Resets fmi-cross-check repository. All changes will get lost!
"""
function cleanFmiCrossCheck()

    if isdir(fmiCrossCheckDir)
        repo = GitRepo(fmiCrossCheckDir)
        head_oid = LibGit2.head_oid(repo)
        mode = LibGit2.Consts.RESET_HARD
        LibGit2.reset!(repo, head_oid, mode)
    end
end


"""
    runFMICrossTests()

Run and test all fmi-cross-test that are supportet on current system.
"""
function runFMICrossTests()
    # Check if repository is up to date
    updateFmiCrossCheck()

    # Collect all tests for current system
    df = DataFrame(toolName=String[], version=String[], test=String[], pathToTestFMU=String[])

    for (root, dirs, files) in walkdir(fmiCrossCheckFMUDir)
        for dir in dirs
            fmuFiles = searchdir(joinpath(root,dir),r".fmu")
            if (length(fmuFiles) > 0)
                pathToFmu = joinpath(root,first(fmuFiles))

                toolName = basename(dirname(dirname(pathToFmu)))
                version = basename(dirname(pathToFmu))
                test = first(splitext(basename(pathToFmu)))

                push!(df, (toolName, version, test, pathToFmu))
            end
        end
    end


    # Run tests
    @testset "FMI Cross Check" begin
        for toolName in unique(df.toolName)
            @testset "$toolName" begin
                versions = unique(df[df.toolName.==toolName,:].version)
                tests = Array{String}(undef, length(versions), 10)          # ToDo: Replace 10 with maximum number of tests of all versions for current tool
                tests[:,:].=""
                for (index,version) in enumerate(versions)
                    testOfVersion = df[(df.toolName.==toolName) .& (df.version.==version),:].test
                    tests[index,1:length(testOfVersion)] = testOfVersion
                end

                testTool(toolName, versions, tests)
            end;
        end
    end;
end


"""
    searchdir(path,key)

Searches path for expression key and returns found files and folders.
"""
function searchdir(path,key)
    return filter(x->occursin(key,x), readdir(path))
end


"""
    function testTool(toolName::String, versions::Array{String,1}, tests)

Heler function to test for generic tools, versions and test cases.

#Example
```julia
julia> toolName = "CATIA"
julia> versions = ["R2015x", "R2016x"]
julia> tests = ["BooleanNetwork1" "ControlledTemperature" "CoupledClutches" "DFFREG" "" "Rectifier";
                "BooleanNetwork1" "ControlledTemperature" "CoupledClutches" "DFFREG" "MixtureGases" "Rectifier"]
julia> testTool(toolName, versions, tests)
```
"""
function testTool(toolName::String, versions::Array{String,1}, tests)

    for (i,version) in enumerate(versions)
        @testset "$version" begin
            for test in tests[i,:]
                if test != ""
                    @test begin
                        model = joinpath(fmiCrossCheckFMUDir, "$toolName", "$version", "$test", "$test.fmu")
                        main(model)
                    end;
                end
            end
        end;
    end
end
