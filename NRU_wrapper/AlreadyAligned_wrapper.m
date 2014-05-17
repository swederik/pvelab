function project=AlreadyAligned_wrapper(project,TaskIndex,MethodIndex,varargin);
% AlreadyAligned_wrapper is launched by the pipeline program when the method is
% run under the registration task. Its purpose is to create an air file that
% corresponds to two volume that already have been aligned, either having same
% voxel and volume size, orhaving e.g. double voxel size and half volume size
%
% SW version 110712CS
%

ImageIndex=1;

%_________ Check if all parameters are defined
userConfig=project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.default;
if ~isfield(userConfig,'to')
    userConfig.to=1;
end
project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.default=userConfig;


%_________________________ Initialise file load ________________________
    
% How many modalities exist for given brain image...
ImageIndex=project.pipeline.imageIndex(1); %One image always exist, and right now only of one subject...
   
%______ Load input files given in project and save them as output files w. prefix if prefix exists...
project.taskDone{TaskIndex}.inputfiles{ImageIndex,1}.path=project.taskDone{1}.outputfiles{ImageIndex,1}.path; %PET
project.taskDone{TaskIndex}.inputfiles{ImageIndex,1}.name=project.taskDone{1}.outputfiles{ImageIndex,1}.name;
   
project.taskDone{TaskIndex}.inputfiles{ImageIndex,2}.path=project.taskDone{1}.outputfiles{ImageIndex,2}.path; %MR
project.taskDone{TaskIndex}.inputfiles{ImageIndex,2}.name=project.taskDone{1}.outputfiles{ImageIndex,2}.name;
   
sourceFile1=fullfile('',project.taskDone{TaskIndex}.inputfiles{ImageIndex,1}.path,project.taskDone{TaskIndex}.inputfiles{ImageIndex,1}.name);
sourceFile2=fullfile('',project.taskDone{TaskIndex}.inputfiles{ImageIndex,2}.path,project.taskDone{TaskIndex}.inputfiles{ImageIndex,2}.name);

[img1,hdr1]=ReadAnalyzeImg(sourceFile1);
[img2,hdr2]=ReadAnalyzeImg(sourceFile2);

vol1siz=hdr1.siz(1:3).*hdr1.dim(1:3);
vol2siz=hdr2.siz(1:3).*hdr2.dim(1:3);

if any(abs(vol1siz-vol2siz)>1e-2)     % Differences in volumes method can not be used, has to be aligned
    msg='Error: Different volume size between the two loaded volumes, use another co-reg method.';
    project=logProject(msg,project,TaskIndex,MethodIndex);
    project.taskDone{TaskIndex}.error{end+1}=msg;
    return;
end

if userConfig.to==1    % to PET  
    [pn,fn,ext]=fileparts(sourceFile1);
    AIRfile=fullfile(project.sysinfo.workspace,[fn '.air']);

    CreateUnityAIRDiffRes(sourceFile1,sourceFile2,AIRfile);
else                   % to MRI
    [pn,fn,ext]=fileparts(sourceFile2);
    AIRfile=fullfile(project.sysinfo.workspace,[fn '.air']);

    CreateUnityAIRDiffRes(sourceFile2,sourceFile1,AIRfile);
end

[pn,fn,ext]=fileparts(AIRfile);
project=logProject(['The following AIR file have been created: ',fn,'.air'],project,TaskIndex,MethodIndex);    
project.taskDone{TaskIndex}.userdata.AIRfile{ImageIndex,1}.path=project.sysinfo.workspace;
project.taskDone{TaskIndex}.userdata.AIRfile{ImageIndex,1}.name=[fn,'.air'];
