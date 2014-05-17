function project=SpmCoreg_wrapper(project,TaskIndex,MethodIndex,varargin)
% SW version: 260903TR 
% SpmCoreg_wrapper calls SPM2 or SPM5 routines to perform coregistration.
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
%   logProject
%   SaveAir
%   voxa2tala
%   SPM2
%____________________________________________
% T. Rask, 160903, NRU
% Updated for SPM8: 20120109, CS

global defaults;

%____Check if SPM2 exists
switch exist('spm','file')
    case 0
        msg='ERROR: Can not find SPM. Addpath or download at www.fil.ion.ucl.ac.uk/spm.';
        project=logProject(msg,project,TaskIndex,MethodIndex);
        project.taskDone{TaskIndex}.error{end+1}=msg;
        return;
    case 2
        [v,c]=spm('Ver');
        if (strcmpi(v,'spm2'))
            project=logProject('SpmCoreg_wrapper: SPM2 found. Co-registration progress is shown in SPM-windows.',project,TaskIndex,MethodIndex);
            SPM_ver=2;
        elseif (strcmpi(v,'spm5'))
            project=logProject('SpmCoreg_wrapper: SPM5 found. Co-registration progress is shown in SPM-windows.',project,TaskIndex,MethodIndex);
            SPM_ver=5;
        elseif(strcmpi(v,'spm8'))
            project=logProject('SpmCoreg_wrapper: SPM8 found. Co-registration progress is shown in SPM-windows.',project,TaskIndex,MethodIndex);
            SPM_ver=8;
        else
            msg='SpmCoreg_wrapper: Wrong SPM version, SPM2/5/8 required. Download SPM at www.fil.ion.ucl.ac.uk/spm.';
            project=logProject(msg,project,TaskIndex,MethodIndex);
            project.taskDone{TaskIndex}.error{end+1}=msg;
            return;
        end
    otherwise
        msg='ERROR: SPM not recognized as .m-file.';
        project=logProject(msg,project,TaskIndex,MethodIndex);
        project.taskDone{TaskIndex}.error{end+1}=msg;
        return;
end

%_____________ Load configuration settings for project ___________________

if (SPM_ver==2)
    %Defaults settings exist?
    if(isempty(project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.default))
        % No user settings have been selected, use defaults set by spm_defaults
        spm_defaults; %setup defaults-tree
        project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.default=defaults.coreg;
        project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.default.to=1;
        project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.default.flipAnalyze=defaults.analyze.flip;
        feval('clear','global','defaults'); %Remove global spm defaults tree
        
        %loginfo
        msg='SpmCoreg_wrapper: Using SPM2 or SPM5 default settings defined in spm_defaults.m.';
    end
    
    %_________ Check if all parameters are defined
    userConfig=project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.default;
    if ~isfield(userConfig,'to')
        userConfig.to=1;
    end
    if ~isfield(userConfig,'flipAnalyze')
        userConfig.flipAnalyze=1;
    end
    if ~isfield(userConfig,'estimate')
        userConfig.estimate=[];
    end
    if ~isfield(userConfig,'write')
        userConfig.write=[];
    end
    if ~isfield(userConfig.write,'interp')
        userConfig.write.interp=1;
    end
    if ~isfield(userConfig.write,'wrap')
        userConfig.write.wrap=[0 0 0];
    end
    if ~isfield(userConfig.write,'mask')
        userConfig.write.mask=0;
    end
    if ~isfield(userConfig.estimate,'cost_fun')
        userConfig.estimate.cost_fun='nmi';
    end
    if ~isfield(userConfig.estimate,'sep')
        userConfig.estimate.sep=[4 2];
    end
    if ~isfield(userConfig.estimate,'tol')
        userConfig.estimate.tol=[0.02 0.02 0.02 0.001 0.001 0.001 0.01 0.01 0.01 0.001 0.001 0.001];
    end
    if ~isfield(userConfig.estimate,'fwhm')
        userConfig.estimate.fwhm=[7 7];
    end
    
    project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.default=userConfig;
    %_____________________________________________
    
    % User defined setting exist?
    if(isempty(project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.user))
        %User settings does not exist in project, use default
        project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.user=userConfig;
    else
        %User settings do exist
        userConfig=project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.user;
        msg='SpmCoreg_wrapper: User settings are loaded';
    end;
    project=logProject(msg,project,TaskIndex,MethodIndex);
    
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
    
    %Make sure SPM knows image orientation
    spmResultName='spm2-coreg.tiff';
    
    defaults.analyze.flip=userConfig.flipAnalyze;
    defaults.printstr=['print -dtiff -painters -noui ',fullfile('',project.sysinfo.workspace,spmResultName)];
    
    
    if (userConfig.to==1) %Select object and target picture from config.
        targImg=sourceFile1;
        objImg=sourceFile2;
        
        [objPath,objName,ext]=fileparts(objImg);
        [targPath,targName,ext]=fileparts(targImg);
        
        %______________Select frames to register if PET is dynamic_____________
        %MR->PET
        substi='';
        PEThdr=ReadAnalyzeHdr(sourceFile1);
        if length(PEThdr.dim)>3 && PEThdr.dim(4)>1
            [petimg,pethdr]=LoadAnalyze(sourceFile1,'single');
            if isempty(petimg)
                msg='User abort, cancel pressed.';
                project=logProject(msg,project,TaskIndex,MethodIndex);
                project.taskDone{TaskIndex}.error{end+1}=msg;
                return
            end
            
            pethdr.name=[targName,'_3D'];
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
                project.taskDone{TaskIndex}.userdata.usedPET{ImageIndex,1}.info='PET used for co-registration.';
                
            else
                msg='Error: Could not create temp-file for dynamic PET.';
                project=logProject(msg,project,TaskIndex,MethodIndex);
                project.taskDone{TaskIndex}.error{end+1}=msg;
                return;
            end
            targImgInf=spm_vol(substi); %Still image (spm_vol reads header info)
            objImgInf=spm_vol(objImg); %Transformed image header info
        else
            targImgInf=spm_vol(targImg); %Still image (spm_vol reads header info)
            objImgInf=spm_vol(objImg); %Transformed image header info
        end
        
    elseif (userConfig.to==2)
        targImg=sourceFile2;
        objImg=sourceFile1;
        
        [objPath,objName,ext]=fileparts(objImg);
        [targPath,targName,ext]=fileparts(targImg);
        
        
        %______________Select frames to register if PET is dynamic_____________
        %PET->MR
        
        substi='';
        PEThdr=ReadAnalyzeHdr(sourceFile1);
        if length(PEThdr.dim)>3 && PEThdr.dim(4)>1
            [petimg,pethdr]=LoadAnalyze(sourceFile1,'single');
            if isempty(petimg)
                msg='User abort, cancel pressed.';
                project=logProject(msg,project,TaskIndex,MethodIndex);
                project.taskDone{TaskIndex}.error{end+1}=msg;
                return
            end
            
            pethdr.name=[objName,'_3D'];
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
                project.taskDone{TaskIndex}.userdata.usedPET{ImageIndex,1}.info='PET used for co-registration.';
                
            else
                msg='Error: Could not create temp-file for dynamic PET.';
                project=logProject(msg,project,TaskIndex,MethodIndex);
                project.taskDone{TaskIndex}.error{end+1}=msg;
                return;
            end
            targImgInf=spm_vol(targImg); %Still image (spm_vol reads header info)
            objImgInf=spm_vol(substi); %Transformed image header info
        else
            targImgInf=spm_vol(targImg); %Still image (spm_vol reads header info)
            objImgInf=spm_vol(objImg); %Transformed image header info
        end
    end
    
    %______ Start SPM UI
    [Finter,Fgraph,CmdLine] = spm('FnUIsetup','Coregister',1,0); %Create SPM-UI Interactive window. And Graphics window (1). Not CmdLine (0). For syntax see spm.m .
    set(Finter,'visible','on');
    spm('Pointer','Watch'); %Set mouse pointer to 'hourglass'
    
    %_____ Start Coregistration
    spm('FigName',['Coreg.: ',objName,' to ',targName],Finter,CmdLine); %set name on interactive window
    
    x  = spm_coreg(targImgInf,objImgInf,userConfig.estimate); %Call SPM coregister
    
    % M  = inv(spm_matrix(x));
    % MM = zeros(4,4,size(objImg,1));
    % for j=1:size(objImg,1), %For each objImg create a .mat file with tansformation matrix
    %     MM(:,:,j) = spm_get_space(deblank(objImg(j,:)));
    % end;
    % for j=1:size(objImg,1),
    %     spm_get_space(deblank(objImg(j,:)), M*MM(:,:,j));
    % end;
    
    %IMPORTANT:
    %You cannot just use inv(spm_matrix(x(:)')) to convert from Talairach to
    %Talairach space, because some of the transformation is done by
    %objImgInf.mat.
    TransVox2Vox=targImgInf.mat\inv(spm_matrix(x(:)'))*objImgInf.mat; %transformation from voxel to voxel
    
elseif (SPM_ver==5)||(SPM_ver==8)
    %Defaults settings exist?
    if(isempty(project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.default))
        if (SPM_ver==5)
            global defaults;
            spm_defaults;
            % def=spm('defaults','pet');         %setup defaults-tree
            def=defaults;
            tmp.estimate.eoptions=def.coreg.estimate;
        else
            % No user settings have been selected, use defaults set by spm_defaults
            def=spm('defaults','pet');         %setup defaults-tree
            tmp.estimate.eoptions=def.coreg.estimate;
        end
        tmp.to=2; %Always to MR as spm8 coreg to PET does not work
        
        project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.default=tmp;
        
        %loginfo
        msg='SpmCoreg_wrapper: Using SPM8 default settings defined in spm_defaults.m.';
    end
    
    % Get parameters from configurator default if user not defined
    if(isempty(project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.user))
        project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.user=...
            project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.default;
    end
    userConfig=project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.user;
    
    % How many modalities exist for given brain image...
    ImageIndex=project.pipeline.imageIndex(1); %One image always exist, and right now only of one subject...
    
    %______ Load input files given in project and save them as output files w. prefix if prefix exists...
    project.taskDone{TaskIndex}.inputfiles{ImageIndex,1}.path=project.taskDone{1}.outputfiles{ImageIndex,1}.path; %PET
    project.taskDone{TaskIndex}.inputfiles{ImageIndex,1}.name=project.taskDone{1}.outputfiles{ImageIndex,1}.name;
    
    project.taskDone{TaskIndex}.inputfiles{ImageIndex,2}.path=project.taskDone{1}.outputfiles{ImageIndex,2}.path; %MR
    project.taskDone{TaskIndex}.inputfiles{ImageIndex,2}.name=project.taskDone{1}.outputfiles{ImageIndex,2}.name;
    
    sourceFile1=fullfile('',project.taskDone{TaskIndex}.inputfiles{ImageIndex,1}.path,project.taskDone{TaskIndex}.inputfiles{ImageIndex,1}.name);
    sourceFile2=fullfile('',project.taskDone{TaskIndex}.inputfiles{ImageIndex,2}.path,project.taskDone{TaskIndex}.inputfiles{ImageIndex,2}.name);
    
    if (userConfig.to==2) % Only works for co-registration to MR in spm8
        
        targImg=sourceFile2;
        objImg=sourceFile1;
        
        %______________Select frames to register if PET is dynamic_____________
        %PET->MR
        
        PEThdr=ReadAnalyzeHdr(objImg);
        if length(PEThdr.dim)>3 && PEThdr.dim(4)>1
            [petimg,pethdr]=LoadAnalyze(sourceFile1,'single');
            if isempty(petimg)
                msg='User abort, cancel pressed.';
                project=logProject(msg,project,TaskIndex,MethodIndex);
                project.taskDone{TaskIndex}.error{end+1}=msg;
                return
            end
            
            [d,objName,dd]=fileparts(objImg);
            pethdr.name=[objName,'_3D'];
            pethdr.path=project.sysinfo.workspace;
            pethdr.origin=PEThdr.origin;
            pethdr.scale=PEThdr.scale;
            pethdr.offset=PEThdr.offset;
            
            project=logProject(['Writing selected frames to temp-file: ',pethdr.name,'.img'],project,TaskIndex,MethodIndex);
            
            noprob=WriteAnalyzeImg(pethdr,petimg);
            clear('petimg');
            if noprob
                objImg=fullfile(pethdr.path,[pethdr.name,'.img']);
                
                %Register used pet image in project structure
                project.taskDone{TaskIndex}.userdata.usedPET{ImageIndex,1}.path=project.sysinfo.workspace;
                project.taskDone{TaskIndex}.userdata.usedPET{ImageIndex,1}.name=[pethdr.name,'.img'];
                project.taskDone{TaskIndex}.userdata.usedPET{ImageIndex,1}.info='PET used for co-registration.';
                
            else
                msg='Error: Could not create temp-file for dynamic PET.';
                project=logProject(msg,project,TaskIndex,MethodIndex);
                project.taskDone{TaskIndex}.error{end+1}=msg;
                return;
            end
        end
    else
        msg='Error: In spm8 only MR image can be used as standard/target image.';
        project=logProject(msg,project,TaskIndex,MethodIndex);
        project.taskDone{TaskIndex}.error{end+1}=msg;
        return;
    end
    
    [objPath,objName,ext]=fileparts(objImg);
    [targPath,targName,ext]=fileparts(targImg);
    
    %____Get headers for voxa2tala and SaveAir
    hdrI=ReadAnalyzeHdr(objImg);
    hdrO=ReadAnalyzeHdr(targImg);
    
    if (SPM_ver==5)
        spm8coreg.jobs{1}.spatial{1}.coreg{1}.estimate.eoptions=userConfig.estimate.eoptions;
        
        % Change MR input file to actual input file
        spm8coreg.jobs{1}.spatial{1}.coreg{1}.estimate.ref{1}=sprintf('%s,1',targImg);
        spm8coreg.jobs{1}.spatial{1}.coreg{1}.estimate.source{1}=sprintf('%s,1',objImg);
        spm8coreg.jobs{1}.spatial{1}.coreg{1}.estimate.other{1}='';
    else
        %spm8coreg=load('spm8-coreg-batch');
        spm8coreg.matlabbatch{1}.spm.spatial.coreg.estimate.eoptions=userConfig.estimate.eoptions;
        
        % Change MR input file to actual input file
        spm8coreg.matlabbatch{1}.spm.spatial.coreg.estimate.ref{1}=sprintf('%s,1',targImg);
        spm8coreg.matlabbatch{1}.spm.spatial.coreg.estimate.source{1}=sprintf('%s,1',objImg);
        spm8coreg.matlabbatch{1}.spm.spatial.coreg.estimate.other{1}='';
    end
    
    % Save batch file for co-registration
    Spm8CoregBatchFile=fullfile(project.taskDone{TaskIndex}.inputfiles{ImageIndex,1}.path,'Spm8CoregBatchFile.mat');
    save(Spm8CoregBatchFile,'-struct','spm8coreg');
    %save(Spm8CoregBatchFile,'spm8coreg');
    project=logProject(['SpmCoreg_wrapper: Created SPM8 batch file: ',Spm8CoregBatchFile],project,TaskIndex,MethodIndex);
    
    % _________________________ Start co-registration ________________________
    project=logProject('SpmCoreg_wrapper: SPM8 Co-registration T1-weighted MRI.',project,TaskIndex,MethodIndex);
    if (SPM_ver==5)
        global defaults;
        spm_defaults;
        spm_jobman('defaults');
    else
        spm_jobman('initcfg');
    end
    
    spm_jobman('run',Spm8CoregBatchFile);
    
    % _________save output-file path and name in userdata
    [pn,fn,ex]=fileparts(Spm8CoregBatchFile);
    project.taskDone{TaskIndex}.userdata.coregcmdfile{ImageIndex,1}.path=project.sysinfo.workspace;
    project.taskDone{TaskIndex}.userdata.coregcmdfile{ImageIndex,1}.name=[fn  ex];
    project.taskDone{TaskIndex}.userdata.coregcmdfile{ImageIndex,1}.info='Batch cmd file for spm8 co-registration';
    
    targImgInf=spm_vol(targImg); %Still image (spm_vol reads header info)
    objImgInf=spm_vol(objImg);   %Transformed image header info
    %TransVox2Vox=targImgInf.mat\inv(spm_matrix(x(:)'))*objImgInf.mat;
    TransVox2Vox=targImgInf.mat\objImgInf.mat;
    %TransVox2Vox=objImgInf.mat\targImgInf.mat;
    
    % Remake the headers for obj/target image as spm have destroid them
    WriteAnalyzeHdr(hdrI);
    %WriteAnalyzeHdr(hdrO);
else
    msg='Error: SPM version not recognizable.';
    project=logProject(msg,project,TaskIndex,MethodIndex);
    project.taskDone{TaskIndex}.error{end+1}=msg;
    return;
end

%____Get headers for voxa2tala and SaveAir
Params.hdrI=ReadAnalyzeHdr(fullfile('',objPath,[objName,'.hdr']));
Params.hdrO=ReadAnalyzeHdr(fullfile('',targPath,[targName,'.hdr']));

%____Convert transformation matrix to go from talairach to talairach
TransTal2Tal=voxa2tala(TransVox2Vox,Params.hdrI,Params.hdrO);

NRUsys=getenv('NRU');
%____Set AIRfile parameters
Params.A=TransTal2Tal; %transformation matrix
if SPM_ver==2
    Params.descr='SPM2';
elseif SPM_ver==5
    Params.descr='SPM5';
elseif SPM_ver==8
    Params.descr='SPM8';
else
    Params.descr='Unknown SPM version';
end

if (isempty(NRUsys) || str2num(NRUsys)==0)
    Params.nruformat=0;
else
    Params.nruformat=1;
end

%____Save AIR file
Message=SaveAir(fullfile('',project.sysinfo.workspace,[objName,'.air']),Params);

%____Save output-file path and name in userdata
coregMod=(~(userConfig.to-1))+1; %invert "coregister to"
project.taskDone{TaskIndex}.userdata.AIRfile{ImageIndex,coregMod}.path=project.sysinfo.workspace;
project.taskDone{TaskIndex}.userdata.AIRfile{ImageIndex,coregMod}.name=[objName,'.air'];

project.taskDone{TaskIndex}.userdata.MATfile{ImageIndex,coregMod}.path=objPath;
project.taskDone{TaskIndex}.userdata.MATfile{ImageIndex,coregMod}.name=[objName,'.mat'];

if SPM_ver==2
    %____Register display-output in project
    project.taskDone{TaskIndex}.show{ImageIndex,1}.path=project.sysinfo.workspace;
    project.taskDone{TaskIndex}.show{ImageIndex,1}.name=spmResultName;
    project.taskDone{TaskIndex}.show{ImageIndex,1}.info='SPM output';
    
    % %__________Save configuration in taskDone
    % project.taskDone{TaskIndex}.configuration{ImageIndex,1}=userConfig;
    
    %____Clean up
    close(Finter); %close SPM-Interactive window
    close(Fgraph); %close SPM-Graphics window
    spm('Pointer'); %Set mouse pointer to default (Arrow)
else
    spm('Pointer'); %Set mouse pointer to default (Arrow)
end

feval('clear','global','defaults'); %Remove global spm defaults tree
