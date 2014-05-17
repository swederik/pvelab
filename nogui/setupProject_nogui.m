function project=setupProject_nogui(handles,UsePipeline,varargin)
% setupProject function initialise a project in the pipeline program w. settings given 
%  in the setupfile.
%
% Input:
%   handles     : If GUI is initialized handles can be given w. field names as in 'project.handles'
%   Usepipeline : Path and name to the setup file (*.m)
%   varargin    : Abitrary number of input arguments. (NOT USED)
%
% Output:
%   project     : Return new project       
%
% Uses special functions:
%
%____________________________________________
% T. Dyrby, 120303, NRU
%SW version: 100903TD

% TO DO:
% - OK 100903TD: Fix so to add new menus given in the user setupfile. New menus will be placed in the 'Tool'-menu

%__________ Setup pipeline-entry
pipeline_ProjectTitleName=[];
pipeline_ProjectPrefix=[];
%_____ Load user setupfile for new pipeline 
fid = fopen(UsePipeline, 'rt');
Stop=0;
while (Stop==0)
    tline = fgetl(fid);
    if ischar(tline)
        eval(tline);
    else
        Stop=1;
    end
end
fclose(fid);%close user setupfile

%_____ Get number of tasks made by the setup file
[TaskIndex,MethodIndex]=size(pipeline.taskSetup);

%Check if task 'Others' exist
if(~strcmpi(pipeline.taskSetup{TaskIndex,1}.task,'others'));
    TaskIndex=TaskIndex+1;
    MethodIndex=1;
else    
    for(i=1:MethodIndex)
        if(isempty(pipeline.taskSetup{TaskIndex,i}))
            MethodIndex=i;
            break
        end
        if(i==MethodIndex)            
            MethodIndex=i+1;
        end
    end    
end

%_____ Load setupfile for The Pipeline Program
fid = fopen('setupPipeline.ini', 'rt');
Stop=0;
while (Stop==0)
    tline = fgetl(fid);
    if ischar(tline)
        eval(tline);
    else
        Stop=1;
    end
end
fclose(fid);%close The Pipeline Program setup file

%Below: Last task in the project.pipeline: Setup the wrapper for PVE Lab

[pipPath,pipName,pipExt]=fileparts(UsePipeline);
tmpTask.task='PipelineProgram';
tmpTask.function_name='';
         
if(~isempty(pipeline_ProjectTitleName))    
    tmpTask.method_name=pipeline_ProjectTitleName;
else
    tmpTask.method_name=pipName;
end
tmpTask.method=pipName;
tmpTask.description='';
tmpTask.require_taskindex{1}=[];%[]=no tasks has to be done
tmpTask.function_wrapper='main_nogui';

if(~isempty(pipeline_ProjectPrefix))
    tmpTask.prefix=pipeline_ProjectPrefix;
else
    tmpTask.prefix='';
end
tmpTask.documentation='file:/PipelineProgramDescription.pdf';
tmpTask.who_did='Tim Dyrby, NRU, 2003';
tmpTask.configurator_wrapper='';
tmpTask.configurator.default='';
tmpTask.configurator.user='';
tmpTask.configurator.configurator_name=[pipName,pipExt];%Do not use path to be OS independent
tmpTask.versionlabel='SW version';
pipeline.taskSetup{end+1,1}=tmpTask;

%NOTE: maby a problem if path do not exist...But then avoid OS problems!!!!!250803TD
pipeline.taskSetup{end,1}.configurator.configurator_name=UsePipeline;

pipeline.lastTaskIndex=[]; % Which TaskIndex was before

%Check if functions for each method exist and search for SW version
[NoTasks,NoMethods]=size(pipeline.taskSetup);
project.pipeline.taskSetup=pipeline.taskSetup;
project.sysinfo.logfile.tmp=[];
for i=1:NoTasks
    %__________ Entry tasks structure
    taskDone{i}=''; % Is empty cell array at the beginning
    
    for ii=1:NoMethods
        if isempty(pipeline.taskSetup{i,ii})%If empty method
            continue;
        end
        pipeline.taskSetup{i,ii}=fileVersion(pipeline.taskSetup{i,ii});       
%         if(pipeline.taskSetup{i,ii}.filesexist==1)
%            project=logProject(sprintf('ProjectSetup: programfile->%s, OK!',pipeline.taskSetup{i,ii}.function_wrapper),project,i,ii); 
%         else
%            project=logProject(sprintf('ProjectSetup: programfile->%s, FAILED!',pipeline.taskSetup{i,ii}.function_wrapper),project,i,ii); 
%         end
    end
end

%____ Setup default pipeline if not already done
if(~isfield(pipeline,'defaultPipeline') || isempty(pipeline.defaultPipeline) || length(pipeline.defaultPipeline)~=(NoTasks-2))
    %No default pipeline exist use first method as default
    pipeline.defaultPipeline=ones(1,NoTasks);
end

pipeline.userPipeline=pipeline.defaultPipeline;
pipeline.statusTask=zeros(1,NoTasks);%0:Ready, 1=Active, 3=Done
pipeline.lastTaskIndex=0;

%__________ Setup sysinfo-entry
project.sysinfo.systemdir='';%pipeline.taskSetup{end,1}.filestatus{1}.path;
project.sysinfo.version='';%pipeline.taskSetup{end,1}.filestatus{1}.version;
project.sysinfo.prjfile='';% Is defined when files are loaded
project.sysinfo.workspace='';% Is defined when files are loaded
project.sysinfo.logfile.name='';% Is defined when files are loaded
project.sysinfo.systemfile='';%File used to check the pipeline program
project.sysinfo.os='';% Which OS project is defined for
project.sysinfo.tmp_workspace='';% Workspaces added to matlab path which are removed when leaving the program
project.sysinfo.mainworkspace='';% Workspaces where workspaceses are placed for each new project

%__________ Collect project structure
project.pipeline=pipeline;
project.taskDone=taskDone;
project.handles=[];