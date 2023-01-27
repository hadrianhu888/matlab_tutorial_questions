clear;
close all;
clc;
bdclose('all'); % close all models
open_system('test_simulink');
ConfigSet = getActiveConfigSet('test_simulink');
get_param(ConfigSet, 'test_simulink');
set_param(ConfigSet, 'test_simulink', 'on');
SIL_Block_Handle = slbuild('test_simulink', 'SIL', 'on');
print -djpeg SIL_Block_Handle;
save_system('test_simulink');
close_system('test_simulink');
bdroot('all'); % close all models
