# JuliaFMI

[![Build Status](https://travis-ci.com/AnHeuermann/JuliaFMI.svg?branch=master)](https://travis-ci.com/AnHeuermann/JuliaFMI)

Julia simulator for [Functional Mockup Interface (FMI)](https://fmi-standard.org/)

## Getting started

### Installing JuliaFMI


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
* Wreak havoc
* Segmentation faults
* Import of FMU's

## Planed features
* Basic check of correctness for imported FMU's
* Import of FMU's
* Simulation with changeable explicit and implicit ODE and DAE integrators
* Export of simulation results as CVS and MAT files

## Documentation
Missing as well :-)


## Known issues
It's buggy as hell.
