#if defined(__cplusplus)
  extern "C" {
#endif
  int BouncingBallFMI20_mayer(DATA* data, modelica_real** res, short*);
  int BouncingBallFMI20_lagrange(DATA* data, modelica_real** res, short *, short *);
  int BouncingBallFMI20_pickUpBoundsForInputsInOptimization(DATA* data, modelica_real* min, modelica_real* max, modelica_real*nominal, modelica_boolean *useNominal, char ** name, modelica_real * start, modelica_real * startTimeOpt);
  int BouncingBallFMI20_setInputData(DATA *data, const modelica_boolean file);
  int BouncingBallFMI20_getTimeGrid(DATA *data, modelica_integer * nsi, modelica_real**t);
#if defined(__cplusplus)
}
#endif