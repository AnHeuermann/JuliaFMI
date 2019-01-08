# ToDo's

Stuff that needs to be done and general development plan:

* Build a working Julia or C function `fmi2Logger` similar to:
```
void *logger(fmi2ComponentEnvironment componentEnvironment,
fmi2String instanceName,
fmi2Status status,
fmi2String category,
fmi2String message, ...){}
```
and put it into struct `fmi2CallbackFunctions`.
* Add wrapper functions for all `fmi2something` functions mentioned in the
[FMI specification](https://svn.modelica.org/fmi/branches/public/specifications/v2.0/FMI_for_ModelExchange_and_CoSimulation_v2.0.pdf) similar to `function
fmi2Instantiate` in [FMIWrapper.jl](https://servant-om.fh-bielefeld.de/gitlab/AnHeuermann/FMU_JL_Simulator/blob/master/src/FMIWrapper.jl).
* Build general simulation routine using our wrapper functions to approximate
solution of ODE / DAE. E.g. by using [DifferentialEquations.jl](https://github.com/JuliaDiffEq/DifferentialEquations.jl).
* Support Unix OS
* Add more support for validating correctness of FMU's. Maybe use [FMI Library](https://jmodelica.org/), but it not supported any more. Build own version of FMI
Library in Julia?
* Build Julia package, e.g. with [Binary Dependency Builder for Julia](https://github.com/JuliaPackaging/BinaryBuilder.jl), and add to [deps/build.jl](https://servant-om.fh-bielefeld.de/gitlab/AnHeuermann/FMU_JL_Simulator/blob/master/deps/build.jl).

## Wish list
Like Christmas, just wish for a lot of stuff you want and be disappointed if
you get nothing.
* Unicorns
* CoSimulation
* FMI 1.0 support
* ...
