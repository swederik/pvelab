function project=registrate_wrapper(project,TaskIndex,MethodIndex,varargin)
% function_wrapper for the two registration methods: IIO_method and IPS_method
%
% Co-registrate: project.pipeline.imageModality{1,2} --> project.pipeline.imageModality{1,1}
%
% ------NOTE>>>> GLOBAL settings: ENABLE_HACKS=1; %Problem w. overlay in Matlab
% ------NOTE>>>> GLOBAL settings: TEMP_AREA='/tmp_data'; %Temp space
% ------NOTE>>>> GLOBAL settings: NRU_FORMAT=1;; %AIR file in NRU format
% ------NOTE>>>> GLOBAL settings: DEF_ENDIAN='ieee-be'; %Define of endian
%
% AIR file info for each modality are saved
%   in project.taskDone{TaskIndex}.userdata.AIRfile{ImageIndex,ModalityIndex}
%   field is empty if no co-registration matrix exist.
%
% Input:
%   project: Structure for actual PVE correction process
%   TaskIndex: Index in the project-structure for actual task
%   MethodIndex: Index in the project-structure for actual method
%   varargin: Extra input arguments, not used
%
% Outout:
%   project: structure for actual PVE correction process
%____________________________________________
%By T. Dyrby, 170303, NRU
%SW version: 060903TD. By T. Dyrby, 170303, NRU

%ToDOnDone
% -OK 260803TD: Check if coregistration exist is made
% - 270803TD: Add SPM, To DO: Change SPM so coregistration is saved as in IIO and IPS
% - 270803TD: Add AIR, To DO:Change SPM so coregistration is saved as in IIO and IPS
% - OK 060903TD: Switch order of PET and MR...agrement between NRU and IBB (Marco,Italy)

%_______ Check if registration function is returning data...
if(~isstruct(project))
    % No project structure is given!!    
    uiresume
     return
end%
%////////////////////////////////////////////////////////////////
% Global settings of PVEOut coregistration package

% Enable workaround for matlab6 surface overlay problem:
global ENABLE_HACKS;
ENABLE_HACKS=1;

% Control writing of NRU or standard .air files:
%
% Possible values: 0/1
%
% CAUTION: If used with unpatched air package, should be set to 0.
% Also affects reslicing using programs provided by air package
%
global NRU_FORMAT;
% Globally used temporary area:
global TEMP_AREA;
NRUsys=getenv('NRU');
if (isempty(NRUsys) | str2num(NRUsys)==0)
  NRU_FORMAT=0;
  TEMP_AREA=tempdir;
else
  NRU_FORMAT=1;
  TEMP_AREA='/tmp_data';
end  

%////////////////////////////////////////////////////////////////


%_______ Add to project: AIR file where to store registration matrix
%define a AIRfilew field for each modality
[ImageIndex,ModalityIndex]=size(project.taskDone{TaskIndex}.inputfiles);
project.taskDone{TaskIndex}.userdata.AIRfile{ImageIndex,ModalityIndex}=[];

%Define transformation direction
Direction=1; %PET->MR (1) or MR->PET (2)

%Name AIR file as resliced image
name=project.taskDone{TaskIndex}.inputfiles{1,Direction}.name;
[tmp,AIRfile,extAIR]=fileparts(name);

project.taskDone{TaskIndex}.userdata.AIRfile{1,Direction}.name=[AIRfile,'.air'];
project.taskDone{TaskIndex}.userdata.AIRfile{1,Direction}.path=project.sysinfo.workspace;%Save in workspace

%_______ Update project in mainFig
set(project.handles.h_mainfig,'UserData',project)

%_______ Init matrix to Co-registration methods defined in header of functions
%Log info
msg=sprintf('Registrate: %s --> %s',project.pipeline.imageModality{1,1},project.pipeline.imageModality{1,2});
project=logProject(msg,project,TaskIndex,MethodIndex);

%Image fixed typical MR
name=project.taskDone{TaskIndex}.inputfiles{1,2}.name;
path=project.taskDone{TaskIndex}.inputfiles{1,2}.path;
files.STD=fullfile('',path,name);

%Image to be co-registrated typical PET/SPECT
name=project.taskDone{TaskIndex}.inputfiles{1,1}.name;
path=project.taskDone{TaskIndex}.inputfiles{1,1}.path;
files.RES{1}=fullfile('',path,name);


name=project.taskDone{TaskIndex}.userdata.AIRfile{1,Direction}.name;
path=project.taskDone{TaskIndex}.userdata.AIRfile{1,Direction}.path;
files.AIR=fullfile('',path,name);

%_______ Possible to load a default registration matrix
files.A{1}=eye(4,4);% Initial registration matrix


%_______ Call registration method
parent=project.handles.h_mainfig;% Parent handle
ReturnFcn=project.pipeline.taskSetup{TaskIndex,MethodIndex}.function_wrapper;% Where to return afterwards
visualizer='nruinspect';% Which method to browse:Could be in a configurator...
Config=project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.default;%Get set up


switch(project.pipeline.taskSetup{TaskIndex,MethodIndex}.method)
case {'IPS','IIO'}
    %_______ Get handle to registration method only used for UIWAIT
    h_registration=feval(project.pipeline.taskSetup{TaskIndex,MethodIndex}.function_name);
    
    feval(project.pipeline.taskSetup{TaskIndex,MethodIndex}.function_name,Config,h_registration,files,parent,ReturnFcn,visualizer);
    %Coreg('Batch',h,files,parent,ReturnFcn,,visualizer);
    % OR
    %Registrate('Batch',h,files,parent,ReturnFcn,visualizer);
    % OR
case{'AIR'}    
       
    %______________Select frames to register if PET is dynamic_____________
    %MR->PET
    substi='';
    PEThdr=ReadAnalyzeHdr(files.RES{1});
    if length(PEThdr.dim)>3 & PEThdr.dim>1
        [petimg,pethdr]=LoadAnalyze(files.RES{1},'single');
        if isempty(petimg)
            msg='User abort, cancel pressed.';
            project=logProject(msg,project,TaskIndex,MethodIndex);
            project.taskDone{TaskIndex}.error{end+1}=msg;
            return
        end
        [tmp,Name]=fileparts(project.taskDone{TaskIndex}.inputfiles{1,1}.name);
        pethdr.name=[Name,'_3D'];
        pethdr.path=project.sysinfo.workspace;
        pethdr.origin=PEThdr.origin;
        pethdr.scale=PEThdr.scale;
        pethdr.offset=PEThdr.offset;

        project=logProject(['Writing selected frames to temp-file: ',pethdr.name,'.img'],project,TaskIndex,MethodIndex);
        
        noprob=WriteAnalyzeImg(pethdr,petimg);
        clear('petimg');
        if noprob
            substi=fullfile(pethdr.path,[pethdr.name,'.img']);
            
            %Register used pet image in project structure
            project.taskDone{TaskIndex}.userdata.usedPET{ImageIndex,1}.path=project.sysinfo.workspace;
            project.taskDone{TaskIndex}.userdata.usedPET{ImageIndex,1}.name=[pethdr.name,'.img'];
            project.taskDone{TaskIndex}.userdata.usedPET{ImageIndex,1}.info=['PET used for co-registration.'];
            
        else
            msg='Error: Could not create temp-file for dynamic PET.';
            project=logProject(msg,project,TaskIndex,MethodIndex);
            project.taskDone{TaskIndex}.error{end+1}=msg;
            return;
        end
        
        %Use new filenames
        files.RES{1}=substi;
        project.taskDone{TaskIndex}.userdata.AIRfile{1,Direction}.name=[pethdr.name,'.air'];
        name=project.taskDone{TaskIndex}.userdata.AIRfile{1,Direction}.name;
        path=project.taskDone{TaskIndex}.userdata.AIRfile{1,Direction}.path;
        files.AIR=fullfile('',path,name);
    end

    %Note that AIR should return data in the same way as IIO and IPS
    ReturnFcn='ReturnCoreg';

    feval(project.pipeline.taskSetup{TaskIndex,MethodIndex}.function_name,Config,files,parent,ReturnFcn,visualizer);
    pause(1)
    h_registration=gcf;
    set(findobj(h_registration,'tag','SelectSTD'),'enable','off');
    set(findobj(h_registration,'tag','AddRES'),'enable','off');
    set(findobj(h_registration,'tag','RemoveRES'),'enable','off');
end%switch


%____ Wait until function (figure object) return (is finished)
uiwait(h_registration)

%____ Check if co-registration went well

%[A, Struct]=ReadAir(fullfile('',path,name));%load AIR file
%if(isempty(A) | sum(diag(A))==4)%No rotation if diag(A)=[1,1,1,1]
if(~exist(fullfile('',path,name),'file'))
    msg='Error: No co-registration file exist';
    project=logProject(msg,project,TaskIndex,MethodIndex);
    project.taskDone{TaskIndex}.error{end+1}=msg;    
end
