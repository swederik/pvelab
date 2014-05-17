function varargout=main_wrapper(project,TaskIndex,MethodIndex,varargin)
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

if(length(MethodIndex)>1)
    MethodIndex=MethodIndex{1};
end


%_____ CheckIn
[project,stateReturn]=checkIn(project,TaskIndex,MethodIndex,varargin{1:end});

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

%_____ Call function wrapper
drawnow;%Flush GUI

try% Check for occored errors in active method
    if(Configurator)       
        temp_pro=feval(project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator_wrapper,project,TaskIndex,MethodIndex);
    else
        temp_pro=feval(project.pipeline.taskSetup{TaskIndex,MethodIndex}.function_wrapper,project,TaskIndex,MethodIndex);  
    end
    %Check if cancel has been pressed:
    %if so - discard project and return unnoticed from callback
    if ishandle(project.handles.h_mainfig)
        GUI_pro=get(project.handles.h_mainfig,'userdata');
        if ~isempty(GUI_pro.taskDone{TaskIndex}) &&...
                isfield(GUI_pro.taskDone{TaskIndex},'processID') &&...
                isfield(temp_pro.taskDone{TaskIndex},'processID') &&...
                (temp_pro.taskDone{TaskIndex}.processID==GUI_pro.taskDone{TaskIndex}.processID)
            %Cancel has not been pressed, proceed normally
            %disp('no cancel');                
            project=temp_pro;
            clear('temp_pro');
            clear('GUI_pro');
        else
            %Cancel has been pressed, return the current project found in mainfig
            clear('temp_pro');
            if(nargout==1)
                varargout={GUI_pro};
            end
            clear('GUI_pro');                
            return
            %Get out of callback without changing curent project
        end
    else
        project=temp_pro;
        clear('temp_pro');
    end
    
catch
    %Check if cancel has been pressed:
    %if so - discard project and return unnoticed from callback
    if ishandle(project.handles.h_mainfig)
        GUI_pro=get(project.handles.h_mainfig,'userdata');
        if ~isempty(GUI_pro.taskDone{TaskIndex}) &&...
                isfield(GUI_pro.taskDone{TaskIndex},'processID') &&...
                isfield(project.taskDone{TaskIndex},'processID') &&...
                (project.taskDone{TaskIndex}.processID==GUI_pro.taskDone{TaskIndex}.processID)
            %Cancel has not been pressed, proceed normally
            clear('GUI_pro');
            %disp('no cancel');
        else
            %Cancel has been pressed, return the current project found in mainfig
            if(nargout==1)
                varargout={GUI_pro};
            end
            clear('GUI_pro');
            return
            %Get out of callback without changing curent project
        end
    else
        return;
    end

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