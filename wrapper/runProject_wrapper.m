function varargout=runProject_wrapper(project,TaskIndex,MethodIndex,varargin)
% runProject function starts a new or continue a pipeline process w. selected 
%   methods given in 'project.pipeline.userPipeline(TaskIndex)' and erase 
%   existing pipeline if a new process is started. The GUI is updated if 
%   it exist within then the pipeline program.
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
% ____________________________________________
% T. Dyrby, 200603, NRU
%SW version: 200603TD

command=project.taskDone{TaskIndex}.command;
%Search for method in project
[NoTask,NoMethods]=size(project.pipeline.taskSetup);
for(iTaskIndex=1:NoTask-1)
    
    %____ Continue a project
    if(strcmp(lower(command),'continue'))  
        if(project.pipeline.statusTask(iTaskIndex)==2)
            continue
        end
    end
    
    if(~strcmp(lower(project.pipeline.taskSetup{iTaskIndex,1}.task),'others'));
        if(~isempty(project.handles.h_mainfig))
            drawGUI(project.handles.h_mainfig,iTaskIndex);
            taskGUI(project.handles.h_mainfig,iTaskIndex);
            %___ Disable buttons 
            set(findobj('tag','task'),'Enable','off');
            set(findobj('tag','method'),'Enable','off');
            set(findobj('tag','options'),'Enable','off');       
            set(findobj('tag','view'),'Enable','off');    
        end
        %___ Get selected MethodIndex given in project
        userMethodIndex=project.pipeline.userPipeline(iTaskIndex);%Init w. user-order method given in project
        
        %___ Get main_wrapper given in project
        wrapperFucn=project.pipeline.taskSetup{end,1}.function_wrapper;
        
       wrapperFucn=sprintf('%s(project,iTaskIndex,userMethodIndex)',wrapperFucn);%
        project=eval(wrapperFucn);    
        %____ Wait to avoid delays in actual system
        pause(1)
    end        
end

%____ Update mainGUI to first TASK
drawGUI(project.handles.h_mainfig,1);
taskGUI(project.handles.h_mainfig,1);

%______ Return the project structure ?
if(nargout==1)
    varargout={project};
end
