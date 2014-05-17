function [project]=checkOut(project,TaskIndex,MethodIndex,varargin)
% checkOut a method from the pipeline environment. 
%
% If no workspace and/or project exist on disc a new project and log file
%   are created, else they are updated.
% NOTE: names and directory for Workdir and project are alwas automatic created.
% When errors are detected: Clean up actual task and update project and return
% Task: 'Others': Has no influence on the status of the pipeline given in
%   'project.pipeline.statusTask(TaskIndex)'
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
%   Updateproject:
%   logProject:
%   rmProjectfiles:
%   setupPipeline:
%   drawGUI:
%____________________________________________
%SW version: 240803TD. By T. Dyrby, 120303, NRU

% TO DO, and DONE:
% - OK 220503TD: check clean up
% - OK 210503TD: save filestatus in .tasks{TaskIndex}
% - OK 210503TD: Update lastTaskIndex
% - OK 140603TD: Add error flag to .statusTask
% - OK 070803TD: Add configurator checkOut 
% - OK 120803TD: Possible to Save as template if a configuration is done before files is loaded or project created
% - OK 180803TD: Add project.sysinfo.workspace to Matlabpath and cnhange directory
% - OK 180803TD: Possible to select a main workspace where project and other files can be saved in a subdir
% - OK 240803TD: Promt user to change name of project. This option is only available if mainGUI exist
% - OK 270803TD: Add prefix to workdir given in setupfile

s_clock=clock;
msglog=sprintf('_______Time stamp: %s.%s.%s.%s.%s (mm.hh.dd.mm.yyyy)',num2str(s_clock(5)),num2str(s_clock(4)),num2str(s_clock(3)),num2str(s_clock(2)),num2str(s_clock(1)));
project=logProject(msglog,project,TaskIndex,MethodIndex);

%remove processID if any
if isfield(project.taskDone{TaskIndex},'processID')
    project.taskDone{TaskIndex}=rmfield(project.taskDone{TaskIndex},'processID');
end

%_________ CheckOut a configurator
if(isfield(project.taskDone{TaskIndex},'command') && ...
        ~isempty(project.taskDone{TaskIndex}.command) && ...
        strcmp(project.taskDone{TaskIndex}.command{1},'configurator'))
    chkOutConfigurator=1;   
else
    chkOutConfigurator=0;
end

%__________ Check done-entry
switch project.pipeline.statusTask(TaskIndex)
case {0,3} %READY, Added ERROR=3,140603TD   
    [project,msg]=logProject('CheckOut: Has NOT been checkedIn, is READY.',project,TaskIndex,MethodIndex);  
    
    if ischar(project.taskDone{TaskIndex}.error)
      project.taskDone{TaskIndex}.error{1}=msg;
    else  
      project.taskDone{TaskIndex}.error{end}=msg;% Add error msg
    end
    return    
    
case 1 %Active OK 
    %project=logProject('CheckOut: OK, Active.',project,TaskIndex,MethodIndex);    
    
case 2 %DONE
    [project,msg]=logProject('CheckOut: Has already been checkedOut, is DONE',project,TaskIndex,MethodIndex);        
    project.taskDone{TaskIndex}.error{end+1}=msg;% Add error msg
    return
    
otherwise
    [project,msg]=logProject('CheckOut: Unknown done-entry',project,TaskIndex,MethodIndex);
    
    project.taskDone{TaskIndex}.error{end+1}=msg;% Add error msg
    return
end%switch    
%end    

taskName= project.pipeline.taskSetup{TaskIndex,MethodIndex}.task;
if(strcmpi(taskName,'others'))    
    %Task 'Others' is alwas ready!!
    project.pipeline.statusTask(TaskIndex)=0;% Set actual method as 'READY'=0
    
    %Log info
    %project=logProject('CheckOut: Others',project,TaskIndex,MethodIndex);
    
    project.taskDone{TaskIndex}.error='';
    
    %__________ Update project and log file
    project=Updateproject(project,TaskIndex,MethodIndex); 
    
    %______ Update MainGUI if mainfig exist
    if(ishandle(project.handles.h_mainfig) && ~chkOutConfigurator)        
        drawGUI(project.handles.h_mainfig,TaskIndex);
    end
  
    return
end

%__________ Check for errors, if detected clean, update project and return
if(~isempty(project.taskDone{TaskIndex}.error))
    
    %______ Configurator?
    if(chkOutConfigurator)
        %________ Update logfile before erase actual task 
        [project,msg]=logProject('Error detected in configurator, settings are cleared.',project,TaskIndex,MethodIndex);
        %project.pipeline.taskSetup{TaskIndex,MethodIndex}=[];  
                 
        
        project.pipeline.statusTask(TaskIndex)=3;% Done=2, Active=1, Ready=0,Error=3,Added ERROR,140603TD   
        %__________ Update project and log file    
        project=Updateproject(project,TaskIndex,MethodIndex); 
        return
    end
    
    project.pipeline.statusTask(TaskIndex)=3;% Done=2, Active=1, Ready=0,Error=3,Added ERROR,140603TD   
    
    %________ Update logfile before erase actual task 
    [project,msg]=logProject('Error detected, task is cleaned-up at checkOut.',project,TaskIndex,MethodIndex);
    
    %________ Clean-up after erase (except input files)    
    project=rmProjectfiles(project,TaskIndex,MethodIndex);
    
    %________ Clear actual task...
    project.taskDone{TaskIndex}='';       
    
    %__________ Update project and log file    
    project=Updateproject(project,TaskIndex,MethodIndex);    
    
    %______ Update MainGUI if mainfig exist
    if(ishandle(project.handles.h_mainfig) & ~chkOutConfigurator)        
        drawGUI(project.handles.h_mainfig,TaskIndex);
    end
    return
end

%__________ Update time-entry (finish)
project.taskDone{TaskIndex}.time.finish=num2str(clock);


%____ Update task w. Configuration parameters
if(chkOutConfigurator)
    config_TaskIndex=project.taskDone{TaskIndex}.command{2};    
    config_MethodIndex=project.taskDone{TaskIndex}.command{3};    
    %Copy settings from temp task in project
    project.pipeline.taskSetup{config_TaskIndex,config_MethodIndex}.configurator=...
        project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator;
    
    project.pipeline.statusTask(TaskIndex)=0;% Done=2, Active=1, Ready=0    
    %Clear temp. task in project         
    TaskIndex=config_TaskIndex;    
    MethodIndex=config_MethodIndex;
else
    %___________Transfer configuration settings to taskDone
    project.taskDone{TaskIndex}.configuration=project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.user;
  
    %__________ Update Last TaskIndex if success (NOT configurators):     
    project.pipeline.statusTask(TaskIndex)=2;% Done=2, Active=1, Ready=0    
    
    if(project.pipeline.lastTaskIndex(end)~=TaskIndex)
        project.pipeline.lastTaskIndex(end+1)=TaskIndex;
    end    
end

%__________ Update project and log file
project=Updateproject(project,TaskIndex,MethodIndex);

%______ Update MainGUI if mainfig exist
if(ishandle(project.handles.h_mainfig) & ~chkOutConfigurator)        
    drawGUI(project.handles.h_mainfig,TaskIndex);
end


