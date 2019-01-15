#include <simulation_data.h>

OMC_DISABLE_OPT
void HelloFMI20World_read_input_fmu(MODEL_DATA* modelData, SIMULATION_INFO* simulationInfo)
{
  simulationInfo->startTime = 0.0;
  simulationInfo->stopTime = 1.0;
  simulationInfo->stepSize = 0.002;
  simulationInfo->tolerance = 1e-06;
  simulationInfo->solverMethod = "dassl";
  simulationInfo->outputFormat = "mat";
  simulationInfo->variableFilter = ".*";
  simulationInfo->OPENMODELICAHOME = "/home/andreas/workspace/OpenModelica/build";
  modelData->realVarsData[0].info.id = 1000;
  modelData->realVarsData[0].info.name = "x";
  modelData->realVarsData[0].info.comment = "";
  modelData->realVarsData[0].info.info.filename = "<interactive>";
  modelData->realVarsData[0].info.info.lineStart = 3;
  modelData->realVarsData[0].info.info.colStart = 3;
  modelData->realVarsData[0].info.info.lineEnd = 3;
  modelData->realVarsData[0].info.info.colEnd = 18;
  modelData->realVarsData[0].info.info.readonly = 0;
  modelData->realVarsData[0].attribute.unit = "";
  modelData->realVarsData[0].attribute.displayUnit = "";
  modelData->realVarsData[0].attribute.min = -DBL_MAX;
  modelData->realVarsData[0].attribute.max = DBL_MAX;
  modelData->realVarsData[0].attribute.fixed = 0;
  modelData->realVarsData[0].attribute.useNominal = 0;
  modelData->realVarsData[0].attribute.nominal = 1.0;
  modelData->realVarsData[0].attribute.start = 1.0;
  modelData->realVarsData[1].info.id = 1001;
  modelData->realVarsData[1].info.name = "der(x)";
  modelData->realVarsData[1].info.comment = "";
  modelData->realVarsData[1].info.info.filename = "<interactive>";
  modelData->realVarsData[1].info.info.lineStart = 3;
  modelData->realVarsData[1].info.info.colStart = 3;
  modelData->realVarsData[1].info.info.lineEnd = 3;
  modelData->realVarsData[1].info.info.colEnd = 18;
  modelData->realVarsData[1].info.info.readonly = 0;
  modelData->realVarsData[1].attribute.unit = "";
  modelData->realVarsData[1].attribute.displayUnit = "";
  modelData->realVarsData[1].attribute.min = -DBL_MAX;
  modelData->realVarsData[1].attribute.max = DBL_MAX;
  modelData->realVarsData[1].attribute.fixed = 0;
  modelData->realVarsData[1].attribute.useNominal = 0;
  modelData->realVarsData[1].attribute.nominal = 1.0;
  modelData->realVarsData[1].attribute.start = 0.0;
  modelData->realParameterData[0].info.id = 1002;
  modelData->realParameterData[0].info.name = "a";
  modelData->realParameterData[0].info.comment = "";
  modelData->realParameterData[0].info.info.filename = "<interactive>";
  modelData->realParameterData[0].info.info.lineStart = 4;
  modelData->realParameterData[0].info.info.colStart = 3;
  modelData->realParameterData[0].info.info.lineEnd = 4;
  modelData->realParameterData[0].info.info.colEnd = 21;
  modelData->realParameterData[0].info.info.readonly = 0;
  modelData->realParameterData[0].attribute.unit = "";
  modelData->realParameterData[0].attribute.displayUnit = "";
  modelData->realParameterData[0].attribute.min = -DBL_MAX;
  modelData->realParameterData[0].attribute.max = DBL_MAX;
  modelData->realParameterData[0].attribute.fixed = 1;
  modelData->realParameterData[0].attribute.useNominal = 0;
  modelData->realParameterData[0].attribute.nominal = 1.0;
  modelData->realParameterData[0].attribute.start = 2.0;
}