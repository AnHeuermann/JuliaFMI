/* External objects file */
#include "HelloFMI20World_model.h"
#if defined(__cplusplus)
extern "C" {
#endif

void HelloFMI20World_callExternalObjectDestructors(DATA *data, threadData_t *threadData)
{
  if(data->simulationInfo->extObjs)
  {
    free(data->simulationInfo->extObjs);
    data->simulationInfo->extObjs = 0;
  }
}
#if defined(__cplusplus)
}
#endif

