function project=Reslice_wrapper(project,TaskIndex,MethodIndex,varargin)
% Reslice wrapper, is specieal for te PVELab
%   Expect T1 to be base, so: PET*A->T1 or T1*inv(A)->PET and if more modalities then demands that: T2->T1 and PD->T1
%   Expect order of modalities as: PET, T1, T2 and PD
% If exist segmented images are also resliced
%
% Configration (userConfig) for each resliced image as 'project.taskDone.configuration{ImageIndex,ModalityIndex}.'
%
% userConfig fields:
%       .method: One of {'linear','nearest','sinc'}
%       .SincParms.SincSize:
%       .SincParms.SincFac:
%       .resizeTo.ModalityIndex: Which modality should be used as target e.g. ->PET, ->MR
%       .resizeTo.fixedSize: All modalities to a given voxelsize
%       .hdrI:Input Analyze header
%       .hdrO: (resliced) Output Analyze header
%
% Special functions
%   ReadAir
%   ReadAnalyzeHdr
%   logProject
%____________________________________________
%By T. Dyrby, 010803, NRU
%SW version: 090903TD. By T. Dyrby, 010803, NRU

ImageIndex=1;

%__________________________ Load configuration ____________________________
project=logProject('Reslice: Loading configuration',project,TaskIndex,MethodIndex);

%_____ Set default configuration if not exist
if(isempty(project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.default))
    project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.default.method='linear';
    project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.default.SincParms.SincFac=[2 2 2];
    project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.default.SincParms.SincSize=[5 5 5];
    project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.default.resizeTo.ModalityIndex=[1];% Reslice to an image modality 'project.taskDone[TaskIndex].inputfiles.{ImageIndex,ModalityIndex}'
    project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.default.resizeTo.fixedSize=[3;3;3];% Reslice all to fixed voxel size
end
userConfig=project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.default;

if isempty(project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.user)
    project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.user=userConfig;
    project=logProject('No configuration exist. Default loaded',project,TaskIndex,MethodIndex);
else
    userConfig=project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.user;
end
%__________________________________________________________________________

%____ Check if sinc interpolation and Reslice selected
if strcmp(userConfig.method,'sinc') & strcmp(project.pipeline.taskSetup{TaskIndex,MethodIndex}.function_name,'Reslice')
    msg='Reslice method cannot use sinc-interpolation. Use ResliceAIR or ResliceWARP, or change interpolation method.';
    project=logProject(msg,project,TaskIndex,MethodIndex);
    project.taskDone{TaskIndex}.error{end+1}=msg;
    return
end

%____ Init matrix to Reslice function.
%Check for ->PET or -> MR or fixedSize
if(~isempty(userConfig.resizeTo.ModalityIndex) && userConfig.resizeTo.ModalityIndex>0)
    %Output size from modality
    nameTarget=project.taskDone{TaskIndex}.inputfiles{1,userConfig.resizeTo.ModalityIndex}.name;
    pathTarget=project.taskDone{TaskIndex}.inputfiles{1,userConfig.resizeTo.ModalityIndex}.path;
    TargetHdr=ReadAnalyzeHdr(fullfile('',pathTarget,nameTarget));
    
    %Loginfo
    msg=sprintf('Reslice: -->%s-space. ',project.pipeline.imageModality{userConfig.resizeTo.ModalityIndex});
    project=logProject(msg,project,TaskIndex,MethodIndex);
else
    %Fixed size
    TargetHdr.siz=userConfig.resizeTo.fixedSize';
    
    %Use the T1w MR scan as dim in output
    target_name=project.taskDone{TaskIndex}.inputfiles{1,2}.name;
    target_path=project.taskDone{TaskIndex}.inputfiles{1,2}.path;
    hdrI=ReadAnalyzeHdr(fullfile('',target_path,target_name));
    
    TargetHdr.dim=round(hdrI.dim.*hdrI.siz./TargetHdr.siz);
    
    userConfig.resizeTo.ModalityIndex=0;%Not used, all modalities are resliced
    
    %Loginfo
    msg=sprintf('Reslice: --->Fixed [%s]',num2str(userConfig.resizeTo.fixedSize));
    project=logProject(msg,project,TaskIndex,MethodIndex);
end

%Reslice PET->T1 or T1->PET
for(iModalityIndex=1:2)
    if(iModalityIndex==userConfig.resizeTo.ModalityIndex)
        %____ Do not reslice target image...waste of time!!
        nameTarget=project.taskDone{TaskIndex}.inputfiles{1,iModalityIndex}.name;
        pathTarget=project.taskDone{TaskIndex}.inputfiles{1,iModalityIndex}.path;
        
        project.taskDone{TaskIndex}.outputfiles{1,iModalityIndex}.name=nameTarget;
        project.taskDone{TaskIndex}.outputfiles{1,iModalityIndex}.path=pathTarget;
        
        continue
    end
    
    %____ Search for AIR file in 'project.taskDone{TaskIndex}.userdata'
    for(iTaskIndex=1:TaskIndex-1)
        if(isfield(project.taskDone{iTaskIndex}.userdata,'AIRfile'))
            
            % Co-registration matrix do not exist for this image...
            Si=size(project.taskDone{iTaskIndex}.userdata.AIRfile);
            if Si(2)<iModalityIndex | (isempty(project.taskDone{iTaskIndex}.userdata.AIRfile{ImageIndex,iModalityIndex}))
                %Load A inverse...
                if(userConfig.resizeTo.ModalityIndex & ...
                        ~isempty(project.taskDone{iTaskIndex}.userdata.AIRfile{ImageIndex,userConfig.resizeTo.ModalityIndex}))
                    
                    nameA=project.taskDone{iTaskIndex}.userdata.AIRfile{ImageIndex,userConfig.resizeTo.ModalityIndex}.name;
                    pathA=project.taskDone{iTaskIndex}.userdata.AIRfile{ImageIndex,userConfig.resizeTo.ModalityIndex}.path;
                    userConfig.A=ReadAir(fullfile('',pathA,nameA));
                    userConfig.A=inv(userConfig.A); % Use inversed matrix
                    
                    %Loginfo
                    project=logProject('Reslice: No coreg. matrix-> Use INVERSE matrix',project,TaskIndex,MethodIndex);
                else
                    userConfig.A=eye(4); %Use indentity matrix
                    
                    %Loginfo
                    project=logProject('Reslice: No coreg. matrix-> Use indentity matrix',project,TaskIndex,MethodIndex);
                end
                break
            end
            
            nameA=project.taskDone{iTaskIndex}.userdata.AIRfile{ImageIndex,iModalityIndex}.name;
            pathA=project.taskDone{iTaskIndex}.userdata.AIRfile{ImageIndex,iModalityIndex}.path;
            userConfig.A=ReadAir(fullfile('',pathA,nameA));
            break
        end
    end%for iTaskIndex
    
    %____ Read Hdr for input file
    rslc_name=project.taskDone{TaskIndex}.inputfiles{1,iModalityIndex}.name;
    rslc_path=project.taskDone{TaskIndex}.inputfiles{1,iModalityIndex}.path;
    
    %Get Header and convert input to 16bit, big-endian if method is ResliceAir or ResliceWarp
    if (strcmp(project.pipeline.taskSetup{TaskIndex,MethodIndex}.function_name,'ResliceAir') ||...
            strcmp(project.pipeline.taskSetup{TaskIndex,MethodIndex}.function_name,'ResliceWarp'))
        %ResliceAir and ResliceWarp has problems with other than 16bit
        %files. Therefore convert segmentation-output to 16bit.
        %PVE-method has problems with non-integer segmented files. So
        %dont mess with scale.
        [img,hdr]=ReadAnalyzeImg(fullfile('',rslc_path,rslc_name));
        
        %____Converting to 16bit
        if (hdr.pre==32) || (hdr.pre==64) || (hdr.pre==8) || ((hdr.pre == 16) && (hdr.lim(1) ~= 32767)) || ...
                ((hdr.pre == 16) && (hdr.lim(2) ~= -32768))
            MinImg=min(img(:));
            MaxImg=max(img(:));
            
            if (MinImg<-32768) || (MaxImg>32767) %only scale colors if necessary
                if (hdr.offset ~= 0)
                    img=img-hdr.offset;
                    MinImg=min(img(:));
                    MaxImg=max(img(:));
                end
                
                if (MinImg>=0) || ((MaxImg+1)>abs(MinImg))
                    Scale=32767/MaxImg;
                else
                    Scale=32768/abs(MinImg);
                end
                img=img*Scale;
                if (hdr.scale~=0)
                    hdr.scale=1/Scale*hdr.scale;
                else
                    hdr.scale=1/Scale;
                end
                hdr.offset=0;
            end
            
            hdr.lim=[32767 -32768];
            hdr.pre=16;
            
            %____16bit
            hdr.path=project.sysinfo.workspace;
            [tmp,newname]=fileparts(hdr.name);
            hdr.name=[newname,'_16bit'];
            %hdr.endian='ieee-be'; %ResliceAir and ResliceWarp needs big endian
            project=logProject(['Creating 16bit image: ',hdr.name,' from input, and using as new input...'],project,TaskIndex,MethodIndex);
            
            result=WriteAnalyzeImg(hdr,img);
            userConfig.hdrI=hdr;
            rslc_name=[hdr.name,'.img'];
            rslc_path=project.sysinfo.workspace;
            project.taskDone{TaskIndex}.inputfiles{1,iModalityIndex}.name=rslc_name;
            project.taskDone{TaskIndex}.inputfiles{1,iModalityIndex}.path=rslc_path;
        else
            userConfig.hdrI=hdr;
        end
        clear('img');
    else
        userConfig.hdrI=ReadAnalyzeHdr(fullfile('',rslc_path,rslc_name));
    end
    
    %____ Make output Hdr of resliced image
    userConfig.hdrO=userConfig.hdrI;
    rmfield(userConfig.hdrO,'endian');
    [t1,imgName,t2]=fileparts(project.taskDone{TaskIndex}.outputfiles{ImageIndex,iModalityIndex}.name);
    %userConfig.hdrO.name=[imgName,'.img'];
    userConfig.hdrO.name=imgName;
    userConfig.hdrO.path=project.taskDone{TaskIndex}.outputfiles{ImageIndex,iModalityIndex}.path;
    
    %New parametes for resliced image
    userConfig.hdrO.siz=TargetHdr.siz;
    userConfig.hdrO.dim(1:3)=TargetHdr.dim(1:3); %Only change first four dimensions
    userConfig.hdrO.origin=TargetHdr.origin;
    
    %     %_______ Save actual configuration into project
    %     project.taskDone{TaskIndex}.configuration{ImageIndex,iModalityIndex}=userConfig;
    
    % Log information
    msg=sprintf('Reslice: %s [%s %s %s] >>>> %s [%s %s %s]',rslc_name,...
        num2str(userConfig.hdrI.siz(1)),num2str(userConfig.hdrI.siz(2)),num2str(userConfig.hdrI.siz(3)),...
        userConfig.hdrO.name,...
        num2str(userConfig.hdrO.siz(1)),num2str(userConfig.hdrO.siz(2)),num2str(userConfig.hdrO.siz(3)));
    project=logProject(msg,project,TaskIndex,MethodIndex);
    
    %_______ Call reslicing method w. parameters from configurator
    feval(project.pipeline.taskSetup{TaskIndex,MethodIndex}.function_name,userConfig,userConfig.method,userConfig.SincParms);
    % function imgO=Reslice(Struct,[method]);
    % OR
    % function ResliceWarp(Struct,[method]);%NOTE: only on UNIX
    % OR
    % function ResliceAir(Struct,[method]);%NOTE: only on UNIX

    % Register output file for delition if task is redone
    project.taskDone{TaskIndex}.userdata.ReslImg{1}.name=[userConfig.hdrO.name '.img'];
    project.taskDone{TaskIndex}.userdata.ReslImg{1}.path=userConfig.hdrO.path;
    project.taskDone{TaskIndex}.userdata.ReslImg{1}.info='Reslice MR/PET image';
   
end%for iModalityIndex




%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Reslice T2 and PD %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%___ Make header for resized image and reslice all inputfiles
ImageIndex=1;
NoModalityIndex=length(project.pipeline.imageModality);

%___ Existy T2 and PD AND T1 resliced to PET, then reslice T2->PET and PD->PET
if(NoModalityIndex>2 & userConfig.resizeTo.ModalityIndex~=2)%T2: ModalityIndex==2
    
    %Loginfo
    project=logProject('Reslice: T2->PET and PD->PET',project,TaskIndex,MethodIndex);
    
    %Reslice T2 and PD w. coregistration matrix used for T1(modalityIndex==2)
    for(iModalityIndex=3:NoModalityIndex)
        
        %____ Read Hdr for input file
        rslc_name=project.taskDone{TaskIndex}.inputfiles{1,iModalityIndex}.name;
        rslc_path=project.taskDone{TaskIndex}.inputfiles{1,iModalityIndex}.path;
        
        
        %Get Header and convert input to 16bit, big-endian if method is ResliceAir or ResliceWarp
        if (strcmp(project.pipeline.taskSetup{TaskIndex,MethodIndex}.function_name,'ResliceAir') |...
                strcmp(project.pipeline.taskSetup{TaskIndex,MethodIndex}.function_name,'ResliceWarp'))
            %ResliceAir and ResliceWarp has problems with other than 16bit
            %files. Therefore convert segmentation-output to 16bit.
            %PVE-method has problems with non-integer segmented files. So
            %dont mess with scale.
            [img,hdr]=ReadAnalyzeImg(fullfile('',rslc_path,rslc_name));
            %____Converting to 16bit
            if (hdr.pre==32) | (hdr.pre==64) | (hdr.pre==8) | ((hdr.pre == 16) & (hdr.lim(1) ~= 32767)) | ((hdr.pre == 16) & (hdr.lim(2) ~= -32768))
                MinImg=min(img(:));
                MaxImg=max(img(:));
                
                if (MinImg<-32768) | (MaxImg>32767) %only scale colors if necessary
                    if (hdr.offset ~= 0)
                        img=img-hdr.offset;
                        MinImg=min(img(:));
                        MaxImg=max(img(:));
                    end
                    
                    if (MinImg>=0) | ((MaxImg+1)>abs(MinImg))
                        Scale=32767/MaxImg;
                    else
                        Scale=32768/abs(MinImg);
                    end
                    img=img*Scale;
                    if (hdr.scale~=0)
                        hdr.scale=1/Scale*hdr.scale;
                    else
                        hdr.scale=1/Scale;
                    end
                    hdr.offset=0;
                end
                
                hdr.lim=[32767 -32768];
                hdr.pre=16;
                
                %____16bit
                hdr.path=project.sysinfo.workspace;
                [tmp,newname]=fileparts(hdr.name);
                hdr.name=[newname,'_16bit'];
                %hdr.endian='ieee-be'; %ResliceAir and ResliceWarp needs big endian
                project=logProject(['Creating 16bit image: ',hdr.name,' from input, and using as new input...'],project,TaskIndex,MethodIndex);
                
                result=WriteAnalyzeImg(hdr,img);
                userConfig.hdrI=hdr;
                rslc_name=[hdr.name,'.img'];
                rslc_path=project.sysinfo.workspace;
                project.taskDone{TaskIndex}.inputfiles{1,iModalityIndex}.name=rslc_name;
                project.taskDone{TaskIndex}.inputfiles{1,iModalityIndex}.path=rslc_path;
                
            else
                userConfig.hdrI=ReadAnalyzeHdr(fullfile('',rslc_path,rslc_name));
            end
            clear('img');
        else
            userConfig.hdrI=ReadAnalyzeHdr(fullfile('',rslc_path,rslc_name));
        end
        
        
        %____ Make output Hdr of resliced image
        userConfig.hdrO=userConfig.hdrI;
        [t,userConfig.hdrO.name,t]=fileparts(project.taskDone{TaskIndex}.outputfiles{ImageIndex,iModalityIndex}.name);
        userConfig.hdrO.path=project.taskDone{TaskIndex}.outputfiles{ImageIndex,iModalityIndex}.path;
        
        if(isempty(TargetHdr.dim))
            %Calculate dim factor in Hdr if FixedSize...
            TargetHdr.dim=round((userConfig.hdrI.siz.*userConfig.hdrI.dim)./TargetHdr.siz);
        end
        
        %New parametes for resliced image
        userConfig.hdrO.siz=TargetHdr.siz;
        userConfig.hdrO.dim(1:3)=TargetHdr.dim(1:3);
        userConfig.hdrO.origin=TargetHdr.origin;
        
        
        %         %_______ Save actual configuration into project
        %         project.taskDone{TaskIndex}.configuration{ImageIndex,iModalityIndex}=userConfig;
        
        % Log information
        msg=sprintf('Reslice: %s [%s %s %s] >>>> %s [%s %s %s]',rslc_name,...
            num2str(userConfig.hdrI.siz(1)),num2str(userConfig.hdrI.siz(2)),num2str(userConfig.hdrI.siz(3)),...
            userConfig.hdrO.name,...
            num2str(userConfig.hdrO.siz(1)),num2str(userConfig.hdrO.siz(2)),num2str(userConfig.hdrO.siz(3)));
        project=logProject(msg,project,TaskIndex,MethodIndex);
        
        %_______ Call reslicing method w. parameters from configurator
        feval(project.pipeline.taskSetup{TaskIndex,MethodIndex}.function_name,userConfig,userConfig.method,userConfig.SincParms);
        % function imgO=Reslice(Struct,[method]);
        % OR
        % function ResliceWarp(Struct,[method]);%NOTE: only on UNIX
        % OR
        % function ResliceAir(Struct,[method]);%NOTE: only on UNIX

            % Register output file for delition if task is redone
        project.taskDone{TaskIndex}.userdata.ReslImg{1}.name=[userConfig.hdrO.name '.img'];
        project.taskDone{TaskIndex}.userdata.ReslImg{1}.path=userConfig.hdrO.path;
        project.taskDone{TaskIndex}.userdata.ReslImg{1}.info='Resliced T2/PD/.... image';

    end%for iModalityIndex
end%if exist T2 and PD




%%%%%%%%%%%%%%%%%%%%%%%%%%%%% Reslice segmented ->PET if T1->PET %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Search for segmented images if PREDEFINED: 'userdata.segout'
for(iTaskIndex=1:TaskIndex-1)
    if(~isempty(project.taskDone{iTaskIndex}) && isfield(project.taskDone{iTaskIndex}.userdata,'segout'))
        break
    end
    if(iTaskIndex==TaskIndex-1)
        project=logProject('No segmented images is found...',project,TaskIndex,MethodIndex);
        return
    end
end

%Check if PET is resliced to T1

if(userConfig.resizeTo.ModalityIndex==2)
    %No change to segmented images
    project.taskDone{TaskIndex}.userdata.segoutReslice=project.taskDone{iTaskIndex}.userdata.segout;
else
    
    %______Reslice (and align) all segemented images
    %Loginfo
    project=logProject('Reslice: Segmented->PET',project,TaskIndex,MethodIndex);
    
    %Number of segmented images (classes)
    NoSegIndex=length(project.taskDone{iTaskIndex}.userdata.segout);
    
    prefix=project.pipeline.taskSetup{TaskIndex}.prefix;
    
    for(iSegIndex=1:NoSegIndex)
        %____ Get inputfiles
        project.taskDone{TaskIndex}.userdata.segoutReslice{iSegIndex}.name=[prefix,'_',project.taskDone{iTaskIndex}.userdata.segout{iSegIndex}.name];
        project.taskDone{TaskIndex}.userdata.segoutReslice{iSegIndex}.path=project.sysinfo.workspace;
        project.taskDone{TaskIndex}.userdata.segoutReslice{iSegIndex}.info='Co-registrated and resliced to PET';
        rslc_name=project.taskDone{iTaskIndex}.userdata.segout{iSegIndex}.name;
        rslc_path=project.taskDone{iTaskIndex}.userdata.segout{iSegIndex}.path;
        
        %Get Header and convert input to 16bit, big-endian if method is ResliceAir or ResliceWarp
        if (strcmp(project.pipeline.taskSetup{TaskIndex,MethodIndex}.function_name,'ResliceAir') |...
                strcmp(project.pipeline.taskSetup{TaskIndex,MethodIndex}.function_name,'ResliceWarp'))
            %ResliceAir and ResliceWarp has problems with other than 16bit
            %files. Therefore convert segmentation-output to 16bit.
            %PVE-method has problems with non-integer segmented files. So
            %dont mess with scale.
            [img,hdr]=ReadAnalyzeImg(fullfile('',rslc_path,rslc_name));
            %____Converting to 16bit
            if (hdr.pre==32) || (hdr.pre==64) || (hdr.pre==8) || ((hdr.pre == 16) && (hdr.lim(1) ~= 32767)) ||...
                    ((hdr.pre == 16) && (hdr.lim(2) ~= -32768))
                MinImg=min(img(:));
                MaxImg=max(img(:));
                
                if (MinImg<-32768) || (MaxImg>32767) %only scale colors if necessary
                    if (hdr.offset ~= 0)
                        img=img-hdr.offset;
                        MinImg=min(img(:));
                        MaxImg=max(img(:));
                    end
                    
                    if (MinImg>=0) || ((MaxImg+1)>abs(MinImg))
                        Scale=32767/MaxImg;
                    else
                        Scale=32768/abs(MinImg);
                    end
                    img=img*Scale;
                    if (hdr.scale~=0)
                        hdr.scale=1/Scale*hdr.scale;
                    else
                        hdr.scale=1/Scale;
                    end
                    hdr.offset=0;
                end
                
                hdr.lim=[32767 -32768];
                hdr.pre=16;
                
                %____16bit
                hdr.path=project.sysinfo.workspace;
                [tmp,newname]=fileparts(hdr.name);
                hdr.name=[newname,'_16bit'];
                %hdr.endian='ieee-be'; %ResliceAir and ResliceWarp needs big endian
                project=logProject(['Creating 16bit image: ',hdr.name,' from input, and using as new input...'],project,TaskIndex,MethodIndex);
                
                result=WriteAnalyzeImg(hdr,img);
                userConfig.hdrI=hdr;
                rslc_name=[hdr.name,'.img'];
                rslc_path=project.sysinfo.workspace;
                
                %____ Register in project structure
                project.taskDone{TaskIndex}.userdata.realInput{iSegIndex}.name=rslc_name;
                project.taskDone{TaskIndex}.userdata.realInput{iSegIndex}.path=rslc_path;
                project.taskDone{TaskIndex}.userdata.realInput{iSegIndex}.info='16bit files used for reslicing, created from original segmented images';
                
            else
                userConfig.hdrI=ReadAnalyzeHdr(fullfile(rslc_path,rslc_name));
            end
            clear('img');
        else
            userConfig.hdrI=ReadAnalyzeHdr(fullfile(rslc_path,rslc_name));
        end
        
        %____ Make output Hdr of resliced image
        userConfig.hdrO=userConfig.hdrI;
        [path,nameOnly,ext]=fileparts(project.taskDone{TaskIndex}.userdata.segoutReslice{iSegIndex}.name);
        %userConfig.hdrO.name=[nameOnly,'.img'];
        userConfig.hdrO.name=nameOnly;
        userConfig.hdrO.path=project.taskDone{TaskIndex}.userdata.segoutReslice{iSegIndex}.path;
        
        if(isempty(TargetHdr.dim))
            %Calculate dim factor in Hdr if FixedSize...
            TargetHdr.dim=round((userConfig.hdrI.siz.*userConfig.hdrI.dim)./TargetHdr.siz);
        end
        
        %New parametes for resliced image
        userConfig.hdrO.siz=TargetHdr.siz;
        userConfig.hdrO.dim(1:3)=TargetHdr.dim(1:3);
        userConfig.hdrO.origin=TargetHdr.origin;
        
        
        %         %_______ Save actual configuration into project
        %         project.taskDone{TaskIndex}.configuration{ImageIndex,NoModalityIndex+iSegIndex}=userConfig;
        
        % Log information
        msg=sprintf('Reslice: %s [%s %s %s] >>>> %s [%s %s %s]',rslc_name,...
            num2str(userConfig.hdrI.siz(1)),num2str(userConfig.hdrI.siz(2)),num2str(userConfig.hdrI.siz(3)),...
            userConfig.hdrO.name,...
            num2str(userConfig.hdrO.siz(1)),num2str(userConfig.hdrO.siz(2)),num2str(userConfig.hdrO.siz(3)));
        project=logProject(msg,project,TaskIndex,MethodIndex);
        %_______ Call reslicing method w. parameters from configurator
        feval(project.pipeline.taskSetup{TaskIndex,MethodIndex}.function_name,userConfig,userConfig.method,userConfig.SincParms);
        % function imgO=Reslice(Struct,[method]);
        % OR
        % function ResliceWarp(Struct,[method]);%NOTE: only on UNIX
        % OR
        % function ResliceAir(Struct,[method]);%NOTE: only on UNIX
    end%for iModalityIndex
end%if res


