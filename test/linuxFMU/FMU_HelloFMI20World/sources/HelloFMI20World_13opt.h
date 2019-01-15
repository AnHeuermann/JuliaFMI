#if defined(__cplusplus)
  extern "C" {
#endif
  int HelloFMI20World_mayer(DATA* data, modelica_real** res, short*);
  int HelloFMI20World_lagrange(DATA* data, modelica_real** res, short *, short *);
  int HelloFMI20World_pickUpBoundsForInputsInOptimization(DATA* data, modelica_real* min, modelica_real* max, modelica_real*nominal, modelica_boolean *useNominal, char ** name, modelica_real * start, modelica_real * startTimeOpt);
  int HelloFMI20World_setInputData(DATA *data, const modelica_boolean file);
  int HelloFMI20World_getTimeGrid(DATA *data, modelica_integer * nsi, modelica_real**t);
#if defined(__cplusplus)
}
#endif