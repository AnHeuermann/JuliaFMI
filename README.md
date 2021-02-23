# JuliaFMI

[![Coverage Status](https://coveralls.io/repos/github/AnHeuermann/JuliaFMI/badge.svg)](https://coveralls.io/github/AnHeuermann/JuliaFMI)

Julia simulator for [Functional Mockup Interface (FMI)](https://fmi-standard.org/)

## Getting started

### Installing JuliaFMI
```julia
julia> import Pkg
julia> Pkg.clone("https://github.com/AnHeuermann/JuliaFMI.git")
```
You can force rebuilding with
```julia
(v1.2) pkg> build JuliaFMI
```

### Run the tests
```julia
(v1.2) pkg> test JuliaFMI
```
Note: Cloning all tests from [modelica/fmi-cross-check][https://github.com/modelica/fmi-cross-check] needs a lot of time.

## FMI
Functional Mock-up Interface (FMI) is a tool independent standard to support
both model exchange and co-simulation of dynamic models using a combination of
xml-files and compiled C-code.

Functional Mockup Unit's, FMU's for short, can be ex- and imported by
[various tools](https://fmi-standard.org/tools/). This package should be the
first FMUSimulator in Julia an be an easy tool to simulate and validate FMU's
for ModelExchange 2.0.

For more informations see the [documentation](https://svn.modelica.org/fmi/branches/public/specifications/v2.0/FMI_for_ModelExchange_and_CoSimulation_v2.0.pdf).

## Features
At the moment the following features are implemented:
* Import of FMU's
* Simulation of first ModelExchange 2.0 FMUs without event handling

## Planed features
* Basic check of correctness of imported FMU's
* Simulation with changeable explicit and implicit ODE and DAE integrators
* Export of simulation results as CVS and MAT files

## Documentation
Missing as well :-)<br>
There are some Julia doc strings for most functions though...


## Known issues
* `fmi2FreeInstance` is not working for provided FMUs in test directory.
