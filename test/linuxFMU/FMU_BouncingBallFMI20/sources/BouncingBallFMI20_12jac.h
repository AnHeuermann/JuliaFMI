/* Jacobians */
static const REAL_ATTRIBUTE dummyREAL_ATTRIBUTE = omc_dummyRealAttribute;
/* Jacobian Variables */
#if defined(__cplusplus)
extern "C" {
#endif
  #define BouncingBallFMI20_INDEX_JAC_D 0
  int BouncingBallFMI20_functionJacD_column(void* data, threadData_t *threadData);
  int BouncingBallFMI20_initialAnalyticJacobianD(void* data, threadData_t *threadData);
#if defined(__cplusplus)
}
#endif
/* D */

#if defined(__cplusplus)
extern "C" {
#endif
  #define BouncingBallFMI20_INDEX_JAC_C 1
  int BouncingBallFMI20_functionJacC_column(void* data, threadData_t *threadData);
  int BouncingBallFMI20_initialAnalyticJacobianC(void* data, threadData_t *threadData);
#if defined(__cplusplus)
}
#endif
/* C */

#if defined(__cplusplus)
extern "C" {
#endif
  #define BouncingBallFMI20_INDEX_JAC_B 2
  int BouncingBallFMI20_functionJacB_column(void* data, threadData_t *threadData);
  int BouncingBallFMI20_initialAnalyticJacobianB(void* data, threadData_t *threadData);
#if defined(__cplusplus)
}
#endif
/* B */

#if defined(__cplusplus)
extern "C" {
#endif
  #define BouncingBallFMI20_INDEX_JAC_A 3
  int BouncingBallFMI20_functionJacA_column(void* data, threadData_t *threadData);
  int BouncingBallFMI20_initialAnalyticJacobianA(void* data, threadData_t *threadData);
#if defined(__cplusplus)
}
#endif
/* A */
/* $Ph$PSeedA */
#define _$Ph$PSeedA(i) data->simulationInfo->analyticJacobians[3].seedVars[0]
#define $Ph$PSeedA _$Ph$PSeedA(0)

/* $Pv$PSeedA */
#define _$Pv$PSeedA(i) data->simulationInfo->analyticJacobians[3].seedVars[1]
#define $Pv$PSeedA _$Pv$PSeedA(0)


