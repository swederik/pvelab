function project=loadGMROI_nogui(project,TaskIndex,MethodIndex,varargin)
% This method is called by the pipeline program.
% It loads three segmented files into the project structure.
% It checks if the loaded files are the same size and dimension and if they
% are coregistered to the PET.
%
% By Thomas Rask 140104, NRU
% Modified by Marco Comerci 11112005, IBB - CNR
%

%______ Initialise
%__________ Image information
project.pipeline.imageModality={'PET','T1-W'}; %Name and order of image modalities to be loaded
noModalities=length(project.pipeline.imageModality);
project.pipeline.imageIndex=1; %(FOR FUTURE USE) Number of loaded different images
ImageIndex=1; %(FOR FUTURE USE) Number of loaded different images

if exist('spm','file')==2
    if ~strcmpi(spm('Ver'),'spm8')
        global defaults
        spm_defaults;
        flip=defaults.analyze.flip;
    end
end

%______ Load 'commands' of structural information
project.taskDone{TaskIndex}.command=project.pipeline.imageModality;

project.taskDone{1}.inputfiles{1,1}.name='Untitled';
project.taskDone{1}.inputfiles{1,2}.name='Untitled';

project.taskDone{1}.outputfiles{1,1}.name='Untitled';
project.taskDone{1}.outputfiles{1,2}.name='Untitled';

project.taskDone{1}.inputfiles{1,1}.path='';
project.taskDone{1}.inputfiles{1,2}.path='';

project.taskDone{1}.outputfiles{1,1}.path='';
project.taskDone{1}.outputfiles{1,2}.path='';

project.taskDone{1}.inputfiles{1,1}.info='';
project.taskDone{1}.inputfiles{1,2}.info='';

project.taskDone{1}.outputfiles{1,1}.info='';
project.taskDone{1}.outputfiles{1,2}.info='';

if strcmp(project.sysinfo.prjfile,'')
    project=checkOut(project,TaskIndex,MethodIndex,varargin);
end

% project.taskDone{TaskIndex}.userdata.map.path=pathout;
% project.taskDone{TaskIndex}.userdata.map.name=[Name,EXT];
% project.taskDone{TaskIndex}.userdata.map.info='ROI file';
% project.taskDone{TaskIndex}.userdata.sn.path=pathout;
% project.taskDone{TaskIndex}.userdata.sn.name='sn.mat';
% project.taskDone{TaskIndex}.userdata.sn.info='Normalization parameters file';

project.taskDone{1}.inputfiles{ImageIndex,1}=project.taskDone{TaskIndex}.outputfiles{ImageIndex,1};
project.taskDone{1}.inputfiles{ImageIndex,2}=project.taskDone{TaskIndex}.outputfiles{ImageIndex,2};

project.taskDone{TaskIndex}.inputfiles{ImageIndex,1}=project.taskDone{TaskIndex}.outputfiles{ImageIndex,1};
project.taskDone{TaskIndex}.inputfiles{ImageIndex,2}=project.taskDone{TaskIndex}.outputfiles{ImageIndex,2};

project.taskDone{TaskIndex}.show{1,1}.name='r_volume_GMROI.img';
project.taskDone{TaskIndex}.show{1,1}.path=project.sysinfo.workspace;
project.taskDone{TaskIndex}.show{1,1}.info='Labeled segmented image';

project.taskDone{1}.outputfiles{ImageIndex,1}=project.taskDone{TaskIndex}.outputfiles{ImageIndex,1};
project.taskDone{1}.outputfiles{ImageIndex,2}=project.taskDone{TaskIndex}.outputfiles{ImageIndex,2};