function project=loadSeg_nogui(project,TaskIndex,MethodIndex,varargin)
% This method is called by the pipeline program. 
% It loads three segmented files into the project structure.
% It checks if the loaded files are the same size and dimension as the
% loaded MR-image (a requirement).
%
% By Thomas Rask 140104, NRU
%

ImageIndex=1;

%_____Make changes to project

%Check if headers are alright
project.taskDone{TaskIndex}.userdata.segout{ImageIndex,1}.info='Segmented Gray Matter';
project.taskDone{TaskIndex}.userdata.segout{ImageIndex,2}.info='Segmented White Matter';
project.taskDone{TaskIndex}.userdata.segout{ImageIndex,3}.info='Segmented CSF';
