function project=RunPrjFromTemplate_nogui(project,TaskIndex,MethodIndex,fullPETpath,fullT1Wpath,fullT2Wpath,fullPDWpath, gm, wm, csf, rois, dat)

StartDir=pwd;
template_file = 'SegSkipAtlas.tem';

% Load template
project=logProject('Load template',project,TaskIndex,MethodIndex); 

% Check if a file is selected
if(template_file==0)
    project=logProject('No template loaded',project,TaskIndex,MethodIndex); 
    return
else
    [~,~,file_ext] = fileparts(template_file);
    % Check if the loadede file is a project using the extension
    if(~strcmp(file_ext,'.tem'))
        msg='Selected file is not a project';
        project=logProject(msg,project,TaskIndex,MethodIndex); 
        return
    end 
end%

%load template
template=load(template_file,'-MAT'); 

%______Make new project        
% Load same configuration of pipeline given i project
%UsePipeline=fullfile('',project.pipeline.taskSetup{end,1}.configuratorfile.path,project.pipeline.taskSetup{end,1}.configuratorfile.name);

%NOTE: maby a problem if path do not exist...But then avoid OS problems!!!!!250803TD
RESTORE_project=project;

UsePipeline=project.pipeline.taskSetup{end,1}.configurator.configurator_name;
project=setupProject_nogui(project.handles,UsePipeline);         
project.handles.h_mainfig = 'n';

% Setup project as given in the template
project.pipeline.taskSetup=template.template.pipeline.taskSetup;
project.pipeline.userPipeline = [1 6 4 6 4 1 1];

% Enables all PVE correction methods
project.pipeline.taskSetup{6}.configurator.user{7} = 255 
%project.pipeline.userPipeline=template.template.pipeline.userPipeline;

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
    project.pipeline.taskSetup{3,4}.method_name='loadSeg_nogui';
    project.pipeline.taskSetup{3,4}.function_name='loadSeg_nogui';
    project.pipeline.taskSetup{3,4}.function_wrapper='loadSeg_nogui';
end

if project.pipeline.userPipeline(4)==6 % Load All Coregistered...
    startstep=4;
    project.pipeline.taskSetup{4,6}.method_name='loadAllAuto_nogui';
    project.pipeline.taskSetup{4,6}.function_name='loadAllAuto_nogui';
    project.pipeline.taskSetup{4,6}.function_wrapper='loadAllAuto_nogui';
end

if project.pipeline.userPipeline(5)==4 % Load GMROI...
    ROIpath=rois;
    startstep=5;
    project.pipeline.taskSetup{5,4}.method_name='loadGMROI_nogui';
    project.pipeline.taskSetup{5,4}.function_name='loadGMROI_nogui';
    project.pipeline.taskSetup{5,4}.function_wrapper='loadGMROI_nogui';
end

if project.pipeline.userPipeline(6)==1 % PVE
    project.pipeline.taskSetup{6,1}.method_name='PVE_nogui';
    project.pipeline.taskSetup{6,1}.function_name='PVE_nogui';
    project.pipeline.taskSetup{6,1}.function_wrapper='PVE_nogui';
end

if project.pipeline.userPipeline(7)==1 % Extract Data
    project.pipeline.taskSetup{7,1}.method_name='extract_nogui';
    project.pipeline.taskSetup{7,1}.function_name='extract_nogui';
    project.pipeline.taskSetup{7,1}.function_wrapper='extract_nogui';
    project.pipeline.taskSetup{7,1}.require_taskindex{4} = [];
    project.pipeline.taskSetup{7,1}.require_taskindex{6} = [1];
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
startstep = 1;
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

project.pipeline.userPipeline
for TaskIndex=startstep:6
    TaskIndex
    MethodIndex=project.pipeline.userPipeline(TaskIndex);
    project=main_nogui(project,TaskIndex,MethodIndex);
    if TaskIndex == 3 % Loading segmentation files
        % GM
        [gmpath,gmname,gmext] = fileparts(gm);
        project.taskDone{3}.userdata.segout{1}.path = gmpath;
        project.taskDone{3}.userdata.segout{1}.name = [gmname gmext];        
        % WM
        [wmpath,wmname,wmext] = fileparts(wm);
        project.taskDone{3}.userdata.segout{2}.path = wmpath;
        project.taskDone{3}.userdata.segout{2}.name = [wmname wmext];
        % CSF
        [csfpath,csfname,csfext] = fileparts(csf);
        project.taskDone{3}.userdata.segout{3}.path = csfpath;
        project.taskDone{3}.userdata.segout{3}.name = [csfname csfext];
    elseif TaskIndex == 4 % Already aligned
        % GM
        [gmpath,gmname,gmext] = fileparts(gm);
        project.taskDone{3}.userdata.segoutReslice{1}.path = gmpath;
        project.taskDone{3}.userdata.segoutReslice{1}.name = [gmname gmext];        
        % WM
        [wmpath,wmname,wmext] = fileparts(wm);
        project.taskDone{3}.userdata.segoutReslice{2}.path = wmpath;
        project.taskDone{3}.userdata.segoutReslice{2}.name = [wmname wmext];
        % CSF
        [csfpath,csfname,csfext] = fileparts(csf);
        project.taskDone{3}.userdata.segoutReslice{3}.path = csfpath;
        project.taskDone{3}.userdata.segoutReslice{3}.name = [csfname csfext];
    elseif TaskIndex == 5 % Loading GM ROI file
        [roipath,roiname,roiext] = fileparts(rois);
        project.taskDone{TaskIndex}.userdata.atlas.path=roipath;
        project.taskDone{TaskIndex}.userdata.atlas.name= [roiname roiext];
        project.taskDone{TaskIndex}.userdata.atlas.info='GMROI file';
        
        [datpath,datname,datext] = fileparts(dat);
        project.taskDone{TaskIndex}.userdata.roi.path=datpath;
        project.taskDone{TaskIndex}.userdata.roi.name= [datname datext];
        project.taskDone{TaskIndex}.userdata.roi.info='ROI Data file';
    end
end
project.taskDone
cd(StartDir);

return
