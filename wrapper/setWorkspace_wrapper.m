function project=setWorkspace_wrapper(project,TaskIndex,MethodIndex,varargin)
% setWorkspace_wrapper function selects a 'main'workspace for new projects where
%   projectfiles and 'work' files are saved as a subdirectory
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
%SW version: 180803TD, T. Dyrby, NRU
%

h_menueWrkSpc=findobj('tag',['tag_',project.pipeline.taskSetup{TaskIndex,MethodIndex}.function_wrapper]);
%___Check if project has started
taskSum=0;    
for i=1:(length(project.pipeline.statusTask)-2)
    taskSum=taskSum+project.pipeline.statusTask(i);
end

if(taskSum~=0 & ~(project.pipeline.statusTask(1)==3))
    set(h_menueWrkSpc,'Enable','off')
    %LogInfo
    msg=sprintf('Project has already been started in: ''%s''',project.sysinfo.mainworkspace)
    project=logProject(msg,project,TaskIndex,MethodIndex);
else    
    %___ Select a workspace
    wrkSpcPath=uigetdir(project.sysinfo.mainworkspace,'Select new workspace...');
    
    if(wrkSpcPath==0)
        msg=sprintf('No new mainWorkspace selected');
    else    
        project.sysinfo.mainworkspace=wrkSpcPath; %Add mark to new path (removed in checkOut)         
        %LogInfo
        msg=sprintf('New mainWorkspace selected:''%s''',project.sysinfo.mainworkspace);
    end
    project=logProject(msg,project,TaskIndex,MethodIndex);
end
