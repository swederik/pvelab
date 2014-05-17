function project=Atlas2_wrapper(project,TaskIndex,MethodIndex,varargin)
% Atlas2_wrapper function performs the MNI atlas based labeling
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
% M. Comerci, 16112005, IBB
%
% SW version: 1.0.13 16112005
% ____________________________________________

%_____ Show message in the log window
msg='MNI based ROI definition: progress data in Matlab command window...';
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
path1=[path0 filesep 'IBB_wrapper' filesep 'pve'];
cd (pathout);

%_____ Looking for segoutResliced field
taskidx=0;
for i=1:TaskIndex
    if isfield(project.taskDone{i},'userdata')
        if isfield(project.taskDone{i}.userdata,'segoutReslice')
            taskidx=i;
        end
    end
end

diary off
if taskidx==0
    [project,msg]=logProject('Error: can not find the segmented file names from reslice method.',project,TaskIndex,MethodIndex);
    project.taskDone{TaskIndex}.error{end+1}=msg;
    return
end

%_____ Copying input files to workspace
diary on
t1wpath=project.taskDone{TaskIndex}.inputfiles{ImageIndex,2}.path;
t1wname=project.taskDone{TaskIndex}.inputfiles{ImageIndex,2}.name;
[file_pathstr,file_name,file_ext] = fileparts(t1wname);

ffs=fullfile(t1wpath,t1wname);
ffd=fullfile(pathout,'r_volume.img');
if strcmp(ffs,ffd)==0
    copyfile(ffs,ffd);
end

ffs=fullfile(t1wpath,[file_name,'.hdr']);
ffd=fullfile(pathout,'r_volume.hdr');
if strcmp(ffs,ffd)==0
    copyfile(ffs,ffd);
end
seg1path=project.taskDone{taskidx}.userdata.segoutReslice{1}.path;
seg1name=project.taskDone{taskidx}.userdata.segoutReslice{1}.name;
[file_pathstr,file_name,file_ext] = fileparts(seg1name);

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

seg2path=project.taskDone{taskidx}.userdata.segoutReslice{2}.path;
seg2name=project.taskDone{taskidx}.userdata.segoutReslice{2}.name;
[file_pathstr,file_name,file_ext] = fileparts(seg2name);

ffs=fullfile(seg2path,seg2name);
ffd=fullfile(pathout,'r_volume_seg2.img');
if strcmp(ffs,ffd)==0
    copyfile(ffs,ffd);
end

ffs=fullfile(seg2path,[file_name,'.hdr']);
ffd=fullfile(pathout,'r_volume_seg2.hdr');
if strcmp(ffs,ffd)==0
    copyfile(ffs,ffd);
end

if isfield(project.taskDone{taskidx}.userdata.segoutReslice{3},'path')
    seg3path=project.taskDone{taskidx}.userdata.segoutReslice{3}.path;
    seg3name=project.taskDone{taskidx}.userdata.segoutReslice{3}.name;
    [file_pathstr,file_name,file_ext] = fileparts(seg3name);
    
    ffs=fullfile(seg3path,seg3name);
    ffd=fullfile(pathout,'r_volume_seg3.img');
    if strcmp(ffs,ffd)==0
        copyfile(ffs,ffd);
    end
    
    ffs=fullfile(seg3path,[file_name,'.hdr']);
    ffd=fullfile(pathout,'r_volume_seg3.hdr');
    if strcmp(ffs,ffd)==0
        copyfile(ffs,ffd);
    end
end

global defaults

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
            project=logProject('Atlas2_wrapper: SPM2 found.',project,TaskIndex,MethodIndex);
            SPM_ver=2;
        elseif (strcmpi(v,'spm5'))
            project=logProject('Atlas2_wrapper: SPM5 found.',project,TaskIndex,MethodIndex);
            SPM_ver=5;
        elseif (strcmpi(v,'spm8'))
            project=logProject('Atlas2_wrapper: SPM8 found.',project,TaskIndex,MethodIndex);
            SPM_ver=8;
        else
            project=logProject('Atlas2_wrapper: Wrong SPM version, SPM2/5/8 required. Download SPM at www.fil.ion.ucl.ac.uk/spm.',project,TaskIndex,MethodIndex);
        end
    otherwise
        msg='ERROR: SPM not recognized as .m-file.';
        project=logProject(msg,project,TaskIndex,MethodIndex);
        project.taskDone{TaskIndex}.error{end+1}=msg;
        return;
end

%_____ Set default configuration if it does not exist
if (isempty(project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.default))
    settings={'Y'};
    project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.default=settings;
end

%_____ Retrieve configuration parameters
if (isempty(project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.user))
    project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.user=project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.default;
end
settings=project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.user;

%_____ Write configuration file for the software
fid=fopen([path1 filesep 'config']);
i=1;
while ~feof(fid)
    c=deblank(fgetl(fid));
    config{i}=c;
    i=i+1;
end
fclose(fid);

fid=fopen([pathout 'config'],'w');
f1=0;
for k=1:i-1
    c=[config{k} '                  '];
    if strcmp(c(1:8),'ROIFile=');
        c=[c(1:8) 'MNI.DAT        '];
        f1=1;
    end
    fprintf(fid,'%s\n',deblank(c));
end
if f1==0
    fprintf(fid,'ROIFile=MNI.DAT\n');
end
fclose(fid);

%Set image orientation
%global defaults;
%defaults.analyze.flip=1; %Image orientation needed by SPM2 (values 0 or 1)

flags.smosrc=8;
flags.smoref=0;
flags.regtype='mni';
flags.cutoff=30;
flags.nits=0;
flags.reg=0.1;
cd(path1);
spm_defaults;
hdr=ReadAnalyzeHdr([project.sysinfo.workspace,filesep,'r_volume_seg1.hdr']);
hdr.origin=[0 0 0];
WriteAnalyzeHdr(hdr);

if (SPM_ver==2)
    spm_normalise('gray.mnc',[project.sysinfo.workspace,filesep,'r_volume_seg1.img'],[pathout,'sn.mat'],'','',flags);
elseif (SPM_ver==5)
    spm_normalise(fullfile(spm('Dir'),'apriori','grey.nii'),[project.sysinfo.workspace,filesep,'r_volume_seg1.img'],[pathout,'sn.mat'],'','',flags);
elseif (SPM_ver==8)
    spm_normalise(fullfile(spm('Dir'),'apriori','grey.nii'),[project.sysinfo.workspace,filesep,'r_volume_seg1.img'],[pathout,'sn.mat'],'','',flags);
else
    project=logProject('Atlas2_wrapper: Wrong SPM version, SPM2 or SPM5 required for normalization',project,TaskIndex,MethodIndex);
end


cd(pathout)
load sn
save -ASCII -DOUBLE sn.txt Affine
cd(path1)

feval('clear','global','defaults'); %Remove global spm defaults tree

%_____ Call to the program
if ismac
    if settings{1}=='Y'
        cmdline=['"' path1,filesep,'pvemac" -w -p -r "',pathout,'sn.mat" "',pathout,'r_volume_seg1.img"',' dummy',' "',fullfile(pathout,'config'),'"'];
    else
        cmdline=['"' path1,filesep,'pvemac" -k -p -r "',pathout,'sn.mat" "',pathout,'r_volume_seg1.img"',' dummy',' "',fullfile(pathout,'config'),'"'];
    end
else
    ccc=computer;
    suff='';
    if ccc(end)=='4'
        suff='64';
    end

    if settings{1}=='Y'
        cmdline=['"' path1,filesep,'pve',suff,'" -w -p -r "',pathout,'sn.mat" "',pathout,'r_volume_seg1.img"',' dummy',' "',fullfile(pathout,'config'),'"'];
    else
        cmdline=['"' path1,filesep,'pve',suff,'" -k -p -r "',pathout,'sn.mat" "',pathout,'r_volume_seg1.img"',' dummy',' "',fullfile(pathout,'config'),'"'];
    end
end
result=unix(cmdline);

diary off
if result~=0
    [project,msg]=logProject('Error in atlas method.',project,TaskIndex,MethodIndex);
    project.taskDone{TaskIndex}.error{end+1}=msg;
    return
end

%_____ Set up output file names
project.taskDone{TaskIndex}.userdata.atlas.name='r_volume_GMROI.img';
project.taskDone{TaskIndex}.userdata.atlas.path=project.sysinfo.workspace;
project.taskDone{TaskIndex}.userdata.atlas.info='Normalized labeled brain according to MNI space';

ffs=fullfile(path1,'MNI.DAT');
ffd=fullfile(project.sysinfo.workspace,'MNI.DAT');
if strcmp(ffs,ffd)==0
    copyfile(ffs,ffd);
end

copyfile(fullfile(path1,'config'),fullfile(pathout,'config_atlas_mni'));

project.taskDone{TaskIndex}.userdata.sn.path=project.sysinfo.workspace;
project.taskDone{TaskIndex}.userdata.sn.info='Trasformation matrix';
project.taskDone{TaskIndex}.userdata.sn.name='sn.mat';
project.taskDone{TaskIndex}.userdata.t1.path=project.sysinfo.workspace;
project.taskDone{TaskIndex}.userdata.t1.info='Registered T1-W image';
project.taskDone{TaskIndex}.userdata.t1.name='r_volume.img';
project.taskDone{TaskIndex}.userdata.seg1.path=project.sysinfo.workspace;
project.taskDone{TaskIndex}.userdata.seg1.info='registered segmented gray matter image';
project.taskDone{TaskIndex}.userdata.seg1.name='r_volume_seg1.img';
project.taskDone{TaskIndex}.userdata.seg2.path=project.sysinfo.workspace;
project.taskDone{TaskIndex}.userdata.seg2.info='registered segmented white matter image';
project.taskDone{TaskIndex}.userdata.seg2.name='r_volume_seg2.img';
project.taskDone{TaskIndex}.userdata.seg3.path=project.sysinfo.workspace;
project.taskDone{TaskIndex}.userdata.seg3.info='registered segmented CSF image';
project.taskDone{TaskIndex}.userdata.seg3.name='r_volume_seg3.img';
project.taskDone{TaskIndex}.userdata.map.name='MNI.DAT';
project.taskDone{TaskIndex}.userdata.map.path=project.sysinfo.workspace;
project.taskDone{TaskIndex}.userdata.map.info='Binary file containing the Talairach Atlas ROI''s codes';
project.taskDone{TaskIndex}.show=[];
cd(pathout);
