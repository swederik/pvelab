function project=PVE_wrapper(project,TaskIndex,MethodIndex,varargin)
% PVE_wrapper function performs the PVE correction step
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
%   unix        : To execute the C program "pve". NOTE: it works also under Windows (despite the name!).
%   diary       : To append the command window output also to a file.
% ____________________________________________
% M. Comerci, 08032004, IBB
%
% SW version: 1.0.11 08032004
% ____________________________________________

%_____ Show message in the log window
msg='PVE Correction: progress data in Matlab command window...';
project=logProject(msg,project,TaskIndex,MethodIndex);

%_____ Initialize
noModalities=length(project.pipeline.imageModality);
ImageIndex=project.pipeline.imageIndex(1);

%_____ Start command window logging
if(isempty(project.sysinfo.logfile.name))
    [pathstr,name,ext] = fileparts(project.sysinfo.prjfile);
    project.sysinfo.logfile.name=[name,'.log'];
end

diary([project.sysinfo.workspace filesep project.sysinfo.logfile.name]);
diary on

%_____ Costruct command line
path0=project.sysinfo.systemdir;
pathout=[project.sysinfo.workspace filesep];
if (isempty(path0))
    [pn,fn]=fileparts(which('pvelab'));
    path0=pn;
end;
path1=[path0 filesep 'IBB_wrapper' filesep 'pve'];
cd (pathout);

%_____ Looking for atlas field
taskidx=0;
for i=1:TaskIndex
    if isfield(project.taskDone{i},'userdata') & isfield(project.taskDone{i}.userdata,'atlas')
        taskidx=i;
    end
end

diary off
if taskidx==0
    [project,msg]=logProject('Error: can not find the atlas file name from atlas method.',project,TaskIndex,MethodIndex);
    project.taskDone{TaskIndex}.error{end+1}=msg;
    return
end

%_____ Copying input files to workspace
diary on
petpath=project.taskDone{TaskIndex}.inputfiles{ImageIndex,1}.path;
petname=project.taskDone{TaskIndex}.inputfiles{ImageIndex,1}.name;
%[file_pathstr,file_name,file_ext] = fileparts(petname);
%copyfile([petpath,filesep,petname],[pathout,'pet.img']);
%copyfile([petpath,filesep,file_name,'.hdr'],[pathout,'pet.hdr']);

gmroipath=project.taskDone{taskidx}.userdata.atlas.path;
gmroiname=project.taskDone{taskidx}.userdata.atlas.name;
[file_pathstr,file_name,file_ext] = fileparts(gmroiname);

ffs=fullfile(gmroipath,gmroiname);
ffd=fullfile(pathout,'r_volume_GMROI.img');
if strcmp(ffs,ffd)==0
    copyfile(ffs,ffd);
    project.taskDone{TaskIndex}.userdata.gmroi.path=project.sysinfo.workspace;
    project.taskDone{TaskIndex}.userdata.gmroi.info='Labeled GM image';
    project.taskDone{TaskIndex}.userdata.gmroi.name='r_volume_GMROI.img';
end

ffs=fullfile(gmroipath,[file_name,'.hdr']);
ffd=fullfile(pathout,'r_volume_GMROI.hdr');
if strcmp(ffs,ffd)==0
    copyfile(ffs,ffd);
end

%_____ Set default configuration if it does not exist
if(isempty(project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.default))
    settings={'LOBES_ROI.dat','Y','8.0','8.0','0.0','Y',140};
    project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.default=settings;
end

%_____ Retrieve configuration parameters
if(isempty(project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.user))
    project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.user=project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.default;
end
settings=project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.user;

mni='';
if isfield(project.taskDone{taskidx}.userdata,'sn')
    mni=[' -r "',fullfile(project.taskDone{taskidx}.userdata.sn.path,project.taskDone{taskidx}.userdata.sn.name),'"'];
    settings{1}='MNI.DAT';
else
    ffd=fullfile(pathout,'r_volume_GMROI.hdr');
    hdr=ReadAnalyzeHdr(ffd);
    mni=sprintf(' -cs %d',round(hdr.dim(3)*.33));
end

%_____ Set ROI-file information *************** ADDED BY NRU
if isfield(project.taskDone{taskidx}.userdata,'map')
    roiPath=project.taskDone{taskidx}.userdata.map.path;
    roiName=project.taskDone{taskidx}.userdata.map.name;
    settings{1}=fullfile(roiPath,roiName);
end

%_____ Write configuration file for the software
fid=fopen([path1 filesep 'config']);
i=1;
while ~feof(fid)
    c=deblank(fgetl(fid));
    config{i}=c;
    i=i+1;
end
fclose(fid);

fid=fopen([pathout filesep 'config'],'w');
f1=0;
f2=0;
f3=0;
f4=0;
f5=0;
f6=0;

for k=1:i-1
    c=[config{k} '                  '];
    if strcmp(c(1:8),'ROIFile=');
        c=[c(1:8) settings{1} '           '];
        f1=1;
    end
    if strcmp(c(1:12),'CSFAnalisys=');
        c=[c(1:12) settings{2} '           '];
        f2=1;
    end
    if strcmp(c(1:7),'FWHMXY=');
        c=[c(1:7) settings{3} '           '];
        f3=1;
    end
    if strcmp(c(1:6),'FWHMZ=');
        c=[c(1:6) settings{4} '           '];
        f4=1;
    end
    if strcmp(c(1:12),'OverCorrect=');
        c=[c(1:12) settings{5} '           '];
        f5=1;
    end
    if strcmp(c(1:12),'MethodsMask=');
        c=[c(1:12) num2str(settings{7}) '           '];
        f6=1;
    end
    fprintf(fid,'%s\n',deblank(c));
end
if f1==0
    fprintf(fid,'ROIFile=%s\n',deblank(settings{1}));
end
if f2==0
    fprintf(fid,'CSFAnalisys=%s\n',settings{2});
end
if f3==0
    fprintf(fid,'FWHMXY=%s\n',settings{3});
end
if f4==0
    fprintf(fid,'FWHMZ=%s\n',settings{4});
end
if f5==0
    fprintf(fid,'OverCorrect=%s\n',settings{5});
end
if f6==0
    fprintf(fid,'MethodsMask=%s\n',num2str(settings{7}));
end
fclose(fid);

% Check if sn.mat exist
if exist([pathout,'sn.mat'], 'file')==0
    project=logProject('PVE_wrapper: sn.mat not found. Calculating it...',project,TaskIndex,MethodIndex);
    try
        try
            seg1path=project.taskDone{taskidx-1}.userdata.segoutReslice{1}.path;
            seg1name=project.taskDone{taskidx-1}.userdata.segoutReslice{1}.name;
        catch
            seg1path=pathout;
            seg1name='r_volume_seg1.img';
        end
        [~,file_name,file_ext] = fileparts(seg1name);
        
        ffs=fullfile(seg1path,seg1name);
        ffd=fullfile(pathout,'r_volume_seg1.img');
        if strcmp(ffs,ffd)==0
            copyfile(ffs,ffd);
        end
        
        ffs=fullfile(seg1path,[file_name,'.hdr']);
        ffd=fullfile(pathout,'r_volume_seg1.hdr');
        if strcmp(ffs,ffd)==0
            copyfile(ffs,ffd);
        end
        SEG1f=[project.sysinfo.workspace,filesep,'r_volume_seg1.img'];
        %____Check if SPM2 exists
        switch exist('spm')
            case 0
                msg='ERROR: Can not find SPM. Addpath or download at www.fil.ion.ucl.ac.uk/spm.';
                project=logProject(msg,project,TaskIndex,MethodIndex);
                project.taskDone{TaskIndex}.error{end+1}=msg;
                return;
            case 2
                [v,c]=spm('Ver');
                if (strcmpi(v,'spm2'))
                    project=logProject('PVE_wrapper: SPM2 found.',project,TaskIndex,MethodIndex);
                    SPM_ver=2;
                elseif (strcmpi(v,'spm5'))
                    project=logProject('PVE_wrapper: SPM5 found.',project,TaskIndex,MethodIndex);
                    SPM_ver=5;
                elseif (strcmpi(v,'spm8'))
                    project=logProject('PVE_wrapper: SPM8 found.',project,TaskIndex,MethodIndex);
                    SPM_ver=8;
                else
                    project=logProject('PVE_wrapper: Wrong SPM version, SPM2/5/8 required. Download SPM at www.fil.ion.ucl.ac.uk/spm.',project,TaskIndex,MethodIndex);
                end
            otherwise
                msg='ERROR: SPM not recognized as .m-file.';
                project=logProject(msg,project,TaskIndex,MethodIndex);
                project.taskDone{TaskIndex}.error{end+1}=msg;
                return;
        end
        oldp=pwd;
        spm_fn=which('spm');
        [pn,fn,ext]=fileparts(spm_fn);
        if (SPM_ver==2)
            spm_template_fn=[pn filesep 'apriori' filesep 'gray.mnc'];
        elseif (SPM_ver==5)
            spm_template_fn=[pn filesep 'apriori' filesep 'grey.nii'];
        elseif (SPM_ver==8)
            spm_template_fn=[pn filesep 'apriori' filesep 'grey.nii'];
        else
            project=logProject('PVE_wrapper: Wrong SPM version, SPM2/5/8 required for normalization',project,TaskIndex,MethodIndex);
        end
        flags.smosrc=8;
        flags.smoref=0;
        flags.regtype='mni';
        flags.cutoff=30;
        flags.nits=0;
        flags.reg=0.1;
        global defaults
        spm_defaults;
        spm_normalise(spm_template_fn,SEG1f,[pathout,'sn.mat'],'','',flags);
        cd(pathout)
        load sn
    catch
        project=logProject('PVE_wrapper: could not calculate sn.mat: error finding files. CS slice results are inaccurate.',project,TaskIndex,MethodIndex);
        disp('PVE_wrapper: could not calculate sn.mat: error finding files. CS slice results are inaccurate.');
        Affine=eye(4);
    end
    save -ASCII -DOUBLE sn.txt Affine
    cd(oldp)
end

%_____ Call to the program
%cd(path1)
cd(path1);
load([pathout 'sn.mat'],'Affine');
save([pathout 'sn.mat'],'Affine','-V6');
if ismac
    if settings{6}=='Y'
        cmdline=['"' path1,filesep,'pvemac" -cse 2 -r "',pathout,'sn.mat" -w -s',mni,' "',pathout,'r_volume_GMROI.img" "',petpath,filesep,petname,'"',' "',fullfile(pathout,'config'),'"'];
    else
        cmdline=['"' path1,filesep,'pvemac" -cse 2 -r "',pathout,'sn.mat" -k -s',mni,' "',pathout,'r_volume_GMROI.img" "',petpath,filesep,petname,'"',' "',fullfile(pathout,'config'),'"'];
    end
else
    ccc=computer;
    suff='';
    if ccc(end)=='4'
        suff='64';
    end

    if settings{6}=='Y'
        cmdline=['"' path1,filesep,'pve',suff,'" -cse 2 -r "',pathout,'sn.mat" -w -s',mni,' "',pathout,'r_volume_GMROI.img" "',petpath,filesep,petname,'"',' "',fullfile(pathout,'config'),'"'];
    else
        cmdline=['"' path1,filesep,'pve',suff,'" -cse 2 -r "',pathout,'sn.mat" -k -s',mni,' "',pathout,'r_volume_GMROI.img" "',petpath,filesep,petname,'"',' "',fullfile(pathout,'config'),'"'];
    end
end
cmdline
result=unix(cmdline);
diary off
if result~=0
    [project,msg]=logProject('Error in PVEC method.',project,TaskIndex,MethodIndex);
    project.taskDone{TaskIndex}.error{end+1}=msg;
    return
end

movefile(fullfile(pathout,'config'),fullfile(pathout,'config_pvec'));

%_____ Set up output file names
midx=0;
project.taskDone{TaskIndex}.show=[];
if exist([pathout,'r_volume_Meltzer.img'],'file')
    midx=midx+1;
    project.taskDone{TaskIndex}.userdata.pvec{midx}.name='r_volume_Meltzer.img';
    project.taskDone{TaskIndex}.userdata.pvec{midx}.path=project.sysinfo.workspace;
    project.taskDone{TaskIndex}.userdata.pvec{midx}.info='Recovered activity map according to Meltzer method';
end

if exist([pathout,'r_volume_MGCS.img'],'file')
    midx=midx+1;
    project.taskDone{TaskIndex}.userdata.pvec{midx}.name='r_volume_MGCS.img';
    project.taskDone{TaskIndex}.userdata.pvec{midx}.path=project.sysinfo.workspace;
    project.taskDone{TaskIndex}.userdata.pvec{midx}.info='Recovered activity map according to Mueller-Gartner method, CS WMA';
end

if exist([pathout,'r_volume_MGRousset.img'],'file')
    midx=midx+1;
    project.taskDone{TaskIndex}.userdata.pvec{midx}.name='r_volume_MGRousset.img';
    project.taskDone{TaskIndex}.userdata.pvec{midx}.path=project.sysinfo.workspace;
    project.taskDone{TaskIndex}.userdata.pvec{midx}.info='Recovered activity map according to Mueller-Gartner method, Rousset WMA';
end

if exist([pathout,'r_volume_MGAlfano.img'],'file')
    midx=midx+1;
    project.taskDone{TaskIndex}.userdata.pvec{midx}.name='r_volume_MGAlfano.img';
    project.taskDone{TaskIndex}.userdata.pvec{midx}.path=project.sysinfo.workspace;
    project.taskDone{TaskIndex}.userdata.pvec{midx}.info='Recovered activity map according to Mueller-Gartner method, Alfano WMA';
end

if exist([pathout,'r_volume_AlfanoCS.img'],'file')
    midx=midx+1;
    project.taskDone{TaskIndex}.userdata.pvec{midx}.name='r_volume_AlfanoCS.img';
    project.taskDone{TaskIndex}.userdata.pvec{midx}.path=project.sysinfo.workspace;
    project.taskDone{TaskIndex}.userdata.pvec{midx}.info='Recovered activity map according to PVEOut method, CS WMA';
end

if exist([pathout,'r_volume_AlfanoRousset.img'],'file')
    midx=midx+1;
    project.taskDone{TaskIndex}.userdata.pvec{midx}.name='r_volume_AlfanoRousset.img';
    project.taskDone{TaskIndex}.userdata.pvec{midx}.path=project.sysinfo.workspace;
    project.taskDone{TaskIndex}.userdata.pvec{midx}.info='Recovered activity map according to PVEOut method, Rousset WMA';
end

if exist([pathout,'r_volume_AlfanoAlfano.img'],'file')
    midx=midx+1;
    project.taskDone{TaskIndex}.userdata.pvec{midx}.name='r_volume_AlfanoAlfano.img';
    project.taskDone{TaskIndex}.userdata.pvec{midx}.path=project.sysinfo.workspace;
    project.taskDone{TaskIndex}.userdata.pvec{midx}.info='Recovered activity map according to PVEOut method, Alfano WMA';
end

if exist([pathout,'r_volume_PSF.img'],'file')
    midx=midx+1;
    project.taskDone{TaskIndex}.userdata.pvec{midx}.name='r_volume_PSF.img';
    project.taskDone{TaskIndex}.userdata.pvec{midx}.path=project.sysinfo.workspace;
    project.taskDone{TaskIndex}.userdata.pvec{midx}.info='Centered estimated point spread function';
end

if exist([pathout,'r_volume_Virtual_PET.img'],'file')
    midx=midx+1;
    project.taskDone{TaskIndex}.userdata.pvec{midx}.name='r_volume_Virtual_PET.img';
    project.taskDone{TaskIndex}.userdata.pvec{midx}.path=project.sysinfo.workspace;
    project.taskDone{TaskIndex}.userdata.pvec{midx}.info='Simulated PET from segmented';
end

if exist([pathout,'r_volume_CSWMROI.img'],'file')
    midx=midx+1;
    project.taskDone{TaskIndex}.userdata.pvec{midx}.name='r_volume_CSWMROI.img';
    project.taskDone{TaskIndex}.userdata.pvec{midx}.path=project.sysinfo.workspace;
    project.taskDone{TaskIndex}.userdata.pvec{midx}.info='Semiovale WM region definition used for calculating WM mean value';
end

if exist([pathout,'r_volume_seg1.img'],'file')
    midx=midx+1;
    project.taskDone{TaskIndex}.userdata.pvec{midx}.name='r_volume_seg1.img';
    project.taskDone{TaskIndex}.userdata.pvec{midx}.path=project.sysinfo.workspace;
    project.taskDone{TaskIndex}.userdata.pvec{midx}.info='r_volume_seg1.img MR GM prop map';
end

project.taskDone{TaskIndex}.outputfiles{1}.name=project.taskDone{TaskIndex}.inputfiles{1}.name;
project.taskDone{TaskIndex}.outputfiles{1}.path=project.taskDone{TaskIndex}.inputfiles{1}.path;
project.taskDone{TaskIndex}.outputfiles{1}.info=project.taskDone{TaskIndex}.inputfiles{1}.info;
project.taskDone{TaskIndex}.outputfiles{2}.name=project.taskDone{TaskIndex}.inputfiles{2}.name;
project.taskDone{TaskIndex}.outputfiles{2}.path=project.taskDone{TaskIndex}.inputfiles{2}.path;
project.taskDone{TaskIndex}.outputfiles{2}.info=project.taskDone{TaskIndex}.inputfiles{2}.info;

[roiPath,roiName,roiExt]=fileparts(settings{1});
roiName=[roiName,roiExt];
if ~(exist(fullfile(project.sysinfo.workspace,roiName), 'file')==2)
    ffs=settings{1};
    ffd=fullfile(project.sysinfo.workspace,roiName);
    copyfile(ffs,ffd);
    %.dat file will be copied to project dir after pve correction,
    %therefore record in project structure.
    project.taskDone{TaskIndex}.userdata.roi.name=roiName;
    project.taskDone{TaskIndex}.userdata.roi.path=project.sysinfo.workspace;
    project.taskDone{TaskIndex}.userdata.roi.info='Text file containing list of ROI codes and corresponding names';
end

if exist([pathout,'r_volume_Occu_Meltzer.img'],'file')
    project.taskDone{TaskIndex}.userdata.occumeltz.path=project.sysinfo.workspace;
    project.taskDone{TaskIndex}.userdata.occumeltz.info='Meltzer occupancy map';
    project.taskDone{TaskIndex}.userdata.occumeltz.name='r_volume_Occu_Meltzer.img';
end

if exist([pathout,'r_volume_Occu_MG.img'],'file')
    project.taskDone{TaskIndex}.userdata.occumg.path=project.sysinfo.workspace;
    project.taskDone{TaskIndex}.userdata.occumg.info='Mueller Gartner / PVEOut occupancy map';
    project.taskDone{TaskIndex}.userdata.occumg.name='r_volume_Occu_MG.img';
end

if exist([pathout,'r_volume_Rousset.Mat'],'file')
    midx=midx+1;
    project.taskDone{TaskIndex}.userdata.pvec{midx}.name='r_volume_Rousset.Mat';
    project.taskDone{TaskIndex}.userdata.pvec{midx}.path=project.sysinfo.workspace;
    project.taskDone{TaskIndex}.userdata.pvec{midx}.info='Rousset method matrix';
end

if exist([pathout,'r_volume_pve.txt'],'file')
    midx=midx+1;
    project.taskDone{TaskIndex}.userdata.pvec{midx}.name='r_volume_pve.txt';
    project.taskDone{TaskIndex}.userdata.pvec{midx}.path=project.sysinfo.workspace;
    project.taskDone{TaskIndex}.userdata.pvec{midx}.info='Text file with detailed results from the active methods';
end

if exist([pathout,'sn.mat'],'file')
    midx=midx+1;
    project.taskDone{TaskIndex}.userdata.pvec{midx}.name='sn.mat';
    project.taskDone{TaskIndex}.userdata.pvec{midx}.path=project.sysinfo.workspace;
    project.taskDone{TaskIndex}.userdata.pvec{midx}.info='sn.mat file created during PVE correction';
end

if exist([pathout,'sn.txt'],'file')
    midx=midx+1;
    project.taskDone{TaskIndex}.userdata.pvec{midx}.name='sn.txt';
    project.taskDone{TaskIndex}.userdata.pvec{midx}.path=project.sysinfo.workspace;
    project.taskDone{TaskIndex}.userdata.pvec{midx}.info='sn.txt file created during PVE correction';
end

if exist([pathout,'config_pvec'],'file')
    midx=midx+1;
    project.taskDone{TaskIndex}.userdata.pvec{midx}.name='config_pvec';
    project.taskDone{TaskIndex}.userdata.pvec{midx}.path=project.sysinfo.workspace;
    project.taskDone{TaskIndex}.userdata.pvec{midx}.info='Configuration file for PVE correction';
end

cd(pathout);
