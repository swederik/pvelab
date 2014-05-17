function project=SpmSeg_wrapper(project,TaskIndex,MethodIndex,varargin)
%
% SpmSeg_wrapper calls SPM2 routines to perform segmentation.
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
%
%____________________________________________
% T. Rask, 160903, NRU
% SW version: 160903TR
% Updated for SPM8: 20111205, CS

global defaults

%____Check if SPM exists
switch exist('spm','file')
    case 0
        msg='ERROR: Can not find SPM. Addpath or download at www.fil.ion.ucl.ac.uk/spm.';
        project=logProject(msg,project,TaskIndex,MethodIndex);
        project.taskDone{TaskIndex}.error{end+1}=msg;
        return;
    case 2
        [v,c]=spm('Ver');
        if(strcmpi(v,'spm2'))
            project=logProject('SpmSeg_wrapper: SPM2 found. Segmentation progress is shown in SPM-windows.',project,TaskIndex,MethodIndex);
            SPM_ver=2;
        elseif(strcmpi(v,'spm5'))
            project=logProject('SpmSeg_wrapper: SPM5 found. Segmentation progress is shown in SPM-windows.',project,TaskIndex,MethodIndex);
            SPM_ver=5;
        elseif(strcmpi(v,'spm8'))
            project=logProject('SpmSeg_wrapper: SPM8 found. Segmentation progress is shown in SPM-windows.',project,TaskIndex,MethodIndex);
            SPM_ver=8;
        else
            msg='ERROR: Wrong SPM version, SPM2/5/8 required. Download SPM at www.fil.ion.ucl.ac.uk/spm.';
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
        project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.default=defaults.segment;
        project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.default.segmentMultiple=1; %option to segment multiple MRIs (if loaded)
        project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.default.sNormalize=1; %Spatially normalize to SPM template? Default is 1.
        project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.default.flipAnalyze=defaults.analyze.flip;
        feval('clear','global','defaults'); %Remove global spm defaults tree
        %loginfo
        msg='SpmSeg_wrapper: Using SPM2/5/8 default settings defined in spm_defaults.m.';
    end
    
    %_____________Check if all values are set
    userConfig=project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.default;
    if ~isfield(userConfig,'estimate')
        userConfig.estimate=[];
    end
    if ~isfield(userConfig,'write')
        userConfig.write=[];
    end
    if ~isfield(userConfig.estimate,'reg')
        userConfig.estimate.reg=0.01;
    end
    if ~isfield(userConfig.estimate,'cutoff')
        userConfig.estimate.cutoff=30;
    end
    if ~isfield(userConfig.estimate,'samp')
        userConfig.estimate.samp=3;
    end
    if ~isfield(userConfig.estimate,'affreg')
        userConfig.estimate.affreg=[];
    end
    if ~isfield(userConfig.estimate.affreg,'smosrc')
        userConfig.estimate.affreg.smosrc=8;
    end
    if ~isfield(userConfig.estimate.affreg,'regtype')
        userConfig.estimate.affreg.regtype='mni';
    end
    if ~isfield(userConfig.write,'cleanup')
        userConfig.write.cleanup=1;
    end
    if ~isfield(userConfig.write,'wrt_cor')
        userConfig.write.wrt_cor=1;
    end
    if ~isfield(userConfig.estimate,'bb')
        userConfig.estimate.bb=[[-88 88]' [-122 86]' [-60 95]'];
    end
    if ~isfield(userConfig,'segmentMultiple')
        userConfig.segmentMultiple=1;
    end
    if ~isfield(userConfig,'sNormalize')
        userConfig.sNormalize=1;
    end
    if ~isfield(userConfig,'flipAnalyze')
        userConfig.flipAnalyze=1;
    end
    project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.default=userConfig;
    %___________________________________________
    
    
    % User defined setting exist?
    if(isempty(project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.user))
        %User settings does not exist in project, use default
        project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.user=userConfig;
    else
        %User settings do exist
        userConfig=project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.user;
        msg='SpmSeg_wrapper: User settings are loaded';
    end;
    project=logProject(msg,project,TaskIndex,MethodIndex);
    
    %________________________Initialise file load_____________________________
    % How many modalities exist for given brain image...
    noModalities=length(project.pipeline.imageModality); % Get number of modalities e.g. PET, T1se (MR)
    ImageIndex=project.pipeline.imageIndex(1); %One image always exist, and right now only of one subject...
    
    
    %____________________________Start SPM UI_________________________________
    
    [Finter,Fgraph,CmdLine] = spm('FnUIsetup','Segment',1,0); %Create SPM-UI Interactive window with title 'Segment' and Graphics window (1). Not CmdLine (0). For syntax see spm.m .
    set(Finter,'visible','on');
    spm('Pointer','Watch'); %Set mouse pointer to 'hourglass'
    
    %______________________________Load files_________________________________
    
    %how many MR-images shall we segment?
    if ~(noModalities>2 && userConfig.segmentMultiple) %checkbox?
        noModalities=2;
    end;
    
    %Make sure SPM knows image orientation
    spmResultName='spm2-segment.tiff';
    defaults.analyze.flip=userConfig.flipAnalyze;
    defaults.printstr=['print -dtiff -painters -noui ',fullfile('',project.sysinfo.workspace,spmResultName)];
    
    PF='';
    for ModalityIndex=2:noModalities %Bypass PET-image (fileload convention: 1:PET 2:T1W 3:T2W 4:PDW)
        
        %Set input-files to output from fileload task.
        project.taskDone{TaskIndex}.inputfiles{ImageIndex,ModalityIndex}.path=project.taskDone{1}.outputfiles{ImageIndex,ModalityIndex}.path;
        project.taskDone{TaskIndex}.inputfiles{ImageIndex,ModalityIndex}.name=project.taskDone{1}.outputfiles{ImageIndex,ModalityIndex}.name;
        
        %Set output-files to output from fileload task. (No change to original files)
        project.taskDone{TaskIndex}.outputfiles{ImageIndex,ModalityIndex}.path=project.taskDone{1}.outputfiles{ImageIndex,ModalityIndex}.path;
        project.taskDone{TaskIndex}.outputfiles{ImageIndex,ModalityIndex}.name=project.taskDone{1}.outputfiles{ImageIndex,ModalityIndex}.name;
        
        sourceFilename=fullfile('',project.taskDone{TaskIndex}.inputfiles{ImageIndex,ModalityIndex}.path,project.taskDone{TaskIndex}.inputfiles{ImageIndex,ModalityIndex}.name);
        if isempty(PF)
            PF=sourceFilename;
        else
            PF=char(PF,sourceFilename);
        end;
    end;
    
    VF{ImageIndex} = spm_vol(PF); %read fileinfo to SPM format
    
    ok    = dims_ok(VF{ImageIndex}); %check if multiple MR are in register
    % If more than one volume is specified (eg T1 & T2), then they must be
    % in register (same position, size, voxel dims etc..).
    
    if userConfig.sNormalize  %Has user selected to spatially normalize to template?
        if SPM_ver==2
            templateFile=fullfile(spm('Dir'),'templates','T1.mnc'); %template for spatial normalisation
        else
            msg='Error: SPM version not recognizable.';
            project=logProject(msg,project,TaskIndex,MethodIndex);
            project.taskDone{TaskIndex}.error{end+1}=msg;
            return;
        end
        TF=spm_vol(templateFile);
        %Multiple images should already be coregistered! so only template for first
        %image is needed (and used).
    else
        TF=eye(4); %if no spatial normalisation shall be done
    end;
    %___________________________Start Segmenting_______________________________
    
    if ok
        if (noModalities>2)
            project=logProject('SpmSeg_wrapper: Segmenting multiple MRIs.',project,TaskIndex,MethodIndex);
            spm('FigName','Segmenting multiple MRIs.',Finter,CmdLine); %Set Title on Interactive window
        else
            project=logProject('SpmSeg_wrapper: Segmenting T1-weighted MRI.',project,TaskIndex,MethodIndex);
            spm('FigName','Segmenting T1-weighted MRI.',Finter,CmdLine); %Set Title on Interactive window
        end;
        
        spm_segment(VF{ImageIndex},TF,userConfig); %Call segmentation routine.
    else
        msg='Error: Loaded MRI not in register. Same position, size, voxel dims etc. needed (reslice).';
        project=logProject(msg,project,TaskIndex,MethodIndex);
        project.taskDone{TaskIndex}.error{end+1}=msg;
        return;
    end
elseif (SPM_ver==5)
    %Defaults settings exist?
    if(isempty(project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.default))
        % No user settings have been selected, use defaults set by spm_defaults
        global defaults;
        spm_defaults;
        % def=spm('defaults','pet');         %setup defaults-tree
        def=defaults;
        tmp.opts=def.preproc;
        tmp.opts.msk={''};
        dummy{1}=cleanupcomment(tmp.opts.tpm(1,:));
        dummy{2}=cleanupcomment(tmp.opts.tpm(2,:));
        dummy{3}=cleanupcomment(tmp.opts.tpm(3,:));
        tmp.opts.tpm=dummy;

        tmp.output.GM=[0 0 1];           
        tmp.output.WM=[0 0 1];
        tmp.output.CSF=[0 0 1];          % CSF is needed to remove non brain tissue
        tmp.output.biascor=1;
        tmp.output.cleanup=0;
        project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.default=tmp;
        
        %loginfo
        msg='SpmSeg_wrapper: Using SPM5 default settings defined in spm_defaults.m.';
    end

    % Get parameters from configurator default if user not defined
    if(isempty(project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.user))
        project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.user=...
            project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.default;
    end
    userConfig=project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.user;    

    ModalityIndex=2;                           % Bypass the PET image (modality 1)
    ImageIndex=project.pipeline.imageIndex(1); %One image always exist, and right now only of one subject...
    
    %spm5segm=load('spm5-segm-batch');
    %Set defaults
    spm5segm.jobs{1}.spatial{1}.preproc.output=userConfig.output;
    spm5segm.jobs{1}.spatial{1}.preproc.opts=userConfig.opts;
    
    % Change MR input file to actual input file
    sourceFilename=fullfile('',project.taskDone{TaskIndex}.inputfiles{ImageIndex,ModalityIndex}.path,project.taskDone{TaskIndex}.inputfiles{ImageIndex,ModalityIndex}.name);
    spm5segm.jobs{1}.spatial{1}.preproc.data{1}=sprintf('%s,1',sourceFilename);
   
    % Save batch file for segmentation
    Spm5SegmBatchFile=fullfile(project.taskDone{TaskIndex}.inputfiles{ImageIndex,ModalityIndex}.path,'Spm5SegmBatchFile.mat');
    save(Spm5SegmBatchFile,'-struct','spm5segm');
    project=logProject(['SpmSeg_wrapper: Created SPM5 batch file: ',Spm5SegmBatchFile],project,TaskIndex,MethodIndex);

    % _________________________ Start segmentation ________________________
    project=logProject('SpmSeg_wrapper: SPM5 segmenting T1-weighted MRI.',project,TaskIndex,MethodIndex);
    %spm('defaults','pet');
    spm_jobman('defaults');
    spm_jobman('run',Spm5SegmBatchFile);

    % _________save output-file path and name in userdata
    [pn,fn,ex]=fileparts(Spm5SegmBatchFile);
    project.taskDone{TaskIndex}.userdata.segcmdfile{ImageIndex,1}.path=project.sysinfo.workspace;
    project.taskDone{TaskIndex}.userdata.segcmdfile{ImageIndex,1}.name=[fn ex];
    project.taskDone{TaskIndex}.userdata.segcmdfile{ImageIndex,1}.info='Batch cmd file for spm5 segmentation';
        
elseif (SPM_ver==8)
    %Defaults settings exist?
    if(isempty(project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.default))
        % No user settings have been selected, use defaults set by spm_defaults
        def=spm('defaults','pet');         %setup defaults-tree
        tmp.opts=def.preproc;
        tmp.output=tmp.opts.output;
        tmp.opts=rmfield(tmp.opts,'output');
        tmp.opts=rmfield(tmp.opts,'fudge');
        tmp.output.CSF=[0 0 1];            % CSF is needed to remove non brain tissue
        project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.default=tmp;
        
        %loginfo
        msg='SpmSeg_wrapper: Using SPM8 default settings defined in spm_defaults.m.';
    end

    % Get parameters from configurator default if user not defined
    if(isempty(project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.user))
        project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.user=...
            project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.default;
    end
    userConfig=project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.user;    

    ModalityIndex=2;                           % Bypass the PET image (modality 1)
    ImageIndex=project.pipeline.imageIndex(1); %One image always exist, and right now only of one subject...
    
    %spm8segm=load('spm8-segm-batch');
    %Set defaults
    spm8segm.matlabbatch{1}.spm.spatial.preproc.output=userConfig.output;
    spm8segm.matlabbatch{1}.spm.spatial.preproc.opts=userConfig.opts;
    
    % Change MR input file to actual input file
    sourceFilename=fullfile('',project.taskDone{TaskIndex}.inputfiles{ImageIndex,ModalityIndex}.path,project.taskDone{TaskIndex}.inputfiles{ImageIndex,ModalityIndex}.name);
    spm8segm.matlabbatch{1}.spm.spatial.preproc.data{1}=sprintf('%s,1',sourceFilename);
   
    % Save batch file for segmentation
    Spm8SegmBatchFile=fullfile(project.taskDone{TaskIndex}.inputfiles{ImageIndex,ModalityIndex}.path,'Spm8SegmBatchFile.mat');
    save(Spm8SegmBatchFile,'-struct','spm8segm');
    project=logProject(['SpmSeg_wrapper: Created SPM8 batch file: ',Spm8SegmBatchFile],project,TaskIndex,MethodIndex);

    % _________________________ Start segmentation ________________________
    project=logProject('SpmSeg_wrapper: SPM8 segmenting T1-weighted MRI.',project,TaskIndex,MethodIndex);
    spm('defaults','pet');
    spm_jobman('initcfg');
    spm_jobman('run',Spm8SegmBatchFile);

    % _________save output-file path and name in userdata
    [pn,fn,ex]=fileparts(Spm8SegmBatchFile);
    project.taskDone{TaskIndex}.userdata.segcmdfile{ImageIndex,1}.path=project.sysinfo.workspace;
    project.taskDone{TaskIndex}.userdata.segcmdfile{ImageIndex,1}.name=[fn ex];
    project.taskDone{TaskIndex}.userdata.segcmdfile{ImageIndex,1}.info='Batch cmd file for spm8 segmentation';
        
else
    msg='Error: SPM version not recognizable.';
    project=logProject(msg,project,TaskIndex,MethodIndex);
    project.taskDone{TaskIndex}.error{end+1}=msg;
    return;
end
%_____________________Set project-structure fields__________________________

%Copy generated files from sourcefile-path to workspace:
[inputPath,inputName,ext]=fileparts(fullfile('',project.taskDone{TaskIndex}.inputfiles{ImageIndex,2}.path,project.taskDone{TaskIndex}.inputfiles{ImageIndex,2}.name));
%_seg files are named from the first MR-file.
for i=1:3
    if SPM_ver==2
        segName=[inputName,'_seg',num2str(i),'.img'];
        segNameHdr=[inputName,'_seg',num2str(i),'.hdr'];
        segNameMat=[inputName,'_seg',num2str(i),'.mat'];
        if ~(exist(fullfile('',project.sysinfo.workspace,[inputName,ext]))==2) %Move output to workspace if it is not there already
            project=logProject(['SpmSeg_wrapper: Moving SPM2 output to project workspace: ',segName],project,TaskIndex,MethodIndex);
            
            [status,message,messageid]=movefile(fullfile('',inputPath,segName),fullfile('',project.sysinfo.workspace,segName));
            if (status==0)
                project=logProject(['Error in SpmSeg_wrapper: ',message],project,TaskIndex,MethodIndex);
                project.taskDone{TaskIndex}.error{end+1}=message;
                return;
            end
            [status,message,messageid]=movefile(fullfile('',inputPath,segNameHdr),fullfile('',project.sysinfo.workspace,segNameHdr));
            if (status==0)
                project=logProject(['Error in SpmSeg_wrapper: ',message],project,TaskIndex,MethodIndex);
                project.taskDone{TaskIndex}.error{end+1}=message;
                return;
            end
            if exist(fullfile('',inputPath,segNameMat))
                [status,message,messageid]=movefile(fullfile('',inputPath,segNameMat),fullfile('',project.sysinfo.workspace,segNameMat));
                if (status==0)
                    project=logProject(['Error in SpmSeg_wrapper: ',message],project,TaskIndex,MethodIndex);
                    project.taskDone{TaskIndex}.error{end+1}=message;
                    return;
                else
                    %_________Register .mat-files in project structure for cleanup
                    project.taskDone{TaskIndex}.userdata.matFile{ImageIndex,i}.path=project.sysinfo.workspace;
                    project.taskDone{TaskIndex}.userdata.matFile{ImageIndex,i}.name=segNameMat;
                end
            end
        end
    elseif SPM_ver==5
        SPM5segName=['c',num2str(i),inputName,'.img'];
        SPM5segNameHdr=['c',num2str(i),inputName,'.hdr'];
        segName=[inputName,'_seg',num2str(i),'.img'];
        segNameHdr=[inputName,'_seg',num2str(i),'.hdr'];
        
        project=logProject(['SpmSeg_wrapper: Moving SPM5 output to project workspace: ',segName],project,TaskIndex,MethodIndex);
        
        [status,message,messageid]=movefile(fullfile('',inputPath,SPM5segName),fullfile('',project.sysinfo.workspace,segName));
        if (status==0)
            project=logProject(['Error in SpmSeg_wrapper: ',message],project,TaskIndex,MethodIndex);
            project.taskDone{TaskIndex}.error{end+1}=message;
            return;
        end
        [status,message,messageid]=movefile(fullfile('',inputPath,SPM5segNameHdr),fullfile('',project.sysinfo.workspace,segNameHdr));
        if (status==0)
            project=logProject(['Error in SpmSeg_wrapper: ',message],project,TaskIndex,MethodIndex);
            project.taskDone{TaskIndex}.error{end+1}=message;
            return;
        end
    elseif SPM_ver==8
        SPM8segName=['c',num2str(i),inputName,'.img'];
        SPM8segNameHdr=['c',num2str(i),inputName,'.hdr'];
        segName=[inputName,'_seg',num2str(i),'.img'];
        segNameHdr=[inputName,'_seg',num2str(i),'.hdr'];
        
        project=logProject(['SpmSeg_wrapper: Moving SPM8 output to project workspace: ',segName],project,TaskIndex,MethodIndex);
        
        [status,message,messageid]=movefile(fullfile('',inputPath,SPM8segName),fullfile('',project.sysinfo.workspace,segName));
        if (status==0)
            project=logProject(['Error in SpmSeg_wrapper: ',message],project,TaskIndex,MethodIndex);
            project.taskDone{TaskIndex}.error{end+1}=message;
            return;
        end
        [status,message,messageid]=movefile(fullfile('',inputPath,SPM8segNameHdr),fullfile('',project.sysinfo.workspace,segNameHdr));
        if (status==0)
            project=logProject(['Error in SpmSeg_wrapper: ',message],project,TaskIndex,MethodIndex);
            project.taskDone{TaskIndex}.error{end+1}=message;
            return;
        end
    else
        message='Unknown SPM version';
        project=logProject(['Error in SpmSeg_wrapper: ',message],project,TaskIndex,MethodIndex);
        project.taskDone{TaskIndex}.error{end+1}=message;
        return;
    end
    % _________save output-file path and name in userdata
    project.taskDone{TaskIndex}.userdata.segout{ImageIndex,i}.path=project.sysinfo.workspace;
    project.taskDone{TaskIndex}.userdata.segout{ImageIndex,i}.name=segName;
    
    
    %__________Fix centered origin back to [0,0,0]
    sourceHdr=ReadAnalyzeHdr(sourceFilename);
    project=logProject(['SpmSeg_wrapper: Setting origin in: ',segNameHdr,' to sourceimage origin.'],project,TaskIndex,MethodIndex);
    hdr=ReadAnalyzeHdr(fullfile('',project.sysinfo.workspace,segNameHdr));
    hdr.origin=sourceHdr.origin;
    hdr.path=project.sysinfo.workspace;
    result=WriteAnalyzeHdr(hdr);
end



% _________save output-file info in userdata
project.taskDone{TaskIndex}.userdata.segout{ImageIndex,1}.info='Segmented Gray Matter';
project.taskDone{TaskIndex}.userdata.segout{ImageIndex,2}.info='Segmented White Matter';
project.taskDone{TaskIndex}.userdata.segout{ImageIndex,3}.info='Segmented CSF';

% %__________Save configuration in taskDone
% project.taskDone{TaskIndex}.configuration{ImageIndex,1}=userConfig;

%_________________________________Cleanup__________________________________

if (SPM_ver==2)
    %Register bias corrected images for cleanup if they are created
    if userConfig.write.wrt_cor
        project.taskDone{TaskIndex}.userdata.biasCorrected{ImageIndex,1}.path=inputPath;
        project.taskDone{TaskIndex}.userdata.biasCorrected{ImageIndex,1}.name=['m',inputName,'.img'];
        project.taskDone{TaskIndex}.userdata.biasCorrected{ImageIndex,2}.path=inputPath;
        project.taskDone{TaskIndex}.userdata.biasCorrected{ImageIndex,2}.name=['m',inputName,'.mat'];
    end
    
    %____Register display-output in project
    project.taskDone{TaskIndex}.show{ImageIndex,1}.path=project.sysinfo.workspace;
    project.taskDone{TaskIndex}.show{ImageIndex,1}.name=spmResultName;
    project.taskDone{TaskIndex}.show{ImageIndex,1}.info='SPM output';
    
    close(Finter); %close SPM-Interactive window
    close(Fgraph); %close SPM-Graphics window
    spm('Pointer'); %Set mouse pointer to default (Arrow)
else    % SPM5, 8
    if userConfig.output.biascor
        project.taskDone{TaskIndex}.userdata.biasCorrected{ImageIndex,1}.path=inputPath;
        project.taskDone{TaskIndex}.userdata.biasCorrected{ImageIndex,1}.name=['m',inputName,'.img'];
        project.taskDone{TaskIndex}.userdata.biasCorrected{ImageIndex,2}.path=inputPath;
        project.taskDone{TaskIndex}.userdata.biasCorrected{ImageIndex,2}.name=['m',inputName,'.mat'];
    end
    
    indo=1;
    seg_sn_name=sprintf('%s_seg_sn.mat',inputName);
    if exist(fullfile(inputPath,seg_sn_name),'file')
        project.taskDone{TaskIndex}.userdata.SpmCoreg{indo}.name=seg_sn_name;
        project.taskDone{TaskIndex}.userdata.SpmCoreg{indo}.path=inputPath;
        project.taskDone{TaskIndex}.userdata.SpmCoreg{indo}.info='SPM segmentation: ....seg_sn.mat file';
        indo=indo+1;
    end

    seg_sn_name=sprintf('%s_seg_inv_sn.mat',inputName);
    if exist(fullfile(inputPath,seg_sn_name),'file')
        project.taskDone{TaskIndex}.userdata.SpmCoreg{indo}.name=seg_sn_name;
        project.taskDone{TaskIndex}.userdata.SpmCoreg{indo}.path=inputPath;
        project.taskDone{TaskIndex}.userdata.SpmCoreg{indo}.info='SPM segmentation: ....seg_sn.mat file';
        indo=indo+1;
    end
end
 
feval('clear','global','defaults'); %Remove global spm defaults
return;

%=======================================================================
function ok = dims_ok(vv)
ok = 0;
if isempty(vv), return; end;
if numel(vv)==1
    ok = 1;
else
    tmp1 = cat(1,vv.dim);
    tmp2 = cat(3,vv.mat);
    if ~any(any(diff(tmp1(:,1:3)))) && ~any(any(any(diff(tmp2,1,3))))
        ok=1;
    end;
end;
return;
%=======================================================================
