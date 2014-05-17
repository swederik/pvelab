function project=setupPipeline(project,TaskIndex,MethodIndex,command,varargin)
% Setup a project in the pipeline program and starts up or update the GUI of
%  the pipeline program.
%
% Input:
%   project     : Structure containing all information of actual pipeline
%   TaskIndex   : Index to active task in the project structure
%   MethodIndex : Index to used method in a TaskIndex in the project structure
%   command     :
%          'new'        : New project in an existing mainGUI (use handles). If a project used setting are reused in ne project!!
%          'load'       : Load an project (*.prj) into the pipeline and update mainGUI
%          'save'       : Save project (*.prj) to disc, to mainGUi (if exist) and update logfile
%          'saveastemplate': Generate a template from given project and save it (*.mrc)
%          'loadtemplate'  : Load a templatefile (*.mrc) and setup a project
%          'defaultsettings': Load default setting. Do not rests the project
%   varargin    : Abitrary number of input arguments. (NOT USED)
%
% Output:
%   project     : Return updated project       
%
% Uses:
%   logProject   
%   fileVersion
%   setupProject
%   mainGUI
%____________________________________________
%SW version: 100903TD, By T. Dyrby, 130303, NRU
%

% To DO:
% - load template: only use sysfiles with SW label given in template??
% - load template: how to use different pipelines:Marco uses setups for a given pipeline->therefor not a problem??
% - OK 120808TD: Check is loadede project work on actual OS system
% - OK 140803TD: Setup Matlab path for system files and workspace
% - OK 180803TD: Setup Matlab path when 'load' new project. Use loadede project settings and path, else use new
% - OK 180803TD: Check that the only one pipeline program is started (mainGUI)
% - OK 240803TD: Reset active flags in 'project.pipeline.statusTask()==1' if found when loading a project
% - OK 100903TD. Fix error unknown mainworkspace when loading template
% - OK 261103TD: Fix problem when cleanUp Matlabpath add function: 'pip_cleanMatlabpath()'


%_______ New or Load project, MainGUI exist
if(isstruct(project))
    
    %Mark that load project is active
%    tmpstatusTask=project.pipeline.statusTask(TaskIndex);       
%    Removed 10072004 by Rask
    
    
    switch(lower(command))
        %_______ Save/update project
    case 'save'
        %_______ New project project and logfile
        project=pip_createProject(project,TaskIndex,MethodIndex,1);        
        Updateproject(project,TaskIndex,MethodIndex);
        project=logProject('Project saved',project,TaskIndex,MethodIndex); 
        return
        
        %_______ Save project as a template
    case 'saveastemplate'       
        template=project;
        %clear fields not used
        template.handles='';
        template.tasks='';
        template.sysinfo='';        
        template.pipeline.statusTask=[];
        template.pipeline.lastTaskIndex=[];   
        
        %Save template-project onto disc
        [temName, temPath] = uiputfile('*.tem','Save template as');
        % Check if a file is selected
        if(temName==0)
            project=logProject('No file to save as',project,TaskIndex,MethodIndex); 
            return
        else
            [file_pathstr,file_name,file_ext] = fileparts(temName);            
        end
        %save template file on disc
        save(fullfile('',temPath,[file_name,'.tem']),'template','-MAT'); 
        return        
        
        %_______ Save project as a template
    case 'loadtemplate'
        % Load template
        project=logProject('Load template',project,TaskIndex,MethodIndex); 
        % User select project to load
        [temName,temPath]=uigetfile('*.tem','Load template project');    
        
        % Check if a file is selected
        if(temName==0)
            project=logProject('No template loaded',project,TaskIndex,MethodIndex); 
            return
        else
            [file_pathstr,file_name,file_ext] = fileparts(temName);
            % Check if the loadede file is a project using the extension
            if(~strcmp(file_ext,'.tem'))
                msg='Selected file is not a project';
                ansawer=errordlg(msg,'Load template project'); %   
                project=logProject(msg,project,TaskIndex,MethodIndex); 
                return
            end 
        end%
        
        %load template
        template=load(fullfile('',temPath,temName),'-MAT'); 
        
        %______Make new project        
        % Load same configuration of pipeline given i project
        %UsePipeline=fullfile('',project.pipeline.taskSetup{end,1}.configuratorfile.path,project.pipeline.taskSetup{end,1}.configuratorfile.name);
        
        %NOTE: maby a problem if path do not exist...But then avoid OS problems!!!!!250803TD
        RESTORE_project=project;
        
        UsePipeline=project.pipeline.taskSetup{end,1}.configurator.configurator_name;
        project=setupProject(project.handles,UsePipeline);         
        
        % Setup project as given in the template
        project.pipeline.taskSetup=template.template.pipeline.taskSetup;        
        project.pipeline.userPipeline=template.template.pipeline.userPipeline;        
        project.pipeline.defaultPipeline=template.template.pipeline.defaultPipeline;  
        project.sysinfo.mainworkspace=pwd;%Set mainworkspace as current directory
        project.sysinfo.tmp_workspace=RESTORE_project.sysinfo.tmp_workspace;%Use known
        PipeLine=which('setupPipeline');
	[pn,fn]=fileparts(PipeLine);
        project.sysinfo.systemdir=pn;
        project.sysinfo.systemfile=fn;
        if(isunix)
            project.sysinfo.os='UNIX';
        else
            project.sysinfo.os='WINDOWS';
        end
        project.sysinfo.version= ...
           RESTORE_project.sysinfo.version;
        msg=sprintf('template file loaded: %s',fullfile('',temPath,temName));
        project=logProject(msg,project,TaskIndex,MethodIndex); 
        
    case 'defaultsettings'
        % Load same configuration of pipeline given i project
        project.pipeline.userPipeline=project.pipeline.defaultPipeline;
        
        %_______ update mainGUI
        project=mainGUI(project,1);
        return
        
        %_______ New or default settings project 
    case 'new'
        
        %Question dialog
        answ=questdlg('Do you want to leave current project?','New project','Yes','No','No');
        if strcmp(answ,'No')
            project=logProject('New project cancelled...',project,TaskIndex,MethodIndex);         
            return
        end
        
        % Load same configuration of pipeline given i project
        %UsePipeline=fullfile('',project.pipeline.taskSetup{end,1}.configuratorfile.path,project.pipeline.taskSetup{end,1}.configuratorfile.name);

        %NOTE: maby a problem if path do not exist...But then avoid OS problems!!!!!250803TD
        UsePipeline=project.pipeline.taskSetup{end,1}.configurator.configurator_name;
        
        %Remove old Matlab path
        project=logProject('New project:',project,TaskIndex,MethodIndex);         
        project=logProject('Removing old matlabpath...',project,TaskIndex,MethodIndex);                 
        pip_cleanMatlabpath(project.sysinfo.tmp_workspace)%261103TD

%         if(~isempty(project.sysinfo.tmp_workspace))
%             for(i=1:length(project.sysinfo.tmp_workspace))%NOTE: first dir is not removed is system dir
%                 %ONLY FOR TEST (project.sysinfo.tmp_workspace{i})%100903TD
%                 
%                 if(exist(project.sysinfo.tmp_workspace{i})==7 & ~isempty(strfind(project.sysinfo.tmp_workspace{i},path)))
%                     rmpath(project.sysinfo.tmp_workspace{i});%Clean-up Matlab path for old paths
%                 end        
%             end    
%         end
        tmp_sysinfo=project.sysinfo;
        
        %_____Set GUI-task to 1 011203TR
        project.handles.data.SelectedTaskIndexGUI=1;
        
        %____ Add pipeline subdirs to Matlab path 
        project=logProject('Creating new matlabpath...',project,TaskIndex,MethodIndex);                         
        subDir=genpath(tmp_sysinfo.systemdir);
        if(isunix)%OS difference
            q=strfind(subDir,':'); 
        else
            q=strfind(subDir,';'); 
        end
        qI=1;
        addpath(subDir(qI:q(1)-1),'-begin');%First dir is system which is not removed on exit
        qI=q(1)+1;;
        for(i=2:length(q))
            tmp_sysinfo.tmp_workspace{end+1}=subDir(qI:q(i)-1);%Directories to be removed on exist           
            addpath(tmp_sysinfo.tmp_workspace{end},'-begin');
            qI=q(i)+1;
        end

        %_____Setup new project w. given setupfile
        project=logProject('Resetting project...',project,TaskIndex,MethodIndex);                         
        project=setupProject(project.handles,UsePipeline);    
        
        %Add sysinfo to new project        
        project.sysinfo.systemdir=tmp_sysinfo.systemdir;
        project.sysinfo.version=tmp_sysinfo.version;
        project.sysinfo.systemfile=tmp_sysinfo.systemfile;
        project.sysinfo.os=tmp_sysinfo.os;
        project.sysinfo.mainworkspace=tmp_sysinfo.mainworkspace;
        project.sysinfo.tmp_workspace=tmp_sysinfo.tmp_workspace;

        %Log info
        [NoTasks,NoMethods]=size(project.pipeline.taskSetup);
        msg=sprintf('Systemdir: %s, pwd: %s',project.sysinfo.systemdir,pwd);           
        project=logProject(msg,project,NoTasks,1);   

        
        %_______ Load project         
    case 'load'        
        project=logProject('Load project:',project,TaskIndex,MethodIndex); 
        % User select project to load
        [prjName,prjPath]=uigetfile('*.prj','Load project');    
        
        % Check if a file is selected
        if(prjName==0)
            project=logProject('No project loaded',project,TaskIndex,MethodIndex); 
            return
        else
            [file_pathstr,file_name,file_ext] = fileparts(prjName);
            % Check if the loadede file is a project using the extension
            if(~strcmp(file_ext,'.prj'))
                msg='Selected file is not a project';
                ansawer=errordlg(msg,'Load project'); %   
                project=logProject(msg,project,TaskIndex,MethodIndex); 
                return
            end 
        end%
        
        %_______ Load selected project into the pipeline
        RESTORE_project=project;% If something happens....
        
        Load_project=load(fullfile('',prjPath,prjName),'-MAT'); 
        
        %_______ Check if loaded project work on actual OS        
        if(isunix)
            OS='UNIX';
        else
            OS='WINDOWS';
        end
        
        if(~strcmp(Load_project.project.sysinfo.os,OS))&&(isempty(Load_project.project.sysinfo.os))
            msg=sprintf('Err: Project is for OS=%s NOT %s',Load_project.project.sysinfo.os,OS);           
            project=logProject(msg,project,TaskIndex,MethodIndex); 
            return
        end
        
        %!!!!! NOTE handles must NOT be used from loaded project because of incorrect handles !!!!!!!!
        project=Load_project.project;
        project.handles=RESTORE_project.handles;%Use same handles
        project.handles.data.SelectedTaskIndexGUI=1; %Reset selected taskindex to 1
        
        %________ Setup Matlab path         
        %Check path for setupPipeline.m and version number (selects the first file independed of version number!!!)
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   
        % Setup Matlab path given in loaded project        
        if(exist(project.sysinfo.systemdir,'dir'))
            %Loginfo
            
            %Remove old sysinfo from Matlab path 
            project=logProject('Removing old matlab path...',project,TaskIndex,MethodIndex);

            pip_cleanMatlabpath(RESTORE_project.sysinfo.tmp_workspace)%261103TD

%             for(i=1:length(RESTORE_project.sysinfo.tmp_workspace))
%                 if(~isempty(strfind(RESTORE_project.sysinfo.tmp_workspace{i},path)))
%                     rmpath(RESTORE_project.sysinfo.tmp_workspace{i});
%                 end
%             end
            
            %Add the loaded paths:
            project=logProject('Loading matlab path from project...',project,TaskIndex,MethodIndex);
            
            addpath(project.sysinfo.systemdir,'-begin');            
            %Add new sysinfo to loaded project
            for(i=1:length(project.sysinfo.tmp_workspace))
                addpath(project.sysinfo.tmp_workspace{i},'-begin');
            end
            
            
        else%old system dir do not exist, make new
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %msg=sprintf('!!!! REMEMBER to report problems !!!!')% Display that task is done
            %asw=questdlg('Textfile: BUGnFIX.txt',msg,'OK','OK');
            msg=sprintf('A new project file have to be generated as the current code basis have switched');
            asw=questdlg('Current code basis have switched, therefore a new project file have to be generated',msg,'OK','OK');
            drawnow
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            
            %___ Remove and check for redundanc system files in Matlabpath
            fileInfo=fileVersion([],'setupPipeline.m','SW version');       
            for(i=1:length(fileInfo)) %NOTE possible to check if more files or versions of the Pipeline program exist in matlabpath                
                %Get all sub directories to current system dir
                subDir=genpath(fileInfo{1}.path);
                if(isunix)%OS difference
                    q=strfind(subDir,':'); 
                else
                    q=strfind(subDir,';'); 
                end
                qI=1;
                for(i=1:length(q))%Remove also all subdir
                    test{i}=subDir(qI:q(i)-1);    
                    qI=q(i)+1;
                    pip_cleanMatlabpath(test{i})%261103TD

                    %if(exist(test{i})==7 & ~isempty(strfind(test{i},path)))
                    %    rmpath(test{i});%Clean-up Matlab path for old paths
                    %end
                end
            end
            
            %____ Setup new Matlab path (Add system files and subdir to Matlab path)
            tmp_workspace=[];
            qI=1;
            addpath(subDir(qI:q(1)-1),'-begin');%First dir is system which is not removed on exit
            qI=q(1)+1;;
            for(i=2:length(q))
                tmp_workspace{end+1}=subDir(qI:q(i)-1);%Directories to be removed on exist           
                addpath(tmp_workspace{end},'-begin');
                qI=q(i)+1;
            end
            
            %Add sysinfo to project
            project.sysinfo.systemdir=fileInfo{1}.path;    
            project.sysinfo.version=fileInfo{1}.version;
            project.sysinfo.systemfile=fileInfo{1}.filename;
            project.sysinfo.os=fileInfo{1}.os;
            %Current directory is states as mainworkspace where new project is placed as subdir
            project.sysinfo.mainworkspace=pwd;
          	project.pipeline.statusTask(7)=0;    
            
            %_____ Reset ACTIVE flags in statusTasks to READY
            IndexActive=find(project.pipeline.statusTask==1);
            if(~isempty(IndexActive))
                project.pipeline.statusTask(IndexActive)=0;%Active=1, Ready=0;
                %Loginfo
                project=logProject('Reset active tasks',project,TaskIndex,MethodIndex);
            end
            
            %_____Update status of Task, so to checkOut without errors            
            project.taskDone{TaskIndex}=RESTORE_project.taskDone{TaskIndex};
            
            %Loginfo            
            project=logProject('Setup Matlab path: New path do not exist in loaded project',project,TaskIndex,MethodIndex);
            
        end%exist sys dir
        
        % Change to main workspace 
        cd(project.sysinfo.mainworkspace);  
        
        %_____ Reset ACTIVE flags in statusTasks to READY
        IndexActive=find(project.pipeline.statusTask==1);
        if(~isempty(IndexActive))
             project.pipeline.statusTask(IndexActive)=0;%Active=1, Ready=0;
             %Loginfo
             project=logProject('Reset active tasks',project,TaskIndex,MethodIndex)
        end

        
        %Log info
        msg=sprintf('Systemdir:''%s'', Main workspace:''%s'' ',project.sysinfo.systemdir,project.sysinfo.mainworkspace);           
        project=logProject(msg,project,TaskIndex,MethodIndex); 
        
        %_______ RESTORE project...something has happend
        %if(length(project.taskDone{TaskIndex}.error))
        %    warndlg('Error: Restore old project','Load project')
        %    project=RESTORE_project;
        %    project=logProject('Error: Restore oldproject',project,TaskIndex,MethodIndex);
        %end
        
    otherwise
        project=logProject('Unknown command',project,TaskIndex,MethodIndex);
        return
    end
    
%     ChekcOut: Restore status of tasks 
%     project.pipeline.statusTask(TaskIndex)=tmpstatusTask;  
%     Removed 10/06/2004 by Rask
else
    %_______ New project, MainGUI do not exist or is initialising    
    
    if(isstr(project))%String for setup file
        %___ Check if Pipeline program already exist
        if (findobj('tag','mainGUI'))
            msgbox('The Pipeline Program is already running');
            return
        end
        
        %_____ Init variables        
        UsePipeline=project;             
        
        %_____ Setup Matlab path and workspace for new project
        [setupPath,setupFilename,setupExt]=fileparts(UsePipeline);
        
        %Check if setupfile exist and add to Matlab path else return       
        if(~exist(setupFilename)==2)            
            disp('Setup file for pipeline do NOT exist in Matlab path...');
            return
        end       
        
        %___ Remove and check for redundance system files from Matlab path
        fileInfo=fileVersion([],'setupPipeline.m','SW version');       
        for(i=1:length(fileInfo)) %NOTE possible to check if more files or versions of the Pipeline program exist in matlabpath                
            %Get all sub directories to current system dir
            subDir=genpath(fileInfo{i}.path);
            if(isunix)%OS difference
                q=strfind(subDir,':'); 
            else
                q=strfind(subDir,';'); 
            end
            qI=1;
            for(i=1:length(q))%Remove also all subdir
                test{i}=subDir(qI:q(i)-1);    
                qI=q(i)+1;
                %ONLY FOR TEST             test{i}
                %ONLY FOR TEST             exist(test{i})
                %if(exist(test{i})==7 & ~isempty(strfind(test{i},path)))
                %    rmpath(test{i}); %Clean-up Matlab path for old paths
                %end
                pip_cleanMatlabpath(test{i})
            end
        end
        
        %____ Setup new Matlab path (Add system files and subdir to Matlab path)
        tmp_workspace=[];
        subDir=genpath(fileInfo{1}.path);
        if(isunix)%OS difference
            q=strfind(subDir,':'); 
        else
            q=strfind(subDir,';'); 
        end
        qI=1;        
        addpath(subDir(qI:q(1)-1),'-begin');%First dir is system which is not removed on exit
        qI=q(1)+1;;
        for(i=2:length(q))
            tmp_workspace{end+1}=subDir(qI:q(i)-1);%Directories to be removed on exist           
            addpath(tmp_workspace{end},'-begin');
            qI=q(i)+1;
        end
        
        %Setup new project
        project=setupProject(0,UsePipeline);
        
        %Add sysinfo to project
        project.sysinfo.systemdir=fileInfo{1}.path;
        project.sysinfo.version=fileInfo{1}.version;
        project.sysinfo.systemfile=fileInfo{1}.filename;
        project.sysinfo.os=fileInfo{1}.os;
        project.sysinfo.tmp_workspace=tmp_workspace;
        % Current directory is states as mainworkspace where new project is placed as subdir
        project.sysinfo.mainworkspace=pwd;

        
        
        %Log info
        [NoTasks,NoMethods]=size(project.pipeline.taskSetup);
        msg=sprintf('Paths: systemdir:%s, main workspace: %s',project.sysinfo.systemdir,project.sysinfo.mainworkspace);           
        project=logProject(msg,project,NoTasks,1); 
        
        project=logProject('New project NO or initialisation mainGUI',project,NoTasks,1); 
        TaskIndex=[];
    else
        project=logProject('Unknown input parameter',project,TaskIndex,MethodIndex);
        return
    end
end


%_______ Create/update mainGUI,always use first task as default
project=mainGUI(project,1);


%_________ Check if programfiles for each method exist and SW version
[NoTasks,NoMethods]=size(project.pipeline.taskSetup);
drawnow;

project=logProject(sprintf('-------------------- NEW PROJECT --------------------'),project,NoTasks,1); 
for(i=1:NoTasks)
    %__________ Entry tasks structure
    for(ii=1:NoMethods)
        if(~length(project.pipeline.taskSetup{i,ii}))%If empty method
            continue;
        end
        %project.pipeline.taskSetup{i,ii}=fileVersion(project.pipeline.taskSetup{i,ii});  %Removed by TR120104 - Does no good as project is not saved hereafter...
        if(project.pipeline.taskSetup{i,ii}.filesexist==1)
            project=logProject(sprintf('LoadProject: programfile -> %s, OK!',project.pipeline.taskSetup{i,ii}.function_wrapper),project,i,ii); 
        else
            project=logProject(sprintf('LoadProject: programfile -> %s, FAILED!',project.pipeline.taskSetup{i,ii}.function_wrapper),project,i,ii); 
        end
    end
end
project=pip_createProject(project,1,1,1);








