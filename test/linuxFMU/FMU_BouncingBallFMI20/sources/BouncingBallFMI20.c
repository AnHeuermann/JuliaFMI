/* Main Simulation File */

#if defined(__cplusplus)
extern "C" {
#endif

#include "BouncingBallFMI20_model.h"
#include "simulation/solver/events.h"


/* dummy VARINFO and FILEINFO */
const FILE_INFO dummyFILE_INFO = omc_dummyFileInfo;
const VAR_INFO dummyVAR_INFO = omc_dummyVarInfo;

int BouncingBallFMI20_input_function(DATA *data, threadData_t *threadData)
{
  TRACE_PUSH

  
  TRACE_POP
  return 0;
}

int BouncingBallFMI20_input_function_init(DATA *data, threadData_t *threadData)
{
  TRACE_PUSH

  
  TRACE_POP
  return 0;
}

int BouncingBallFMI20_input_function_updateStartValues(DATA *data, threadData_t *threadData)
{
  TRACE_PUSH

  
  TRACE_POP
  return 0;
}

int BouncingBallFMI20_inputNames(DATA *data, char ** names){
  TRACE_PUSH

  
  TRACE_POP
  return 0;
}

int BouncingBallFMI20_output_function(DATA *data, threadData_t *threadData)
{
  TRACE_PUSH

  
  TRACE_POP
  return 0;
}


/*
 equation index: 8
 type: SIMPLE_ASSIGN
 $whenCondition1 = h <= 0.0
 */
void BouncingBallFMI20_eqFunction_8(DATA *data, threadData_t *threadData)
{
  TRACE_PUSH
  const int equationIndexes[2] = {1,8};
  modelica_boolean tmp0;
  RELATIONHYSTERESIS(tmp0, data->localData[0]->realVars[0] /* h STATE(1,v) */, 0.0, 0, LessEq);
  data->localData[0]->booleanVars[0] /* $whenCondition1 DISCRETE */ = tmp0;
  TRACE_POP
}
/*
 equation index: 9
 type: WHEN
 
 when {$whenCondition1} then
   v_new = (-e) * pre(v);
 end when;
 */
void BouncingBallFMI20_eqFunction_9(DATA *data, threadData_t *threadData)
{
  TRACE_PUSH
  const int equationIndexes[2] = {1,9};
  if((data->localData[0]->booleanVars[0] /* $whenCondition1 DISCRETE */ && !data->simulationInfo->booleanVarsPre[0] /* $whenCondition1 DISCRETE */ /* edge */))
  {
    data->localData[0]->realVars[4] /* v_new DISCRETE */ = ((-data->simulationInfo->realParameter[0])) * (data->simulationInfo->realVarsPre[1] /* v STATE(1) */);
  }
  TRACE_POP
}
/*
 equation index: 10
 type: SIMPLE_ASSIGN
 der(h) = v
 */
void BouncingBallFMI20_eqFunction_10(DATA *data, threadData_t *threadData)
{
  TRACE_PUSH
  const int equationIndexes[2] = {1,10};
  data->localData[0]->realVars[2] /* der(h) STATE_DER */ = data->localData[0]->realVars[1] /* v STATE(1) */;
  TRACE_POP
}
/*
 equation index: 11
 type: SIMPLE_ASSIGN
 der(v) = -g
 */
void BouncingBallFMI20_eqFunction_11(DATA *data, threadData_t *threadData)
{
  TRACE_PUSH
  const int equationIndexes[2] = {1,11};
  data->localData[0]->realVars[3] /* der(v) STATE_DER */ = (-data->simulationInfo->realParameter[1]);
  TRACE_POP
}
/*
 equation index: 12
 type: WHEN
 
 when {$whenCondition1} then
   reinit(v,  v_new);
 end when;
 */
void BouncingBallFMI20_eqFunction_12(DATA *data, threadData_t *threadData)
{
  TRACE_PUSH
  const int equationIndexes[2] = {1,12};
  if((data->localData[0]->booleanVars[0] /* $whenCondition1 DISCRETE */ && !data->simulationInfo->booleanVarsPre[0] /* $whenCondition1 DISCRETE */ /* edge */))
  {
    data->localData[0]->realVars[1] /* v STATE(1) */ = data->localData[0]->realVars[4] /* v_new DISCRETE */;
    infoStreamPrint(LOG_EVENTS, 0, "reinit v = %g", data->localData[0]->realVars[1] /* v STATE(1) */);
    data->simulationInfo->needToIterate = 1;
  }
  TRACE_POP
}

OMC_DISABLE_OPT
int BouncingBallFMI20_functionDAE(DATA *data, threadData_t *threadData)
{
  TRACE_PUSH
  int equationIndexes[1] = {0};
  
  data->simulationInfo->needToIterate = 0;
  data->simulationInfo->discreteCall = 1;
  BouncingBallFMI20_functionLocalKnownVars(data, threadData);
  BouncingBallFMI20_eqFunction_8(data, threadData);

  BouncingBallFMI20_eqFunction_9(data, threadData);

  BouncingBallFMI20_eqFunction_10(data, threadData);

  BouncingBallFMI20_eqFunction_11(data, threadData);

  BouncingBallFMI20_eqFunction_12(data, threadData);
  data->simulationInfo->discreteCall = 0;
  
  TRACE_POP
  return 0;
}


int BouncingBallFMI20_functionLocalKnownVars(DATA *data, threadData_t *threadData)
{
  TRACE_PUSH

  
  TRACE_POP
  return 0;
}


/* forwarded equations */
extern void BouncingBallFMI20_eqFunction_10(DATA* data, threadData_t *threadData);
extern void BouncingBallFMI20_eqFunction_11(DATA* data, threadData_t *threadData);

static void functionODE_system0(DATA *data, threadData_t *threadData)
{
    BouncingBallFMI20_eqFunction_10(data, threadData);

    BouncingBallFMI20_eqFunction_11(data, threadData);
}

int BouncingBallFMI20_functionODE(DATA *data, threadData_t *threadData)
{
  TRACE_PUSH

  
  data->simulationInfo->callStatistics.functionODE++;
  
  BouncingBallFMI20_functionLocalKnownVars(data, threadData);
  functionODE_system0(data, threadData);

  
  TRACE_POP
  return 0;
}

/* forward the main in the simulation runtime */
extern int _main_SimulationRuntime(int argc, char**argv, DATA *data, threadData_t *threadData);

#include "BouncingBallFMI20_12jac.h"
#include "BouncingBallFMI20_13opt.h"

struct OpenModelicaGeneratedFunctionCallbacks BouncingBallFMI20_callback = {
   NULL,
   NULL,
   NULL,
   BouncingBallFMI20_callExternalObjectDestructors,
   NULL,
   NULL,
   NULL,
   #if !defined(OMC_NO_STATESELECTION)
   BouncingBallFMI20_initializeStateSets,
   #else
   NULL,
   #endif
   BouncingBallFMI20_initializeDAEmodeData,
   BouncingBallFMI20_functionODE,
   BouncingBallFMI20_functionAlgebraics,
   BouncingBallFMI20_functionDAE,
   BouncingBallFMI20_functionLocalKnownVars,
   BouncingBallFMI20_input_function,
   BouncingBallFMI20_input_function_init,
   BouncingBallFMI20_input_function_updateStartValues,
   BouncingBallFMI20_output_function,
   BouncingBallFMI20_function_storeDelayed,
   BouncingBallFMI20_updateBoundVariableAttributes,
   BouncingBallFMI20_functionInitialEquations,
   1, /* useHomotopy - 0: local homotopy (equidistant lambda), 1: global homotopy (equidistant lambda), 2: new global homotopy approach (adaptive lambda), 3: new local homotopy approach (adaptive lambda)*/
   BouncingBallFMI20_functionInitialEquations_lambda0,
   BouncingBallFMI20_functionRemovedInitialEquations,
   BouncingBallFMI20_updateBoundParameters,
   BouncingBallFMI20_checkForAsserts,
   BouncingBallFMI20_function_ZeroCrossingsEquations,
   BouncingBallFMI20_function_ZeroCrossings,
   BouncingBallFMI20_function_updateRelations,
   BouncingBallFMI20_zeroCrossingDescription,
   BouncingBallFMI20_relationDescription,
   BouncingBallFMI20_function_initSample,
   BouncingBallFMI20_INDEX_JAC_A,
   BouncingBallFMI20_INDEX_JAC_B,
   BouncingBallFMI20_INDEX_JAC_C,
   BouncingBallFMI20_INDEX_JAC_D,
   BouncingBallFMI20_initialAnalyticJacobianA,
   BouncingBallFMI20_initialAnalyticJacobianB,
   BouncingBallFMI20_initialAnalyticJacobianC,
   BouncingBallFMI20_initialAnalyticJacobianD,
   BouncingBallFMI20_functionJacA_column,
   BouncingBallFMI20_functionJacB_column,
   BouncingBallFMI20_functionJacC_column,
   BouncingBallFMI20_functionJacD_column,
   BouncingBallFMI20_linear_model_frame,
   BouncingBallFMI20_linear_model_datarecovery_frame,
   BouncingBallFMI20_mayer,
   BouncingBallFMI20_lagrange,
   BouncingBallFMI20_pickUpBoundsForInputsInOptimization,
   BouncingBallFMI20_setInputData,
   BouncingBallFMI20_getTimeGrid,
   BouncingBallFMI20_symbolicInlineSystem,
   BouncingBallFMI20_function_initSynchronous,
   BouncingBallFMI20_function_updateSynchronous,
   BouncingBallFMI20_function_equationsSynchronous,
   BouncingBallFMI20_inputNames,
   BouncingBallFMI20_read_input_fmu,
   NULL,
   NULL,
   -1

};

#define _OMC_LIT_RESOURCE_0_name_data "BouncingBallFMI20"
#define _OMC_LIT_RESOURCE_0_dir_data "."
static const MMC_DEFSTRINGLIT(_OMC_LIT_RESOURCE_0_name,17,_OMC_LIT_RESOURCE_0_name_data);
static const MMC_DEFSTRINGLIT(_OMC_LIT_RESOURCE_0_dir,1,_OMC_LIT_RESOURCE_0_dir_data);

static const MMC_DEFSTRUCTLIT(_OMC_LIT_RESOURCES,2,MMC_ARRAY_TAG) {MMC_REFSTRINGLIT(_OMC_LIT_RESOURCE_0_name), MMC_REFSTRINGLIT(_OMC_LIT_RESOURCE_0_dir)}};
void BouncingBallFMI20_setupDataStruc(DATA *data, threadData_t *threadData)
{
  assertStreamPrint(threadData,0!=data, "Error while initialize Data");
  threadData->localRoots[LOCAL_ROOT_SIMULATION_DATA] = data;
  data->callback = &BouncingBallFMI20_callback;
  OpenModelica_updateUriMapping(threadData, MMC_REFSTRUCTLIT(_OMC_LIT_RESOURCES));
  data->modelData->modelName = "BouncingBallFMI20";
  data->modelData->modelFilePrefix = "BouncingBallFMI20";
  data->modelData->resultFileName = NULL;
  data->modelData->modelDir = "";
  data->modelData->modelGUID = "{83e3623b-dae7-4f68-a9b6-11318b1e264c}";
  data->modelData->initXMLData = NULL;
  data->modelData->modelDataXml.infoXMLData = NULL;
  
  data->modelData->nStates = 2;
  data->modelData->nVariablesReal = 5;
  data->modelData->nDiscreteReal = 1;
  data->modelData->nVariablesInteger = 0;
  data->modelData->nVariablesBoolean = 1;
  data->modelData->nVariablesString = 0;
  data->modelData->nParametersReal = 2;
  data->modelData->nParametersInteger = 0;
  data->modelData->nParametersBoolean = 0;
  data->modelData->nParametersString = 0;
  data->modelData->nInputVars = 0;
  data->modelData->nOutputVars = 0;
  
  data->modelData->nAliasReal = 0;
  data->modelData->nAliasInteger = 0;
  data->modelData->nAliasBoolean = 0;
  data->modelData->nAliasString = 0;
  
  data->modelData->nZeroCrossings = 1;
  data->modelData->nSamples = 0;
  data->modelData->nRelations = 1;
  data->modelData->nMathEvents = 0;
  data->modelData->nExtObjs = 0;
  GC_asprintf(&data->modelData->modelDataXml.fileName, "%s/BouncingBallFMI20_info.json", data->modelData->resourcesDir);
  data->modelData->modelDataXml.modelInfoXmlLength = 0;
  data->modelData->modelDataXml.nFunctions = 0;
  data->modelData->modelDataXml.nProfileBlocks = 0;
  data->modelData->modelDataXml.nEquations = 13;
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

