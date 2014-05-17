function project=applyRois_wrapper(project,TaskIndex,MethodIndex,varargin)
% This wrapper is called by the pipeline program to run the
% applyrois method on the loaded PET and MR.
%
% By Thomas Rask, NRU, 190104
%

%Check for Image processing toolbox function roipoly.m
if isempty(which('roipoly.m'))
    msg='Error: The function ''roipoly'' in the image processing toolbox is required to run applyrois.';
    project=logProject(msg,project,TaskIndex,MethodIndex);
    project.taskDone{TaskIndex}.error{end+1}=msg;
    return;
end

%____________________________Load settings________________________________

%Defaults settings exist?
if(isempty(project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.default))
    % No defaults exists... create
    %_____ Define ROIsets
    RoiSets.BundleRoi='nru_all';
    sysDir=project.sysinfo.systemdir;
    stdDir=[sysDir,filesep,'NRU_lib',filesep,'applyrois',filesep,'stdrois',filesep,RoiSets.BundleRoi];
    if ~exist(stdDir,'file')
        [pn,fn]=fileparts(which('applyrois'));
        stdDir=[pn,filesep,'stdrois',filesep,RoiSets.BundleRoi];
    end
    %Select 10 non-atrophytemplates or as many as available
    k=1;
    while (k<=10)
        TemplDir=[stdDir,filesep,sprintf('n%02i',k)];
        if (exist(TemplDir,'dir')~=0)
            RoiSets.Sets{k}=TemplDir;
            k=k+1;
        else
            k=11;
        end
    end
    RoiSets.SetName='roi';
    RoiSets.TemplateType='T1';
    
    project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.default.RoiSets=RoiSets;
end
userConfig=project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.default;

% User defined setting exist?
if(isempty(project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.user))
    %User settings does not exist in project, use default
    project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.user=userConfig;
else
    %User settings do exist
    userConfig=project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.user;
end;

%____________________________Handle GUI____________________________________


%ImageIndex for future multiimageset expansion
ImageIndex=1;

%Get inputfiles
MRf=fullfile(project.taskDone{1}.outputfiles{ImageIndex,2}.path,project.taskDone{1}.outputfiles{ImageIndex,2}.name);
PETf=fullfile(project.taskDone{1}.outputfiles{ImageIndex,1}.path,project.taskDone{1}.outputfiles{ImageIndex,1}.name);

[MRpath,MRname]=fileparts(MRf);
[PETpath,PETname]=fileparts(PETf);

%_____ Looking for segout field
taskidx=0;
for i=1:TaskIndex
    if isfield(project.taskDone{i},'userdata') && isfield(project.taskDone{i}.userdata,'segout')
        taskidx=i;
    end
end

SEG1f=fullfile(project.taskDone{taskidx}.userdata.segout{1}.path,project.taskDone{taskidx}.userdata.segout{1}.name);
SEG2f=fullfile(project.taskDone{taskidx}.userdata.segout{2}.path,project.taskDone{taskidx}.userdata.segout{2}.name);
SEG3f=fullfile(project.taskDone{taskidx}.userdata.segout{3}.path,project.taskDone{taskidx}.userdata.segout{3}.name);

%Generate Masked MR (MR without surroundings) and GM_WM-file
origDir=pwd;
cd(project.sysinfo.workspace);

project=logProject(['Creating Masked- and Gray matter White matter images...'],project,TaskIndex,MethodIndex);
Stat=spmsegm2mask(MRf,SEG1f,SEG2f,SEG3f,'011');

if ~Stat
    msg='Error: Masked file could not be created from segmented files! Make sure seg-files are SPM2-format.';
    project=logProject(msg,project,TaskIndex,MethodIndex);
    project.taskDone{TaskIndex}.error{end+1}=msg;
    return;
end

GMWMname=[MRname,'_GM_WM'];
MASKname=[MRname,'_masked'];

%project=logProject(['Moving outputfile: ',[GMWMname,'.img'],' to project dir.'],project,TaskIndex,MethodIndex);
%movefile(fullfile(MRpath,[GMWMname,'.*']),project.sysinfo.workspace);
project.taskDone{TaskIndex}.userdata.GM_WM.path=project.sysinfo.workspace;
project.taskDone{TaskIndex}.userdata.GM_WM.info='Gray matter - White matter image';
project.taskDone{TaskIndex}.userdata.GM_WM.name=[GMWMname,'.img'];

%project=logProject(['Moving outputfile: ',[MASKname,'.img'],' to project dir.'],project,TaskIndex,MethodIndex);
%movefile(fullfile(MRpath,[MASKname,'.*']),project.sysinfo.workspace);
project.taskDone{TaskIndex}.userdata.MaskedMR.path=project.sysinfo.workspace;
project.taskDone{TaskIndex}.userdata.MaskedMR.info='Masked MRI (no surroundings)';
project.taskDone{TaskIndex}.userdata.MaskedMR.name=[MASKname,'.img'];


%Find airfile
%_____ Looking for segout field
taskidx=0;
for i=1:TaskIndex
    if isfield(project.taskDone{i},'userdata') && isfield(project.taskDone{i}.userdata,'AIRfile')
        taskidx=i;
    end
end

Si=size(project.taskDone{taskidx}.userdata.AIRfile);
for n=1:Si(2)
    Hold=project.taskDone{taskidx}.userdata.AIRfile{ImageIndex,n};
    if ~isempty(Hold)
        AIRf=fullfile(Hold.path,Hold.name);
        if exist(AIRf,'file')==2
            break;
        end
    end
end

% ____ Decide whether editroi or voxroi defintions of regions that are
% going to be used
[pn,fn,ext]=fileparts(fullfile(userConfig.RoiSets.Sets{1},userConfig.RoiSets.SetName));
if (strcmp(ext,'.mat')==1) || (exist(fullfile(pn,[fn '.mat']),'file')==2)
    editroiTypeVOI=1;
else
    editroiTypeVOI=0;
end

%_____ Call applyRois
project=logProject(['Running applyrois. Progress is shown in matlab window...'],project,TaskIndex,MethodIndex);
if (isfield(userConfig,'ApplyroisDef'))
    ApplyroisDef=userConfig.ApplyroisDef;
else
    ApplyroisDef={};
end

%_____ Make parallel processing mode available if possible
ParMode=0;
if license('test','distrib_computing_toolbox')
    if license('checkout','distrib_computing_toolbox')
        s = findResource('scheduler','type','local');
        j = s.findJob('State','running');
        if isempty(j)
            % No jobs running
            fprintf('\nRunning program in parallel mode\n');
            ParMode=1;
            % Error resolution to be sure not to have a common scheduler dir if
            % multiple jobs started at the same time
            %sched=findResource('scheduler','type','local');
            %TmpDir=tempname(sched.DataLocation);
            %mkdir(TmpDir);
            %sched.DataLocation=TmpDir;
            %
            if (matlabpool('size')==0)
                matlabpool;
            end
        else
            % A job is running, take some kind of action
            fprintf('\nYou are already using parallel mode in another session, running program in sequential mode\n');
        end
    else
        fprintf('\nThe parallel computing toolbox is in use, running program in sequential mode\n');
    end
else
    fprintf('\nThe parallel computing toolbox is not installed, running program in sequential mode\n');
end

applyrois(fullfile(PETpath,PETname),fullfile(project.sysinfo.workspace,MASKname),AIRf,userConfig.RoiSets,'','',0,ApplyroisDef);
pause(1);
try
    rmdir([pwd,filesep,'tmp_applyrois'],'s');
catch
    disp(['Could not remove temporary dir in: ', pwd])
end

%register output from applyrois
templDir=userConfig.RoiSets.BundleRoi;

dispFieldName=['invdisplacementfield.vol']; %Analyze file
ResMRName='ResliceMR'; %.txt file
WarpName='warp'; %.log file

Sets=userConfig.RoiSets.Sets;
for k=1:length(Sets)
    q=find(Sets{k}==filesep);
    singleRoi=Sets{k};
    singleRoi=singleRoi(q(end)+1:end);
    singleRoiName{k}=[singleRoi,'ROI2',PETname]; %.mat file
    
    %project=logProject(['Moving outputfile: ',[n01RoiName,'.mat'],' to project dir.'],project,TaskIndex,MethodIndex);
    % movefile(fullfile(PETpath,[n01RoiName,'.mat']),project.sysinfo.workspace);
    project.taskDone{TaskIndex}.userdata.singleRoi{k}.path=project.sysinfo.workspace;
    project.taskDone{TaskIndex}.userdata.singleRoi{k}.info=['Roi for ',singleRoi];
    if editroiTypeVOI==1
        project.taskDone{TaskIndex}.userdata.singleRoi{k}.name=[singleRoiName{k},'.mat'];
    else
        project.taskDone{TaskIndex}.userdata.singleRoi{k}.name=[singleRoiName{k},'.img'];
        project.taskDone{TaskIndex}.userdata.singleRoiDescr{k}.path=project.sysinfo.workspace;
        project.taskDone{TaskIndex}.userdata.singleRoiDescr{k}.info=['Description for Roi set ',singleRoi];
        project.taskDone{TaskIndex}.userdata.singleRoiDescr{k}.name=[singleRoiName{k},'.descr'];
    end
end
if length(singleRoiName)==1
    CommonRoiName=singleRoiName{1};
else
    CommonRoiName=['CommonROI',templDir,'2',PETname]; %.mat file
end
%project=logProject(['Moving outputfile: ',[CommonRoiName,'.mat'],' to project dir.'],project,TaskIndex,MethodIndex);
%movefile(fullfile(PETpath,[CommonRoiName,'.mat']),project.sysinfo.workspace);

project.taskDone{TaskIndex}.userdata.CommonRoi.path=project.sysinfo.workspace;
project.taskDone{TaskIndex}.userdata.CommonRoi.info='Common Roi - average of all used templates.';
if editroiTypeVOI==1
    project.taskDone{TaskIndex}.userdata.CommonRoi.name=[CommonRoiName,'.mat'];
    %
    % Decide if there is significant overlap (decided to be 5%) in any region
    % then not really well suited for Rousset method
    %
    if ~isempty(strfind(computer,'64'))
       Overlap=editroiTestOverlap(fullfile(project.sysinfo.workspace,CommonRoiName),...
           fullfile(PETpath,PETname));
       if any(Overlap>0.05)
           fprintf('\nSignificant overlap (>0.05) detected for one or more regions - NOT well suited for Rousset PVE correction\n\n');
       end
    else
        fprintf('32 bit matlab version no test for overlap between regions available, could be a potential problem for Rousset method\n');
        fprintf('  please test yourself\\n');
    end
else
    project.taskDone{TaskIndex}.userdata.CommonRoi.name=[CommonRoiName,'.img'];
    project.taskDone{TaskIndex}.userdata.CommonRoiDescr.path=project.sysinfo.workspace;
    project.taskDone{TaskIndex}.userdata.CommonRoiDescr.info='Description for Common Roi set.';
    project.taskDone{TaskIndex}.userdata.CommonRoiDescr.name=[CommonRoiName,'.descr'];
    %
    % As is the voxvoi Volumes is not bit volumes so there is not chance
    % of overlap and no reason for testing for problem with overlapping
    % VOI's
    %
    % Decide if there is significant overlap (decided to be 97.5%) in any region
    % then not really well suited for Rousset method
    %
    %Overlap=voxvoiTestOverlap(fullfile(project.sysinfo.workspace,CommonRoiName));
    %if any(Overlap>0.975)
    %    fprintf('\nSignificant overlap (>0.975) detected for one or more regions - NOT well suited for Rousset PVE correction\n\n');
    %end
end

%_____ Stop use of parallel processing toolbox
if ParMode==1
    matlabpool close;
end

%project=logProject(['Moving outputfile: ',[dispFieldName,'.img'],' to project dir.'],project,TaskIndex,MethodIndex);
movefile(fullfile(pwd,[dispFieldName,'.hdr']),fullfile(pwd,[dispFieldName(1:end-4),'.hdr']),'f');
movefile(fullfile(pwd,[dispFieldName,'.img']),fullfile(pwd,[dispFieldName(1:end-4),'.img']),'f');
project.taskDone{TaskIndex}.userdata.dispField.path=project.sysinfo.workspace;
project.taskDone{TaskIndex}.userdata.dispField.info='Displacementfield';
project.taskDone{TaskIndex}.userdata.dispField.name=[dispFieldName(1:end-4),'.img'];

%project=logProject(['Moving outputfile: ',[ResMRName,'.txt'],' to project dir.'],project,TaskIndex,MethodIndex);
% movefile(fullfile(pwd,[ResMRName,'.txt']),project.sysinfo.workspace,'f');
project.taskDone{TaskIndex}.userdata.ResliceTxt.path=project.sysinfo.workspace;
project.taskDone{TaskIndex}.userdata.ResliceTxt.info='Reslice info';
project.taskDone{TaskIndex}.userdata.ResliceTxt.name=[ResMRName,'.txt'];

%project=logProject(['Moving outputfile: ',[WarpName,'.log'],' to project dir.'],project,TaskIndex,MethodIndex);
% movefile(fullfile(pwd,[WarpName,'.log']),project.sysinfo.workspace,'f');
project.taskDone{TaskIndex}.userdata.WarpLog.path=project.sysinfo.workspace;
project.taskDone{TaskIndex}.userdata.WarpLog.info='Warping log';
project.taskDone{TaskIndex}.userdata.WarpLog.name=[WarpName,'.log'];

%______ Reslice GM_WM_file
r_GMWMname=['r_',GMWMname];

%Set headers
[A,airStruct]=ReadAir(AIRf);
PEThdr=ReadAnalyzeHdr(PETf);
hdrI=ReadAnalyzeHdr(fullfile(project.sysinfo.workspace,[GMWMname,'.img']));
hdrI.path=project.sysinfo.workspace;
hdrO=hdrI;
hdrO.name=r_GMWMname;
hdrO.dim=PEThdr.dim(1:3);
hdrO.origin=PEThdr.origin;
hdrO.siz=PEThdr.siz;
Struct.hdrI=hdrI;
Struct.hdrO=hdrO;

%Set matrix
if all(airStruct.hdrI.dim(1:3)==hdrI.dim(1:3)) && all(airStruct.hdrI.siz(1:3)==hdrI.siz(1:3))
    Struct.A=A;
else
    Struct.A=inv(A);
end

%Call reslice
project=logProject(['Reslicing GM_WM-file...'],project,TaskIndex,MethodIndex);
Reslice(Struct,'nearest');
project.taskDone{TaskIndex}.userdata.r_GMWM.path=project.sysinfo.workspace;
project.taskDone{TaskIndex}.userdata.r_GMWM.info='Resliced gray- and white matter';
project.taskDone{TaskIndex}.userdata.r_GMWM.name=[r_GMWMname,'.img'];

%____ Copy r_volume file (r_MR) needed by pve-method (reslice if necessary)
%find Reslice taskno
Si=size(project.pipeline.taskSetup);
for rTask=1:Si(1)
    if strcmp(project.pipeline.taskSetup{rTask,1}.task,'Reslicing')
        break;
    end
end
if project.pipeline.statusTask(rTask)==2 %reslice done
    [Path,Name]=fileparts(fullfile(project.taskDone{rTask}.outputfiles{ImageIndex,2}.path,project.taskDone{rTask}.outputfiles{ImageIndex,2}.name));
    copyfile(fullfile(Path,[Name,'.img']),fullfile(project.sysinfo.workspace,'r_volume.img'));
    copyfile(fullfile(Path,[Name,'.hdr']),fullfile(project.sysinfo.workspace,'r_volume.hdr'));
    project.taskDone{TaskIndex}.userdata.r_MR.path=project.sysinfo.workspace;
    project.taskDone{TaskIndex}.userdata.r_MR.info='Resliced MRI';
    project.taskDone{TaskIndex}.userdata.r_MR.name='r_volume.img';
else
    %______ Reslice GM_WM_file
    r_name=['r_volume'];
    
    %Set headers
    [A,airStruct]=ReadAir(AIRf);
    PEThdr=ReadAnalyzeHdr(PETf);
    hdrI=ReadAnalyzeHdr(MRf);
    hdrI.path=MRpath;
    hdrO=hdrI;
    hdrO.name=r_name;
    hdrO.path=project.sysinfo.workspace;
    hdrO.dim=PEThdr.dim(1:3);
    hdrO.origin=PEThdr.origin;
    hdrO.siz=PEThdr.siz;
    Struct.hdrI=hdrI;
    Struct.hdrO=hdrO;
    
    %Set matrix
    if all(airStruct.hdrI.dim(1:3)==hdrI.dim(1:3)) && all(airStruct.hdrI.siz(1:3)==hdrI.siz(1:3))
        Struct.A=A;
    else
        Struct.A=inv(A);
    end
    
    %Call reslice
    project=logProject(['Reslicing MR-file...'],project,TaskIndex,MethodIndex);
    Reslice(Struct,'linear');
    project.taskDone{TaskIndex}.userdata.r_MR.path=project.sysinfo.workspace;
    project.taskDone{TaskIndex}.userdata.r_MR.info='Resliced MRI';
    project.taskDone{TaskIndex}.userdata.r_MR.name='r_volume.img';
end



%______ Final step: create the GMROI-file with textfile

project=logProject(['Creating analyze image from found ROIs...'],project,TaskIndex,MethodIndex);
if editroiTypeVOI==1
    fprintf('Debug: editroi2pve is called\n');
    editroi2pve(fullfile(project.sysinfo.workspace,[CommonRoiName,'.mat']),PETf,fullfile(project.sysinfo.workspace,[r_GMWMname,'.img']),[PETname,'_GMWM_ROI']);
else
    fprintf('Debug: voxvoi2pve is called\n');
    voxvoi2pve(fullfile(project.sysinfo.workspace,[CommonRoiName,'.img']),fullfile(project.sysinfo.workspace,[r_GMWMname,'.img']),[PETname,'_GMWM_ROI']);
end

project.taskDone{TaskIndex}.userdata.GMWM_ROI.path=project.sysinfo.workspace;
project.taskDone{TaskIndex}.userdata.GMWM_ROI.info='Gray matter/ White matter ROI';
project.taskDone{TaskIndex}.userdata.GMWM_ROI.name=[PETname,'_GMWM_ROI.img'];

project.taskDone{TaskIndex}.userdata.GMWM_ROI_descr.path=project.sysinfo.workspace;
project.taskDone{TaskIndex}.userdata.GMWM_ROI_descr.info='Description of regions in GMWM_ROI.';
project.taskDone{TaskIndex}.userdata.GMWM_ROI_descr.name=[PETname,'_GMWM_ROI.descr'];

%_____ Convert to italy format
fil = textread(fullfile(project.sysinfo.workspace,[PETname,'_GMWM_ROI.descr']),'%s','delimiter','\n','whitespace','');
fid=fopen(fullfile(project.sysinfo.workspace,[PETname,'_GM_ROI.dat']),'w+');
fprintf(fid,'%s\n','Report ROI coding # and ROI Name, separated by a <Tab> hereinafter, with no space at the end');
for k=1:length(fil)
    str=char(fil(k));
    komma=strfind(str,',');
    if komma(1)==2 && ~(str(1)=='2')
        continue;
    end
    Number=str2num(str(1:komma(1)-1))+60;
    %replace spaces with underscore
    str(strfind(str,' '))='_';
    %text
    txtLabel=str(komma(1)+3:end-1);
    if strcmp(txtLabel,'Gray_matter')
        txtLabel='GM_no_region';
    end
    %Select color
    colour=dec2hex(round(((2^24-1)/length(fil))*k));
    %Write to new file
    fprintf(fid,['%s\t%s\t%s\n'],num2str(Number),txtLabel,num2str(colour));
end
fclose(fid);
project.taskDone{TaskIndex}.userdata.map.path=project.sysinfo.workspace;
project.taskDone{TaskIndex}.userdata.map.info='Description of regions in GM_ROI.';
project.taskDone{TaskIndex}.userdata.map.name=[PETname,'_GM_ROI.dat'];


%_____ Remove white matter and csf and fat from image
[Img,Hdr]=ReadAnalyzeImg(fullfile(project.sysinfo.workspace,[PETname,'_GMWM_ROI.img']));
Img=Img+60;
Img(Img==60)=0; %Nothing
Img(Img==61)=3; %CSF
%Img(Img==62)=62; % (Actually PVE sets this to value 1 = Not labeled Gray matter, but applyrois gives a big amount of unlabeled GM)
Img(Img==63)=2; %White matter
Img(Img==64)=1; %Not labeled Gray matter  (applyrois value 4=fat and other tissue. But pve has no value for this tissue so set to no_labelGM (disregarded by pve))
Hdr.name=[PETname,'_GM_ROI'];
Hdr.path=project.sysinfo.workspace;
Hdr.pre=8;
Hdr.lim=[255 0];
Hdr.dim=Hdr.dim(1:3);
Hdr.endian='ieee-le';
WriteAnalyzeImg(Hdr,Img);

project.taskDone{TaskIndex}.userdata.atlas.path=project.sysinfo.workspace;
project.taskDone{TaskIndex}.userdata.atlas.info='Gray matter ROI.';
project.taskDone{TaskIndex}.userdata.atlas.name=[PETname,'_GM_ROI.img'];


cd(origDir);
