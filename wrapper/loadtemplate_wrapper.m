function project=loadtemplate_wrapper(project,TaskIndex,MethodIndex,varargin)
% loadtemplate_wrapper function load a saved template into the pipeline program.
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
%SW version: 250503TD, 170303TD, T. Dyrby, 130303, NRU
%

project=feval(project.pipeline.taskSetup{TaskIndex,MethodIndex}.function_name,project,TaskIndex,MethodIndex,'loadtemplate');
