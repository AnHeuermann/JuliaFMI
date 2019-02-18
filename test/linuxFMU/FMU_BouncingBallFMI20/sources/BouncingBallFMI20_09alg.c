/* Algebraic */
#include "BouncingBallFMI20_model.h"

#ifdef __cplusplus
extern "C" {
#endif


/* forwarded equations */
extern void BouncingBallFMI20_eqFunction_8(DATA* data, threadData_t *threadData);
extern void BouncingBallFMI20_eqFunction_12(DATA* data, threadData_t *threadData);

static void functionAlg_system0(DATA *data, threadData_t *threadData)
{
    BouncingBallFMI20_eqFunction_8(data, threadData);

    BouncingBallFMI20_eqFunction_12(data, threadData);
}
/* for continuous time variables */
int BouncingBallFMI20_functionAlgebraics(DATA *data, threadData_t *threadData)
{
  TRACE_PUSH
  
  data->simulationInfo->callStatistics.functionAlgebraics++;
  
  functionAlg_system0(data, threadData);

  BouncingBallFMI20_function_savePreSynchronous(data, threadData);
  
  TRACE_POP
  return 0;
}

#ifdef __cplusplus
}
#endif
