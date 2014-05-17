function [project,stateReturn]=checkIn_nogui(project,TaskIndex,MethodIndex,varargin)
% checkIn controls the flow of a pipleine given in the setupfile
%   and in project.pipeline.setupTask.{TaskIndex,MethodIndex}
% 
% Checks if a method is allowed to be started and needed functions are available.
% Tasks named 'others' have no influence on the pipeline and can be executed 
% in parallel with tasks in the pipeline (unless anything else is given for this tasks!)
%
% Input:
%   project     : Structure containing all information of actual pipeline
%   TaskIndex   : Index to active task in the project structure
%   MethodIndex : Index to used method in a TaskIndex in the project structure
%   varargin    : Abitrary number of input commands given by user. Is stored in 'project.taskDone{TaskIndex}.command' 
%           configurator:
%               varargin{1}='configurator'
%               varargin{2}='TaskIndex'
%               varargin{3}='MethodIndex'
%
% Output:
%   project     : Return updated project       
%   stateReturn : '1': Method could not be started.
%                 '0': Method started w. no errors.
%
% Uses special functions:
%       rmProjectfiles
%       logProject 
%       get_username
%       drawGUI:
%____________________________________________
% T. Dyrby, 120303, NRU
%SW version: 069003TD, by T. Dyrby, 120303, NRU

% TO DO:
% - OK 230503TD: Use lastTaskIndex
% - OK 230503TD: If an old task is redone then remove all projectfiles from following tasks!!
% - OK 140603TD: Add error flag to .statusTask
% - OK 200603TD: Check to remove both datafile and headerfile of image!!
% - OK 300603TD: Add username field and to title
% - OK 290703TD: Add code to get username from system
% - OK 070808TD: Add configurator checkIn 
% - OK 060903TD: Set as default current directory==project.info.workspace
% - OK 221203TR: Upgrade of Redo-dialog.
% - OK 100104TR: Detach function implemented

%_________ CheckIn a configurator
if(length(varargin)>0 & strcmp(varargin{1},'configurator'))
    chkInConfigurator=1; 
else
    chkInConfigurator=0;
end

stateReturn=0;


%__________ Check if other tasks in the pipeline are active...
%Tasks named 'other' have no influence on the pipeline 
if(~strcmp(lower(project.pipeline.taskSetup{TaskIndex,MethodIndex}.task),'others'))
    q=find(project.pipeline.statusTask==1); %'ACTIVE'=1   

   
    %a configurator is checked in (eg. TaskIndex=8, MethodIndex=16)
    if (~isempty(q) & chkInConfigurator) %configurator 
        %____ Set Indexes to GUIselected
        TaskSelected=project.handles.data.SelectedTaskIndexGUI;
        i=1;
        while ~isempty(project.pipeline.taskSetup{TaskSelected,i})
            if strcmp(project.pipeline.taskSetup{TaskSelected,i}.method,project.pipeline.taskSetup{TaskIndex,MethodIndex}.method)
                MethodIndex=i;
                break;
            end
            i=i+1;
        end	
        TaskIndex=TaskSelected;
    end
    
    %A configurator is running
    if(~isempty(q) && strcmp(project.pipeline.taskSetup{q(1),1}.task,'PipelineProgram'))
        Ans=questdlg('A configurator is running. Would you like to detach from the configurator (data in configurator will be lost)?','Detach from configurator?','Yes','No','No');          
        if strcmp(Ans,'Yes')
            CleanTaskIndex=q(1);     
                
            project=logProject('Detach selected. Detaching from configurator...',project,CleanTaskIndex,1);    
            
            project=logProject('checkIn (clean-up): Clearing taskDone',project,CleanTaskIndex,1);    
            project.taskDone{CleanTaskIndex}='';   

            project=logProject('checkIn (clean-up): Set task to ready',project,CleanTaskIndex,1);    
            project.pipeline.statusTask(CleanTaskIndex)=0; % Done=2, Active=1, Ready=0

            %__________ Update project and log file
            project=Updateproject(project,TaskIndex,MethodIndex);    
            drawGUI(project.handles.h_mainfig,TaskIndex); 
        end
        stateReturn=1;
        return     
    end
        
    %A method is running
    if(~isempty(q) & ~strcmp(lower(project.pipeline.taskSetup{q(1),MethodIndex}.task),'others'))
        Ans=questdlg('A task in the pipeline is already running. Would you like to detach from the running method (results already generated in this method will be lost)?','Detach from running method?','Yes','No','No');          
        if strcmp(Ans,'Yes')
            %______________ Clean taskDone _____________
            CleanTaskIndex=q(1);
            
            %Find the used method
            Si=size(project.pipeline.taskSetup);
            for i=1:Si(2)
                if ~isempty(project.taskDone{CleanTaskIndex}) &...
                       ~isempty(project.pipeline.taskSetup{CleanTaskIndex,i}) &...
                        strcmp(project.taskDone{CleanTaskIndex}.method,project.pipeline.taskSetup{CleanTaskIndex,i}.method)
                    CleanMethodIndex=i;
                    break;
                end
            end
            
            project=logProject('Detach selected. Reverting changes made by method...',project,CleanTaskIndex,CleanMethodIndex);    
            
            %________ Clean-up after erase (except input files)    
            project=logProject('checkIn (clean-up): Erase files',project,CleanTaskIndex,CleanMethodIndex);    
            project=rmProjectfiles(project,CleanTaskIndex,CleanMethodIndex);
            
            %________ Clear actual task...
            project=logProject('checkIn (clean-up): Clear taskDone',project,CleanTaskIndex,CleanMethodIndex);    
            project.taskDone{CleanTaskIndex}='';   

            %No update lastTask, because the running task has not been put in yet
%             %________ Updata lastTask (resize)
%             if(length(project.pipeline.lastTaskIndex)>1)
%                 project=logProject('checkIn (clean-up): Update lastTask',project,CleanTaskIndex,CleanMethodIndex);    
%                 project.pipeline.lastTaskIndex=project.pipeline.lastTaskIndex(1:end-1);
%             end
               
            %________ Set to 'Ready' in statusTask
            project=logProject('checkIn (clean-up): Set task to ready',project,CleanTaskIndex,CleanMethodIndex);    
            project.pipeline.statusTask(CleanTaskIndex)=0; % Done=2, Active=1, Ready=0
         
            %___________________________________________
 
            %__________ Update project and log file

            project=Updateproject(project,TaskIndex,MethodIndex);    
            drawGUI(project.handles.h_mainfig,TaskIndex);   
        end
        stateReturn=1;
        return     
    end
end


%__________Check if program for given method exist...
if(project.pipeline.taskSetup{TaskIndex,MethodIndex}.filesexist==0)
    [project,msg]=logProject('CheckIn: Program could not be found.',project,TaskIndex,MethodIndex); 
    project.taskDone{TaskIndex}.error=msg;
    stateReturn=1;
    return
end


if(~chkInConfigurator)    

    %__________Check if method can run under current OS...
    OS=project.pipeline.taskSetup{TaskIndex,MethodIndex}.require_os;
    if(OS==0 | (OS==1 & isunix) | (OS==2 & ~isunix))
        
    else
        display_text('Method not compatible with current Operating System.');
        stateReturn=1;
        return;
    end
         
            
    
    require_taskIndex=project.pipeline.taskSetup{TaskIndex,MethodIndex}.require_taskindex; %Get requirement of done tasks 
    
    %__________Check if required tasks are done...
    for(taskCount=1:length(require_taskIndex))
        if(isempty(require_taskIndex{taskCount}));   %No requirements to task
        else
            if(require_taskIndex{taskCount}==0)      %Task has to be completed
                if(project.pipeline.statusTask(taskCount)~=2)
                    display_text(['Task ',num2str(taskCount),' not completed.']);
                    stateReturn=1;
                    return;
                end
            else   %Task has to be completed with one of the methods in vector.
                methodDone=false;
                methodVector=require_taskIndex{taskCount};
                if (project.pipeline.statusTask(taskCount)==2)
                    for(methodCount=1:length(methodVector))
                        if strcmp(project.taskDone{taskCount}.method,project.pipeline.taskSetup{taskCount,methodVector(methodCount)}.method)
                            methodDone=true;
                        end
                    end
                else 
                    display_text(['Task ',num2str(taskCount),' not completed.']);
                    stateReturn=1;
                    return;
                end
                
                if(~methodDone)
                    display_text(['Task ',num2str(taskCount),' not completed with required method(s): ',num2str(methodVector),'.']);
                    stateReturn=1;
                    return;
                end
            end
        end
    end
    
    
    %__________ Check if task already is done...
    if(project.pipeline.statusTask(TaskIndex)==2)%'DONE'=2
        msg=sprintf('Redo task: %s ?',project.pipeline.taskSetup{TaskIndex,1}.task); % Display that task is done
        asw=questdlg(sprintf('Warning: Redo deletes output located in project directory,\ngenerated by this and all following tasks!\nRename files if you want to keep them.'),msg,'Redo','Cancel','Cancel');
        if(strcmp(asw,'Cancel') || isempty(asw))
            project=logProject('Redo canceled, no checkIn',project,TaskIndex,MethodIndex);
            stateReturn=1;
            return
        end
        project=logProject(msg,project,TaskIndex,MethodIndex);    
        
        %_______ Clear following tasks in project already done
        for(CleanTaskIndex=(length(project.pipeline.statusTask)):-1:TaskIndex)
                        
            %Do not change Tasks:'Others'
            if(strcmpi(project.pipeline.taskSetup{CleanTaskIndex,1}.task,'others'))
                continue
            end
            
            
            %Add ERROR,140603TD     
            if(project.pipeline.statusTask(CleanTaskIndex)==0 || project.pipeline.statusTask(CleanTaskIndex)==3)
                continue
            else           
                %Get existing Method index for task to be ereased
                %CleanMethodIndex=project.pipeline.userPipeline(CleanTaskIndex);
                CleanMethodIndex=0;
                i=1;
                while ~isempty(project.pipeline.taskSetup{CleanTaskIndex,i})
                    if strcmp(project.taskDone{CleanTaskIndex}.method,project.pipeline.taskSetup{CleanTaskIndex,i}.method)
                        CleanMethodIndex=i;
                        break;
                    end
                    i=i+1;
                end
                
                %________ Clean-up after erase (except input files)    
                project=logProject('checkIn (clean-up): Erase files',project,CleanTaskIndex,CleanMethodIndex);    
                project=rmProjectfiles(project,CleanTaskIndex,CleanMethodIndex);
                
                %________ Clear actual task...
                project=logProject('checkIn (clean-up): Clear taskDone',project,CleanTaskIndex,CleanMethodIndex);    
                project.taskDone{CleanTaskIndex}='';   
                
                %________ Updata lastTask (resize)
                if(length(project.pipeline.lastTaskIndex)>1)
                    project=logProject('checkIn (clean-up): Update lastTask',project,CleanTaskIndex,CleanMethodIndex);   
                    
                    %Go through lastTaskIndex and remove any occurences of CleanTaskIndex
                    new(1)=project.pipeline.lastTaskIndex(1);
                    for k=2:length(project.pipeline.lastTaskIndex)
                        if project.pipeline.lastTaskIndex(k)==CleanTaskIndex
                            %do nada
                        else
                            new(end+1)=project.pipeline.lastTaskIndex(k);
                        end
                    end
                    project.pipeline.lastTaskIndex=new;
                end
                
                %________ Set to 'Ready' in statusTask
                project=logProject('checkIn (clean-up): Set task to ready',project,CleanTaskIndex,CleanMethodIndex);    
                project.pipeline.statusTask(CleanTaskIndex)=0; % Done=2, Active=1, Ready=0
            end
        end%cleanUp     
    end    
end%if(~chkInConfigurator)


%_____________________________________________________
%_____%%%% Setup project.taskDone{TaskIndex} %%%%_____
%_____________________________________________________

%__________ Define basic-structure of the task...
project.taskDone{TaskIndex}.task=project.pipeline.taskSetup{TaskIndex,MethodIndex}.task;
project.taskDone{TaskIndex}.method=project.pipeline.taskSetup{TaskIndex,MethodIndex}.method;
project.taskDone{TaskIndex}.time.start=num2str(clock);
project.taskDone{TaskIndex}.time.finish='';
project.taskDone{TaskIndex}.error='';
project.taskDone{TaskIndex}.command='';  
project.taskDone{TaskIndex}.userdata='';
project.taskDone{TaskIndex}.configuration='';
project.taskDone{TaskIndex}.username=''; 
project.taskDone{TaskIndex}.filestatus=project.pipeline.taskSetup{TaskIndex,MethodIndex}.filestatus;
project.taskDone{TaskIndex}.processID=rand(1)*100000;

ImageIndex=project.pipeline.imageIndex(1);

if ~isempty(project.pipeline.imageModality) %imagemodality is set by fileload
    %fileload creates its own filefields depending on number of loaded
    %modalities
    for ModalityIndex=1:length(project.pipeline.imageModality)
        project.taskDone{TaskIndex}.inputfiles{ImageIndex,ModalityIndex}.path='';
        project.taskDone{TaskIndex}.inputfiles{ImageIndex,ModalityIndex}.name='' ;
        project.taskDone{TaskIndex}.inputfiles{ImageIndex,ModalityIndex}.info='';
        
        project.taskDone{TaskIndex}.outputfiles{ImageIndex,ModalityIndex}.path='';
        project.taskDone{TaskIndex}.outputfiles{ImageIndex,ModalityIndex}.name='';
        project.taskDone{TaskIndex}.outputfiles{ImageIndex,ModalityIndex}.info='';
        
        project.taskDone{TaskIndex}.show{ImageIndex,ModalityIndex}.name='';
        project.taskDone{TaskIndex}.show{ImageIndex,ModalityIndex}.path=''; 
        project.taskDone{TaskIndex}.show{ImageIndex,ModalityIndex}.info='';      
    end     
end

s_clock=clock;
msglog=sprintf('_______Time stamp: %s.%s.%s.%s.%s (mm.hh.dd.mm.yyyy)',num2str(s_clock(5)),num2str(s_clock(4)),num2str(s_clock(3)),num2str(s_clock(2)),num2str(s_clock(1)));
project=logProject(msglog,project,TaskIndex,MethodIndex);

%_________ Check if a command is handled to the method
if(nargin>3)
    for(i=1:length(varargin))
        project.taskDone{TaskIndex}.command{i}=varargin{i};  
    end
end

%__________ Define outputname if input name exist...
if(TaskIndex>1 & project.pipeline.lastTaskIndex(end)~=0 && ~chkInConfigurator) % Files are loaded
   
%     %If inputfiles has vanished...it could happen
%     for(i=1:length(project.pipeline.imageModality))
%        
%        %No filename exist
%         if(isempty(project.taskDone{TaskIndex}.inputfiles{1,i}.name))
%             msg='CheckIn: No inputfiles available';
%             project=logProject(msg,project,TaskIndex,MethodIndex);
%             project.taskDone{TaskIndex}.error{end+1}=msg;
%             return;
%         end
%         
%        %Filename exist, but no file 
%        chkInputfilename=fullfile('',project.taskDone{TaskIndex}.inputfiles{1,i}.path,...
%            project.taskDone{TaskIndex}.inputfiles{1,i}.name);
%              
%         if(~exist(chkInputfilename,'file'))
%             msg=sprintf('CheckIn: Inputfile do not exist: ''%s''',chkInputfilename);
%             project=logProject(msg,project,TaskIndex,MethodIndex);
%             project.taskDone{TaskIndex}.error{end+1}=msg;
%             return;
%         end
%     end
%     

    project.taskDone{TaskIndex}.inputfiles=project.taskDone{project.pipeline.lastTaskIndex(end)}.outputfiles;%Use output files from last task
    
    prefix=project.pipeline.taskSetup{TaskIndex,MethodIndex}.prefix;
    
    %_______ Prefix empty: Input=output filename. No outputfile is made from given method/task
    if(isempty(prefix))
        project.taskDone{TaskIndex}.outputfiles=project.taskDone{TaskIndex}.inputfiles;%Use output files from last task             
    else
        for(ModalityIndex=1:length(project.pipeline.imageModality))            
            %No filename exist
            if(isempty(project.taskDone{TaskIndex}.inputfiles{1,ModalityIndex}.name))
                msg='CheckIn: No inputfiles available';
                project=logProject(msg,project,TaskIndex,MethodIndex);
                project.taskDone{TaskIndex}.error{end+1}=msg;
                return;
            end
            
            %Filename exist, but no file 
            chkInputfilename=fullfile('',project.taskDone{TaskIndex}.inputfiles{1,ModalityIndex}.path,...
                project.taskDone{TaskIndex}.inputfiles{1,ModalityIndex}.name);
            
            if(~exist(chkInputfilename,'file'))
                msg=sprintf('CheckIn: Inputfile do not exist: ''%s''',chkInputfilename);
                project=logProject(msg,project,TaskIndex,MethodIndex);
                project.taskDone{TaskIndex}.error{end+1}=msg;
                return;
            end
            %Make outfilenames
            project.taskDone{TaskIndex}.outputfiles{ImageIndex,ModalityIndex}.name=[prefix,'_',project.taskDone{TaskIndex}.inputfiles{ImageIndex,ModalityIndex}.name];%Use output files from last task    
            project.taskDone{TaskIndex}.outputfiles{ImageIndex,ModalityIndex}.path=project.sysinfo.workspace;% Use always workspace as outputpath             
            project.taskDone{TaskIndex}.outputfiles{ImageIndex,ModalityIndex}.info=project.taskDone{TaskIndex}.inputfiles{ImageIndex,ModalityIndex}.info;% Use always workspace as outputpath             
        end
    end
end


%__________ Set task/method to active (checked in w. no errors)...
project.pipeline.statusTask(TaskIndex)=1;% Set actual method as 'ACTIVE'=1

%______ Save actual username
project.taskDone{TaskIndex}.username=get_username; 

%______ Default current directory=workspace
cd(project.sysinfo.mainworkspace);