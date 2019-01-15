/* Main Simulation File */

#if defined(__cplusplus)
extern "C" {
#endif

#include "HelloFMI20World_model.h"
#include "simulation/solver/events.h"


/* dummy VARINFO and FILEINFO */
const FILE_INFO dummyFILE_INFO = omc_dummyFileInfo;
const VAR_INFO dummyVAR_INFO = omc_dummyVarInfo;

int HelloFMI20World_input_function(DATA *data, threadData_t *threadData)
{
  TRACE_PUSH

  
  TRACE_POP
  return 0;
}

int HelloFMI20World_input_function_init(DATA *data, threadData_t *threadData)
{
  TRACE_PUSH

  
  TRACE_POP
  return 0;
}

int HelloFMI20World_input_function_updateStartValues(DATA *data, threadData_t *threadData)
{
  TRACE_PUSH

  
  TRACE_POP
  return 0;
}

int HelloFMI20World_inputNames(DATA *data, char ** names){
  TRACE_PUSH

  
  TRACE_POP
  return 0;
}

int HelloFMI20World_output_function(DATA *data, threadData_t *threadData)
{
  TRACE_PUSH

  
  TRACE_POP
  return 0;
}


/*
 equation index: 3
 type: SIMPLE_ASSIGN
 der(x) = a * x
 */
void HelloFMI20World_eqFunction_3(DATA *data, threadData_t *threadData)
{
  TRACE_PUSH
  const int equationIndexes[2] = {1,3};
  data->localData[0]->realVars[1] /* der(x) STATE_DER */ = (data->simulationInfo->realParameter[0]) * (data->localData[0]->realVars[0] /* x STATE(1) */);
  TRACE_POP
}

OMC_DISABLE_OPT
int HelloFMI20World_functionDAE(DATA *data, threadData_t *threadData)
{
  TRACE_PUSH
  int equationIndexes[1] = {0};
  
  data->simulationInfo->needToIterate = 0;
  data->simulationInfo->discreteCall = 1;
  HelloFMI20World_functionLocalKnownVars(data, threadData);
  HelloFMI20World_eqFunction_3(data, threadData);
  data->simulationInfo->discreteCall = 0;
  
  TRACE_POP
  return 0;
}


int HelloFMI20World_functionLocalKnownVars(DATA *data, threadData_t *threadData)
{
  TRACE_PUSH

  
  TRACE_POP
  return 0;
}


/* forwarded equations */
extern void HelloFMI20World_eqFunction_3(DATA* data, threadData_t *threadData);

static void functionODE_system0(DATA *data, threadData_t *threadData)
{
    HelloFMI20World_eqFunction_3(data, threadData);
}

int HelloFMI20World_functionODE(DATA *data, threadData_t *threadData)
{
  TRACE_PUSH

  
  data->simulationInfo->callStatistics.functionODE++;
  
  HelloFMI20World_functionLocalKnownVars(data, threadData);
  functionODE_system0(data, threadData);

  
  TRACE_POP
  return 0;
}

/* forward the main in the simulation runtime */
extern int _main_SimulationRuntime(int argc, char**argv, DATA *data, threadData_t *threadData);

#include "HelloFMI20World_12jac.h"
#include "HelloFMI20World_13opt.h"

struct OpenModelicaGeneratedFunctionCallbacks HelloFMI20World_callback = {
   NULL,
   NULL,
   NULL,
   HelloFMI20World_callExternalObjectDestructors,
   NULL,
   NULL,
   NULL,
   #if !defined(OMC_NO_STATESELECTION)
   HelloFMI20World_initializeStateSets,
   #else
   NULL,
   #endif
   HelloFMI20World_initializeDAEmodeData,
   HelloFMI20World_functionODE,
   HelloFMI20World_functionAlgebraics,
   HelloFMI20World_functionDAE,
   HelloFMI20World_functionLocalKnownVars,
   HelloFMI20World_input_function,
   HelloFMI20World_input_function_init,
   HelloFMI20World_input_function_updateStartValues,
   HelloFMI20World_output_function,
   HelloFMI20World_function_storeDelayed,
   HelloFMI20World_updateBoundVariableAttributes,
   HelloFMI20World_functionInitialEquations,
   1, /* useHomotopy - 0: local homotopy (equidistant lambda), 1: global homotopy (equidistant lambda), 2: new global homotopy approach (adaptive lambda), 3: new local homotopy approach (adaptive lambda)*/
   HelloFMI20World_functionInitialEquations_lambda0,
   HelloFMI20World_functionRemovedInitialEquations,
   HelloFMI20World_updateBoundParameters,
   HelloFMI20World_checkForAsserts,
   HelloFMI20World_function_ZeroCrossingsEquations,
   HelloFMI20World_function_ZeroCrossings,
   HelloFMI20World_function_updateRelations,
   HelloFMI20World_zeroCrossingDescription,
   HelloFMI20World_relationDescription,
   HelloFMI20World_function_initSample,
   HelloFMI20World_INDEX_JAC_A,
   HelloFMI20World_INDEX_JAC_B,
   HelloFMI20World_INDEX_JAC_C,
   HelloFMI20World_INDEX_JAC_D,
   HelloFMI20World_initialAnalyticJacobianA,
   HelloFMI20World_initialAnalyticJacobianB,
   HelloFMI20World_initialAnalyticJacobianC,
   HelloFMI20World_initialAnalyticJacobianD,
   HelloFMI20World_functionJacA_column,
   HelloFMI20World_functionJacB_column,
   HelloFMI20World_functionJacC_column,
   HelloFMI20World_functionJacD_column,
   HelloFMI20World_linear_model_frame,
   HelloFMI20World_linear_model_datarecovery_frame,
   HelloFMI20World_mayer,
   HelloFMI20World_lagrange,
   HelloFMI20World_pickUpBoundsForInputsInOptimization,
   HelloFMI20World_setInputData,
   HelloFMI20World_getTimeGrid,
   HelloFMI20World_symbolicInlineSystem,
   HelloFMI20World_function_initSynchronous,
   HelloFMI20World_function_updateSynchronous,
   HelloFMI20World_function_equationsSynchronous,
   HelloFMI20World_inputNames,
   HelloFMI20World_read_input_fmu,
   NULL,
   NULL,
   -1

};

#define _OMC_LIT_RESOURCE_0_name_data "HelloFMI20World"
#define _OMC_LIT_RESOURCE_0_dir_data "."
static const MMC_DEFSTRINGLIT(_OMC_LIT_RESOURCE_0_name,15,_OMC_LIT_RESOURCE_0_name_data);
static const MMC_DEFSTRINGLIT(_OMC_LIT_RESOURCE_0_dir,1,_OMC_LIT_RESOURCE_0_dir_data);

static const MMC_DEFSTRUCTLIT(_OMC_LIT_RESOURCES,2,MMC_ARRAY_TAG) {MMC_REFSTRINGLIT(_OMC_LIT_RESOURCE_0_name), MMC_REFSTRINGLIT(_OMC_LIT_RESOURCE_0_dir)}};
void HelloFMI20World_setupDataStruc(DATA *data, threadData_t *threadData)
{
  assertStreamPrint(threadData,0!=data, "Error while initialize Data");
  threadData->localRoots[LOCAL_ROOT_SIMULATION_DATA] = data;
  data->callback = &HelloFMI20World_callback;
  OpenModelica_updateUriMapping(threadData, MMC_REFSTRUCTLIT(_OMC_LIT_RESOURCES));
  data->modelData->modelName = "HelloFMI20World";
  data->modelData->modelFilePrefix = "HelloFMI20World";
  data->modelData->resultFileName = NULL;
  data->modelData->modelDir = "";
  data->modelData->modelGUID = "{f7d1f815-44cb-4aac-88bc-2fcbf3078152}";
  data->modelData->initXMLData = NULL;
  data->modelData->modelDataXml.infoXMLData = NULL;
  
  data->modelData->nStates = 1;
  data->modelData->nVariablesReal = 2;
  data->modelData->nDiscreteReal = 0;
  data->modelData->nVariablesInteger = 0;
  data->modelData->nVariablesBoolean = 0;
  data->modelData->nVariablesString = 0;
  data->modelData->nParametersReal = 1;
  data->modelData->nParametersInteger = 0;
  data->modelData->nParametersBoolean = 0;
  data->modelData->nParametersString = 0;
  data->modelData->nInputVars = 0;
  data->modelData->nOutputVars = 0;
  
  data->modelData->nAliasReal = 0;
  data->modelData->nAliasInteger = 0;
  data->modelData->nAliasBoolean = 0;
  data->modelData->nAliasString = 0;
  
  data->modelData->nZeroCrossings = 0;
  data->modelData->nSamples = 0;
  data->modelData->nRelations = 0;
  data->modelData->nMathEvents = 0;
  data->modelData->nExtObjs = 0;
  GC_asprintf(&data->modelData->modelDataXml.fileName, "%s/HelloFMI20World_info.json", data->modelData->resourcesDir);
  data->modelData->modelDataXml.modelInfoXmlLength = 0;
  data->modelData->modelDataXml.nFunctions = 0;
  data->modelData->modelDataXml.nProfileBlocks = 0;
  data->modelData->modelDataXml.nEquations = 4;
  data->modelData->nMixedSystems = 0;
  data->modelData->nLinearSystems = 0;
  data->modelData->nNonLinearSystems = 0;
  data->modelData->nStateSets = 0;
  data->modelData->nJacobians = 4;
  data->modelData->nOptimizeConstraints = 0;
  data->modelData->nOptimizeFinalConstraints = 0;
  
  data->modelData->nDelayExpressions = 0;
  
  data->modelData->nClocks = 0;
  data->modelData->nSubClocks = 0;
  
  data->modelData->nSensitivityVars = 0;
  data->modelData->nSensitivityParamVars = 0;
}

static int rml_execution_failed()
{
  fflush(NULL);
  fprintf(stderr, "Execution failed!\n");
  fflush(NULL);
  return 1;
}

