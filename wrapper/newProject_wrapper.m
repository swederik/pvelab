function project=newProject_wrapper(project,TaskIndex,MethodIndex,varargin)
% newProject_wrapper function creates a new project in the pipeline program.
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

project=feval(project.pipeline.taskSetup{TaskIndex,MethodIndex}.function_name,project,TaskIndex,MethodIndex,'new');
