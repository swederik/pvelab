function project=RunBatch(project,TaskIndex,MethodIndex)
global PETpath T1Wpath T2Wpath PDWpath ROIpath flg
flg=[];
ROIpath=[];

oldp=project;
project=logProject('Select a template',project,TaskIndex,MethodIndex); 
% User select project to load
[temName,temPath]=uigetfile('*.tem','Select a template project');    

% Check if a file is selected
if(temName==0)
    project=logProject('No template selected',project,TaskIndex,MethodIndex); 
    return
else
    [~,~,file_ext] = fileparts(temName);
    % Check if the loadede file is a project using the extension
    if(~strcmp(file_ext,'.tem'))
        msg='Selected file is not a project';
        ansawer=errordlg(msg,'Select template project'); %   
        project=logProject(msg,project,TaskIndex,MethodIndex); 
        return
    end 
end%

%load template
template=load(fullfile('',temPath,temName),'-MAT');
NumberMR=1;
if template.template.pipeline.userPipeline(1)==1
    project=logProject('1 MR per study',project,TaskIndex,MethodIndex);
else
    NumberMR=3;
    project=logProject('3 MR per study',project,TaskIndex,MethodIndex);
end    

project=logProject('Select a study list file',project,TaskIndex,MethodIndex); 

[lstName,lstPath]=uigetfile('*.txt','Select a study list file');    
lst=fullfile(lstPath,lstName);

a=textread(lst,'%s','delimiter',';');

PETS=a(1:(1+NumberMR):end)';
T1WS=a(2:(1+NumberMR):end)';
T2WS=a(NumberMR:(1+NumberMR):end)';
PDWS=a(1+NumberMR:(1+NumberMR):end)';

for i=1:length(PETS)
    project=logProject(['Running analysis ',num2str(i)],project,TaskIndex,MethodIndex); 
    project=RunPrjFromTemplate(temName,temPath,project,TaskIndex,MethodIndex,cell2mat(PETS(i)),cell2mat(T1WS(i)),cell2mat(T2WS(i)),cell2mat(PDWS(i)));
end
project=mainGUI(oldp,1);



function project=RunPrjFromTemplate(temName,temPath,project,TaskIndex,MethodIndex,fullPETpath,fullT1Wpath,fullT2Wpath,fullPDWpath)

StartDir=pwd;

% Load template
project=logProject('Load template',project,TaskIndex,MethodIndex); 

% Check if a file is selected
if(temName==0)
    project=logProject('No template loaded',project,TaskIndex,MethodIndex); 
    return
else
    [~,~,file_ext] = fileparts(temName);
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
fileInfo=fileVersion([],'setupPipeline.m','SW version');
project.sysinfo.systemdir=fileInfo{1}.path;    
project.sysinfo.version=fileInfo{1}.version;
project.sysinfo.systemfile=fileInfo{1}.filename;
project.sysinfo.os=fileInfo{1}.os;

global PETpath T1Wpath T2Wpath PDWpath ROIpath

startstep=1;

if project.pipeline.userPipeline(2)==3 % SPM Coregistration...
    project.pipeline.taskSetup{2,3}.method_name='SpmCoregAuto_wrapper';
    project.pipeline.taskSetup{2,3}.function_name='SpmCoregAuto_wrapper';
    project.pipeline.taskSetup{2,3}.function_wrapper='SpmCoregAuto_wrapper';
end

if project.pipeline.userPipeline(2)==5 % Load AIR file...
    project.pipeline.taskSetup{2,5}.method_name='loadRegAuto_wrapper';
    project.pipeline.taskSetup{2,5}.function_name='loadRegAuto_wrapper';
    project.pipeline.taskSetup{2,5}.function_wrapper='loadRegAuto_wrapper';
end

if project.pipeline.userPipeline(3)==4 % Load Segmented...
    project.pipeline.taskSetup{3,4}.method_name='loadSegAuto_wrapper';
    project.pipeline.taskSetup{3,4}.function_name='loadSegAuto_wrapper';
    project.pipeline.taskSetup{3,4}.function_wrapper='loadSegAuto_wrapper';
end

if project.pipeline.userPipeline(4)==6 % Load All Coregistered...
    startstep=4;
    project.pipeline.taskSetup{4,6}.method_name='loadAllAuto_wrapper';
    project.pipeline.taskSetup{4,6}.function_name='loadAllAuto_wrapper';
    project.pipeline.taskSetup{4,6}.function_wrapper='loadAllAuto_wrapper';
end

if project.pipeline.userPipeline(5)==4 % Load GMROI...
    if isempty(ROIpath)
        project=logProject('Select a ROI code file',project,TaskIndex,MethodIndex); 
        [rName,rPath]=uigetfile('*.dat;*.DAT','Select a ROI code file');
        ROIpath=fullfile(rPath,rName);
    end
    startstep=5;
    project.pipeline.taskSetup{5,4}.method_name='loadGMROIAuto_wrapper';
    project.pipeline.taskSetup{5,4}.function_name='loadGMROIAuto_wrapper';
    project.pipeline.taskSetup{5,4}.function_wrapper='loadGMROIAuto_wrapper';
end

project.pipeline.taskSetup{1,1}.method='Load 1 PET + 1 MR';
project.pipeline.taskSetup{1,1}.method_name='FileLoad1MRAuto_wrapper';
project.pipeline.taskSetup{1,1}.function_name='FileLoad1MRAuto_wrapper';
project.pipeline.taskSetup{1,1}.function_wrapper='FileLoad1MRAuto_wrapper';

project.pipeline.taskSetup{1,2}.method='Load 1 PET + 3 MR';
project.pipeline.taskSetup{1,2}.method_name='FileLoad3MRAuto_wrapper';
project.pipeline.taskSetup{1,2}.function_name='FileLoad3MRAuto_wrapper';
project.pipeline.taskSetup{1,2}.function_wrapper='FileLoad3MRAuto_wrapper';

PETpath=fullPETpath;
T1Wpath=fullT1Wpath;
T2Wpath=fullT2Wpath;
PDWpath=fullPDWpath;

if startstep>1
    %_______ Get filenames 
    [file_pathstr,file_name,file_ext] = fileparts(PETpath);
    project.taskDone{1}.outputfiles{1,1}.name=[file_name,file_ext];    
    project.taskDone{1}.outputfiles{1,1}.path=file_pathstr;
    
    [file_pathstr,file_name,file_ext] = fileparts(T1Wpath);
    project.taskDone{1}.outputfiles{1,2}.name=[file_name,file_ext];    
    project.taskDone{1}.outputfiles{1,2}.path=file_pathstr;
    
    %_____ Create project if it does not exist
    project=pip_createProject(project,1,1,0);
end

for TaskIndex=startstep:7
    MethodIndex=project.pipeline.userPipeline(TaskIndex);
    project=main_wrapper(project,TaskIndex,MethodIndex);
end

cd(StartDir);

return
