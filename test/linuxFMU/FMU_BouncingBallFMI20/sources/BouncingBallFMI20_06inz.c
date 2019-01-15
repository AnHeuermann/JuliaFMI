/* Initialization */
#include "BouncingBallFMI20_model.h"
#include "BouncingBallFMI20_11mix.h"
#include "BouncingBallFMI20_12jac.h"
#if defined(__cplusplus)
extern "C" {
#endif

void BouncingBallFMI20_functionInitialEquations_0(DATA *data, threadData_t *threadData);
extern void BouncingBallFMI20_eqFunction_11(DATA *data, threadData_t *threadData);


/*
 equation index: 2
 type: SIMPLE_ASSIGN
 v = $START.v
 */
void BouncingBallFMI20_eqFunction_2(DATA *data, threadData_t *threadData)
{
  TRACE_PUSH
  const int equationIndexes[2] = {1,2};
  data->localData[0]->realVars[1] /* v STATE(1) */ = data->modelData->realVarsData[1].attribute /* v STATE(1) */.start;
  TRACE_POP
}
extern void BouncingBallFMI20_eqFunction_10(DATA *data, threadData_t *threadData);


/*
 equation index: 4
 type: SIMPLE_ASSIGN
 h = $START.h
 */
void BouncingBallFMI20_eqFunction_4(DATA *data, threadData_t *threadData)
{
  TRACE_PUSH
  const int equationIndexes[2] = {1,4};
  data->localData[0]->realVars[0] /* h STATE(1,v) */ = data->modelData->realVarsData[0].attribute /* h STATE(1,v) */.start;
  TRACE_POP
}
extern void BouncingBallFMI20_eqFunction_8(DATA *data, threadData_t *threadData);


/*
 equation index: 6
 type: SIMPLE_ASSIGN
 $PRE._v_new = $START.v_new
 */
void BouncingBallFMI20_eqFunction_6(DATA *data, threadData_t *threadData)
{
  TRACE_PUSH
  const int equationIndexes[2] = {1,6};
  data->simulationInfo->realVarsPre[4] /* v_new DISCRETE */ = data->modelData->realVarsData[4].attribute /* v_new DISCRETE */.start;
  TRACE_POP
}

/*
 equation index: 7
 type: SIMPLE_ASSIGN
 v_new = $PRE.v_new
 */
void BouncingBallFMI20_eqFunction_7(DATA *data, threadData_t *threadData)
{
  TRACE_PUSH
  const int equationIndexes[2] = {1,7};
  data->localData[0]->realVars[4] /* v_new DISCRETE */ = data->simulationInfo->realVarsPre[4] /* v_new DISCRETE */;
  TRACE_POP
}
OMC_DISABLE_OPT
void BouncingBallFMI20_functionInitialEquations_0(DATA *data, threadData_t *threadData)
{
  TRACE_PUSH
  BouncingBallFMI20_eqFunction_11(data, threadData);
  BouncingBallFMI20_eqFunction_2(data, threadData);
  BouncingBallFMI20_eqFunction_10(data, threadData);
  BouncingBallFMI20_eqFunction_4(data, threadData);
  BouncingBallFMI20_eqFunction_8(data, threadData);
  BouncingBallFMI20_eqFunction_6(data, threadData);
  BouncingBallFMI20_eqFunction_7(data, threadData);
  TRACE_POP
}


int BouncingBallFMI20_functionInitialEquations(DATA *data, threadData_t *threadData)
{
  TRACE_PUSH

  data->simulationInfo->discreteCall = 1;
  BouncingBallFMI20_functionInitialEquations_0(data, threadData);
  data->simulationInfo->discreteCall = 0;
  
  TRACE_POP
  return 0;
}


int BouncingBallFMI20_functionInitialEquations_lambda0(DATA *data, threadData_t *threadData)
{
  TRACE_PUSH

  data->simulationInfo->discreteCall = 1;
  data->simulationInfo->discreteCall = 0;
  
  TRACE_POP
  return 0;
}
int BouncingBallFMI20_functionRemovedInitialEquations(DATA *data, threadData_t *threadData)
{
  TRACE_PUSH
  const int *equationIndexes = NULL;
  double res = 0.0;

  
  TRACE_POP
  return 0;
}


#if defined(__cplusplus)
}
#endif

