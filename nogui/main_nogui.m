function varargout=main_nogui(project,TaskIndex,MethodIndex,varargin)
% main_wrapper function is called if a function wrapper within the pipeline program is to be executed
%   such as a menu, task, method or configurator. All function wrappers are found in the project
%   and are identified through TaskIndex and MethodIndex (e.x.: 'project.pipeline.setupTask{TaskIndex,MethodIndex}.function_wrapper')
%
% To avoid crashes within a function_wrapper a TRY-CATCH bounds the calling function_wrapper. If a crash apear
%   an error is given for the actual function wrapper and the pipeline program will not be affected.
%
% Input:
%   project     : Structure containing all information of actual pipeline
%   TaskIndex   : Index to active task in the project structure
%   MethodIndex : Index to used method in a TaskIndex in the project structure
%   varargin    : Abitrary number of input commands given by user. 
%
% Output:
%   varargout{1}: Return updated project if wanted       
%
% Uses special functions:
%   logProject
%   checkIn
%   checkOut
%____________________________________________
% T. Dyrby, 170303, NRU
%SW version: 170303TD

%Below to easly solve a problem ...280303TD

project.handles.h_mainfig =  'n';

if(nargout==1)
    varargout={project};
end

if(length(MethodIndex)>1)
    MethodIndex=MethodIndex{1};
end


%_____ CheckIn

[project,stateReturn]=checkIn_nogui(project,TaskIndex,MethodIndex,varargin{1:end});

%____ Error at checkIn
if(project.pipeline.statusTask(TaskIndex)~=1 || stateReturn==1)% Error occored
    %Do some action...mayby an other task is activ?!?    
    
    %______ Return the project structure ?
    if(nargout==1)
        varargout={project};
    end    
    return
end

%_____ A configurator
Configurator=0;
if(~isempty(project.taskDone{TaskIndex}.command) && strcmp(project.taskDone{TaskIndex}.command{1},'configurator'))
    %Do something if command is configurator                
    Configurator=1;
end

if Configurator
    msg=sprintf('checkIn: %s',project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator_wrapper);
else
    msg=sprintf('checkIn: %s',project.pipeline.taskSetup{TaskIndex,MethodIndex}.function_wrapper);
end;

project=logProject(msg, project,TaskIndex,MethodIndex);

try% Check for occored errors in active method
    if(Configurator)       
        temp_pro=feval(project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator_wrapper,project,TaskIndex,MethodIndex);
    else
        temp_pro=feval(project.pipeline.taskSetup{TaskIndex,MethodIndex}.function_wrapper,project,TaskIndex,MethodIndex);  
    end
    project=temp_pro;
    clear('temp_pro');
catch
    msg=sprintf('---------------- CATCH: error is detected ------------------');
    project=logProject(msg, project,TaskIndex,MethodIndex);
    msg=lasterr;
    project.taskDone{TaskIndex}.error{end+1}=msg;
    msg=sprintf('Error in method: %s',msg);
    project=logProject(msg, project,TaskIndex,MethodIndex);
end

%_____ CheckOut
project=checkOut(project,TaskIndex,MethodIndex);

if(Configurator)
    msg=sprintf('CheckedOut: %s',project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator_wrapper);
else
    msg=sprintf('CheckedOut: %s',project.pipeline.taskSetup{TaskIndex,MethodIndex}.function_wrapper);
end
project=logProject(msg, project,TaskIndex,MethodIndex);
%______ Return the project structure ?
if(nargout==1)
    varargout={project};
end
%_____________________________________________________________________________________________________________