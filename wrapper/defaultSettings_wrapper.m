function project=defaultSettings_wrapper(project,TaskIndex,MethodIndex,varargin)
% defaultSettings_wrapper function load default methods into the pipeline program.
%
% Input:
%   project     : Structure containing all information of actual pipeline
%   TaskIndex   : Index to active task in the project structure
%   MethodIndex : Index to used method in a TaskIndex in the project structure
%   varargin    : Abitrary number of input arguments. (NOT USED)
%
% Output:
%   project     : Return updated project       
%
% Uses special functions:
%
%____________________________________________
%SW version: 250603TD, NRU
%
project=feval(project.pipeline.taskSetup{TaskIndex,MethodIndex}.function_name,project,TaskIndex,MethodIndex,'defaultSettings');
