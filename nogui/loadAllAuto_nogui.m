function project=loadAllAuto_nogui(project,TaskIndex,MethodIndex,varargin)
% This method is called by the pipeline program.
% It loads three segmented files and a PET file into the project structure.
% It checks if the loaded files are the same size and dimension and if they
% are coregistered.
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

flip=1;
addendum='';
if exist('spm','file')==2
    if ~strcmpi(spm('Ver'),'spm8')
        spm_defaults;
        flip=defaults.analyze.flip;
    end
end

if flip==0
    addendum=' -s';
end

if strcmp(project.sysinfo.prjfile,'')
    project=checkOut(project,TaskIndex,MethodIndex,varargin);
end

global PETpath T1Wpath


project.taskDone{TaskIndex}.userdata.segoutReslice{1}.info='Coregistered segmented Gray Matter';
project.taskDone{TaskIndex}.userdata.segoutReslice{2}.info='Coregistered segmented White Matter';
project.taskDone{TaskIndex}.userdata.segoutReslice{3}.info='Coregistered segmented CSF';
project.taskDone{TaskIndex}.outputfiles{ImageIndex,1}.path=project.sysinfo.workspace;
project.taskDone{TaskIndex}.outputfiles{ImageIndex,1}.name=project.taskDone{1}.outputfiles{1}.name;
project.taskDone{TaskIndex}.outputfiles{ImageIndex,1}.info='PET file';
project.taskDone{TaskIndex}.outputfiles{ImageIndex,2}.path=project.sysinfo.workspace;
project.taskDone{TaskIndex}.outputfiles{ImageIndex,2}.name=project.taskDone{1}.outputfiles{2}.name;
project.taskDone{TaskIndex}.outputfiles{ImageIndex,2}.info='T1W file';

project.taskDone{1}.inputfiles{ImageIndex,1}=project.taskDone{TaskIndex}.outputfiles{ImageIndex,1};
project.taskDone{1}.inputfiles{ImageIndex,2}=project.taskDone{TaskIndex}.outputfiles{ImageIndex,2};

project.taskDone{TaskIndex}.inputfiles{ImageIndex,1}=project.taskDone{TaskIndex}.outputfiles{ImageIndex,1};
project.taskDone{TaskIndex}.inputfiles{ImageIndex,2}=project.taskDone{TaskIndex}.outputfiles{ImageIndex,2};

project.taskDone{1}.outputfiles{ImageIndex,1}=project.taskDone{TaskIndex}.outputfiles{ImageIndex,1};
project.taskDone{1}.outputfiles{ImageIndex,2}=project.taskDone{TaskIndex}.outputfiles{ImageIndex,2};
