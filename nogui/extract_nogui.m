function project=extract_nogui(project,TaskIndex,MethodIndex,varargin)
% This wrapper is called by the pipeline program to extract data from
% the PVE corrected data files.
% 
% By Claus Svarer, NRU, 20071012
% Improved, 20120131, CS
%

%____________________________Load settings________________________________

%Defaults doesn't exist

%ImageIndex for future multiimageset expansion
ImageIndex=1;

%Get PET inputfiles
PETf=fullfile(project.taskDone{1}.outputfiles{ImageIndex,1}.path,project.taskDone{1}.outputfiles{ImageIndex,1}.name);

%_____ Looking for r_GMWM file field
%_____ Looking for Common ROI file
taskidx=0;
for i=1:TaskIndex
    if isfield(project.taskDone{i},'userdata') && isfield(project.taskDone{i}.userdata,'CommonRoi')
        taskidx=i;
    end

end
if taskidx~=0    % Common ROI file exist and applyrois method used
    CommonRoif=fullfile(project.taskDone{taskidx}.userdata.CommonRoi.path,project.taskDone{taskidx}.userdata.CommonRoi.name);
    %
    taskidx=0;
    for i=1:TaskIndex
        if isfield(project.taskDone{i},'userdata') && isfield(project.taskDone{i}.userdata,'r_GMWM')
            taskidx=i;
        end
    end
    r_GMWMf=fullfile(project.taskDone{taskidx}.userdata.r_GMWM.path,project.taskDone{taskidx}.userdata.r_GMWM.name);
else             % Other method than applyrois used, use instead r_volume_RAWATLAS
    % r_volume_GMROI has to be converted to voxvoi NRU format
    ROIfile=fullfile(project.sysinfo.workspace,'r_volume_GMROI');
    ROIname=fullfile(project.sysinfo.workspace,'ROI_names.DAT');
    CommonRoif=fullfile(project.sysinfo.workspace,'IBB_roi_voxvoi');
    ConvertIBB2voxvoi(ROIfile,ROIname,CommonRoif);
    %
    % Registration of Naples roi file converted to voxvoi file format
    %
    project.taskDone{TaskIndex}.userdata.VoxVoi.path=project.sysinfo.workspace;
    project.taskDone{TaskIndex}.userdata.VoxVoi.name=[CommonRoif '.img'];
    project.taskDone{TaskIndex}.userdata.VoxVoi.info='Naples regions converted to NRU voxvoi format';
    %
    taskidx=0;
    for i=1:TaskIndex
        if isfield(project.taskDone{i},'userdata') && isfield(project.taskDone{i}.userdata,'segoutReslice')
            taskidx=i;
        end
    end
    if taskidx==0
         error('No segmentation files available');
    else
         ReslSegm=project.taskDone{taskidx}.userdata.segoutReslice{1}.name;
         pos=strfind(ReslSegm,'_seg1');
         ReslSegm=ReslSegm(1:pos(1)-1);
         CurDir=pwd;
         cd(project.sysinfo.workspace);
         spmsegm2mask(ReslSegm,'','','','001');
         cd(CurDir);
         r_GMWMf=[ReslSegm '_GM_WM.img'];
         %
         % Registration of resliced segmentation file 
         %
         project.taskDone{TaskIndex}.userdata.rGMWM.path=project.sysinfo.workspace;
         project.taskDone{TaskIndex}.userdata.rGMWM.name=r_GMWMf;
         project.taskDone{TaskIndex}.userdata.rGMWM.info='Resliced GM_WM file r_<MR filename>_GM_WM';
    end
end

%_____ Looking for pve correction file field
taskidx=0;
for i=1:TaskIndex
    if isfield(project.taskDone{i},'userdata') && isfield(project.taskDone{i}.userdata,'pvec')
        taskidx=i;
    end
end
r_vol_Meltzer=[];
r_vol_MGCS=[];
r_vol_MGRousset=[];
r_vol_MGAlfano=[];
r_vol_AlfanoAlfano=[];
r_vol_AlfanoCS=[];
r_vol_AlfanoRousset=[];
if (taskidx~=0)
    for i=1:length(project.taskDone{taskidx}.userdata.pvec)
        if ~isempty(strfind(project.taskDone{taskidx}.userdata.pvec{i}.name,'r_volume_Meltzer'))
           r_vol_Meltzer=fullfile(project.taskDone{taskidx}.userdata.pvec{i}.path,project.taskDone{taskidx}.userdata.pvec{i}.name);
        elseif ~isempty(strfind(project.taskDone{taskidx}.userdata.pvec{i}.name,'r_volume_MGCS'))
           r_vol_MGCS=fullfile(project.taskDone{taskidx}.userdata.pvec{i}.path,project.taskDone{taskidx}.userdata.pvec{i}.name);        
        elseif ~isempty(strfind(project.taskDone{taskidx}.userdata.pvec{i}.name,'r_volume_MGRousset'))
           r_vol_MGRousset=fullfile(project.taskDone{taskidx}.userdata.pvec{i}.path,project.taskDone{taskidx}.userdata.pvec{i}.name);
        elseif ~isempty(strfind(project.taskDone{taskidx}.userdata.pvec{i}.name,'r_volume_MGAlfano'))
           r_vol_MGAlfano=fullfile(project.taskDone{taskidx}.userdata.pvec{i}.path,project.taskDone{taskidx}.userdata.pvec{i}.name);
        elseif ~isempty(strfind(project.taskDone{taskidx}.userdata.pvec{i}.name,'r_volume_AlfanoAlfano'))
           r_vol_AlfanoAlfano=fullfile(project.taskDone{taskidx}.userdata.pvec{i}.path,project.taskDone{taskidx}.userdata.pvec{i}.name);
        elseif ~isempty(strfind(project.taskDone{taskidx}.userdata.pvec{i}.name,'r_volume_AlfanoCS'))
           r_vol_AlfanoCS=fullfile(project.taskDone{taskidx}.userdata.pvec{i}.path,project.taskDone{taskidx}.userdata.pvec{i}.name);
        elseif ~isempty(strfind(project.taskDone{taskidx}.userdata.pvec{i}.name,'r_volume_AlfanoRousset'))
           r_vol_AlfanoRousset=fullfile(project.taskDone{taskidx}.userdata.pvec{i}.path,project.taskDone{taskidx}.userdata.pvec{i}.name);
        end
    end
end  

%_____ Creating text output file
project.taskDone{TaskIndex}.userdata.ExtractResult.path=project.sysinfo.workspace;
project.taskDone{TaskIndex}.userdata.ExtractResult.info='Extracted data, raw PET and volume';
project.taskDone{TaskIndex}.userdata.ExtractResult.name='ExtractedData.txt';

ExtractDataf=fullfile(project.taskDone{TaskIndex}.userdata.ExtractResult.path,project.taskDone{TaskIndex}.userdata.ExtractResult.name);

%_____ Files to extract data from
VolumeFiles{1}=PETf;
VolumeName{1}='Raw PET';
n=2;
if ~isempty(r_vol_Meltzer)
    VolumeFiles{n}=r_vol_Meltzer;
    VolumeName{n}='Meltzer';
    n=n+1;
end 
if ~isempty(r_vol_MGCS)
    VolumeFiles{n}=r_vol_MGCS;
    VolumeName{n}='MG CS';
    n=n+1;
end 
if ~isempty(r_vol_MGRousset)
    VolumeFiles{n}=r_vol_MGRousset;
    VolumeName{n}='MG Rousset';
    n=n+1;
end 
if ~isempty(r_vol_MGAlfano)
    VolumeFiles{n}=r_vol_MGAlfano;
    VolumeName{n}='MG Alfano';
    n=n+1;
end 
if ~isempty(r_vol_AlfanoAlfano)
    VolumeFiles{n}=r_vol_AlfanoAlfano;
    VolumeName{n}='Alfano Alfano';
    n=n+1;
end 
if ~isempty(r_vol_AlfanoCS)
    VolumeFiles{n}=r_vol_AlfanoCS;
    VolumeName{n}='Alfano CS';
    n=n+1;
end 
if ~isempty(r_vol_AlfanoRousset)
    VolumeFiles{n}=r_vol_AlfanoRousset;
    VolumeName{n}='Alfano Rousset';
    n=n+1;
end 

%_____ Call applyroisExtractData
project=logProject('Running voxvoi/editroiGetData. Progress is shown in matlab window...',project,TaskIndex,MethodIndex);

[pn,fn]=fileparts(CommonRoif);
if (exist(fullfile(pn,[fn '.mat']),'file')==2)
    project=logProject('Running editroiGetData. Progress is shown in matlab window...',project,TaskIndex,MethodIndex);

    [~,Data]=editroiGetData(CommonRoif,VolumeFiles,[],r_GMWMf,0);
else
    project=logProject('Running voxvoiGetData. Progress is shown in matlab window...',project,TaskIndex,MethodIndex);

    [~,Data]=voxvoiGetData(fullfile(pn,[fn '.img']),VolumeFiles,[],r_GMWMf,0);
end

PrintResult(Data,ExtractDataf,VolumeName,VolumeFiles,CommonRoif,r_GMWMf);
pause(1);


function PrintResult(Data,ExtractDataf,VolumeName,VolumeFiles,CommonRoif,GMWMf)
%
% Function that creates data files with results
%
pid=fopen(ExtractDataf,'w');
if (pid==-1)
    error('Not possible to open results file');
end
%
if (~iscell(Data))
    Tmp{1}=Data;
    Data=Tmp;
end
%
% Document date user and so on
%
fprintf(pid,'#Date: %s\n',datestr(clock));
if ispc
    fprintf(pid,'#User: %s\n',getenv('USERNAME'));
    fprintf(pid,'#Host: %s\n',getenv('COMPUTERNAME'));
else
    fprintf(pid,'#User: %s\n',getenv('USER'));
    fprintf(pid,'#Host: %s\n',getenv('HOST'));
end
fprintf(pid,'#Comp: %s\n',computer);
fprintf(pid,'\n');
%
% Document which files used
%
fprintf(pid,'Data extracted from the following files:\n');
for i=1:length(VolumeFiles)
   fprintf(pid,'   %s\n',VolumeFiles{i});
end
fprintf(pid,'\nusing segmentation from:\n   %s\n',GMWMf);
fprintf(pid,'\nand regions from:\n   %s\n\n',CommonRoif);

%
% Document volumes
%
fprintf(pid,'Volumes\n');
for j=0:5
    switch j
        case 0,
            fprintf(pid,'\t');
        case 1,
            fprintf(pid,'Total\t');
        case 2,
            fprintf(pid,'GM\t');
        case 3,
            fprintf(pid,'WM\t');
        case 4,
            fprintf(pid,'CSF\t');
        case 5,
            fprintf(pid,'BG\t');
        otherwise
            error('');
    end
    for i=1:size(Data{1},1)
        if j==0
            fprintf(pid,'%s\t',Data{1}(i,1).Name);
        else
            fprintf(pid,'%i\t',Data{1}(i,j).Volume);
        end
    end
    fprintf(pid,'\n');
end
fprintf(pid,'\n');
%
% Document roi mean (all voxels)
%
for j=1:5
fprintf(pid,'%s\n',VolumeName{1});
    switch j
        case 1,
            fprintf(pid,'Total\n');
        case 2,
            fprintf(pid,'GM\n');
        case 3,
            fprintf(pid,'WM\n');
        case 4,
            fprintf(pid,'CSF\n');
        case 5,
            fprintf(pid,'BG\n');
        otherwise
            error('');
    end
    fprintf(pid,'\t');
    for i=1:size(Data{1},1)
        fprintf(pid,'%s\t',Data{1}(i,1).Name);
    end
    fprintf(pid,'\n');
    for k=1:length(Data{1}(1,1).Mean)
        fprintf(pid,'Frame %i:\t',k);
        for i=1:size(Data{1},1)
            fprintf(pid,'%e\t',Data{1}(i,j).Mean(k));
        end
        fprintf(pid,'\n');
    end
    fprintf(pid,'\n');
end
fprintf(pid,'\n');
%
% Document corrected roi mean for GM voxels
%
for j=2:length(VolumeName)
    fprintf(pid,'%s\n',VolumeName{j});
    fprintf(pid,'GM\n');
    fprintf(pid,'\t');
    for i=1:size(Data{1},1)
        fprintf(pid,'%s\t',Data{1}(i,1).Name);
    end
    fprintf(pid,'\n');
    for k=1:length(Data{1}(1,1).Mean)  % Loop over time frames
        fprintf(pid,'Frame %i:\t',k);
        for i=1:size(Data{1},1) % Loop over regions
            fprintf(pid,'%e\t',Data{j}(i,2).Mean(k)); % Only GM, so index=2
        end
        fprintf(pid,'\n');
    end
    fprintf(pid,'\n\n');
end
fprintf(pid,'\n');
%
fclose(pid);


function ConvertIBB2voxvoi(ROIfile,ROIname,CommonRoif)
%
% Function that converts IBB VOI's into voxvoi (NRU) format
%
[voi,hdr]=ReadAnalyzeImg(ROIfile);
%
rois=unique(voi);
%
% Ones below 10 is GM/WM and not labels
% 0 - BG
% 2 - WM
% 3 - GM (without a label)
% Should be ignored in voxvoi file, this information is read from the
% GM_WM file
%
rois=rois(rois>=10);
%
newvoi=zeros(size(voi));
for i=1:length(rois)
    newvoi(voi==rois(i))=i;
end
hdr.pre=8;
hdr.lim=[255 0];
hdr.origin=[0,0,0];
hdr.scale=1;
hdr.offset=0;
hdr.descr='Converted r_volume_GMROI file';
[pn,fn,ext]=fileparts(CommonRoif);
hdr.path=pn;
hdr.name=fn;
WriteAnalyzeImg(hdr,newvoi);
%
count=0;
pid=fopen(ROIname,'r');
while ~feof(pid)
    tline = fgetl(pid);
    if count~=0   %Remove 1st line
        ss=strfind(tline,sprintf('\t'));
        voinumber(count)=sscanf(tline(1:ss(1)-1),'%i');
        voiname{count}=tline(ss(1)+1:ss(2)-1);
    end
    count=count+1; 
end
fclose(pid);
%
descrfile=fullfile(pn,[fn '.descr']);
pid=fopen(descrfile,'w');
for i=1:length(rois)
    pos=find(voinumber==rois(i));
    Name=voiname{pos(1)};
    fprintf(pid,'%i, "%s"\n',i,Name);
end
fclose(pid);