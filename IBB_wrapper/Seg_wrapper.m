function project=Seg_wrapper(project,TaskIndex,MethodIndex,varargin)
% Seg_wrapper function performs the QMCI based segmentation
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
%   unix        : To execute the C program "volume". NOTE: it works also under Windows (despite the name!).
%   diary       : To append the command window output also to a file.
% ____________________________________________
% M. Comerci, 23092003, IBB
%
% SW version: 1.0.17a 09022004
% ____________________________________________

%_____ Show message in the log window
msg='Segmentation: progress data in Matlab command window...';
project=logProject(msg,project,TaskIndex,MethodIndex);

%_____ Initialize
noModalities=length(project.pipeline.imageModality);
ImageIndex=project.pipeline.imageIndex(1);

%_____ Check number of MRI scans
if noModalities<4
    [project,msg]=logProject('Error: you need at least three MRI series to use this module.',project,TaskIndex,MethodIndex);
    project.taskDone{TaskIndex}.error{end+1}=msg;
    return
end

%_____ Start command window logging
if(isempty(project.sysinfo.logfile.name))
    [pathstr,name,ext] = fileparts(project.sysinfo.prjfile);
    project.sysinfo.logfile.name=[name,'.log'];
end

diary([project.sysinfo.workspace filesep project.sysinfo.logfile.name]);
diary on

flag=1;

%_____ Check for required data
for(i=2:noModalities)
    if not (isfield(project.taskDone{TaskIndex}.inputfiles{ImageIndex,i}.info,'patientName'))
        flag=0;
    end
    if not (isfield(project.taskDone{TaskIndex}.inputfiles{ImageIndex,i}.info,'studyDate'))
        flag=0;
    end
    if not (isfield(project.taskDone{TaskIndex}.inputfiles{ImageIndex,i}.info,'TR'))
        flag=0;
    end
    if not (isfield(project.taskDone{TaskIndex}.inputfiles{ImageIndex,i}.info,'TE'))
        flag=0;
    end
    if not (isfield(project.taskDone{TaskIndex}.inputfiles{ImageIndex,i}.info,'rescaleIntercept'))
        flag=0;
    end
    if not (isfield(project.taskDone{TaskIndex}.inputfiles{ImageIndex,i}.info,'rescaleSlope'))
        flag=0;
    end
    if not (isfield(project.taskDone{TaskIndex}.inputfiles{ImageIndex,i}.info,'flipAngle'))
        flag=0;
    end
    if not (isfield(project.taskDone{TaskIndex}.inputfiles{ImageIndex,i}.info,'magneticField'))
        flag=0;
    end
end

diary off
if flag==0
    [project,msg]=logProject('Error: missing data in at least one MRI series.',project,TaskIndex,MethodIndex);
    project.taskDone{TaskIndex}.error{end+1}=msg;
    return
end

diary on
%_____ Costruct command line
path0=project.sysinfo.systemdir;
pathout=[project.sysinfo.workspace filesep];
path1=[path0 filesep 'IBB_wrapper' filesep 'volume'];
copyfile(fullfile(path1,'config'),pathout);

%_____ Set default configuration if it does not exist
if(isempty(project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.default))
    settings={'320.0','Y','Y','N','1.0'};
    project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.default=settings;
end

%_____ Retrieve configuration parameters
if(isempty(project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.user))
    project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.user=project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.default;
end
settings=project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.user;

%_____ Write configuration file for the software
fid=fopen([pathout filesep 'config']);
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

for k=1:i-1
    c=[config{k} '                  '];
    if strcmp(c(1:8),'PDNoise=');
        c=[c(1:8) settings{1} '       '];
        f1=1;
    end
    if strcmp(c(1:8),'DrawBox=');
        c=[c(1:8) settings{2} '       '];
        f2=1;
    end
    if strcmp(c(1:9),'GaussFit=');
        c=[c(1:9) settings{3} '       '];
        f3=1;
    end
    fprintf(fid,'%s\n',deblank(c));
end
if f1==0
    fprintf(fid,'PDNoise=%s\n',settings{1});
end
if f2==0
    fprintf(fid,'DrawBox=%s\n',settings{2});
end
if f3==0
    fprintf(fid,'GaussFit%s\n',settings{3});
end
fclose(fid);

%_____ Copying input files to workspace
% delete([pathout '*.img']);
% delete([pathout '*.hdr']);
% delete([pathout '*.dat']);
t1th=num2str(round(str2num(settings{1})));
imgth=num2str(round(str2num(settings{1})/4));
[file_pathstr,t1name,file_ext] = fileparts(project.taskDone{TaskIndex}.inputfiles{ImageIndex,2}.name);
[file_pathstr,t2name,file_ext] = fileparts(project.taskDone{TaskIndex}.inputfiles{ImageIndex,3}.name);
[file_pathstr,pdname,file_ext] = fileparts(project.taskDone{TaskIndex}.inputfiles{ImageIndex,4}.name);
for(i=2:noModalities)
    [file_pathstr,file_name,file_ext] = fileparts(project.taskDone{TaskIndex}.inputfiles{ImageIndex,i}.name);
    %     copyfile([project.taskDone{TaskIndex}.inputfiles{ImageIndex,i}.path,filesep,file_name,'.img'],pathout);
    %     copyfile([project.taskDone{TaskIndex}.inputfiles{ImageIndex,i}.path,filesep,file_name,'.hdr'],pathout);
    %     copyfile([project.taskDone{TaskIndex}.inputfiles{ImageIndex,i}.path,filesep,file_name,'.dat'],pathout);
    if (settings{4}=='Y') & (i==2)
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
                    project=logProject('Seg_wrapper: SPM2 found.',project,TaskIndex,MethodIndex);
                    SPM_ver=2;
                elseif (strcmpi(v,'spm5'))
                    project=logProject('Seg_wrapper: SPM5 found.',project,TaskIndex,MethodIndex);
                    SPM_ver=5;
                else
                    project=logProject('Seg_wrapper: Wrong SPM version, SPM2 or SPM5 required. Download SPM at www.fil.ion.ucl.ac.uk/spm.',project,TaskIndex,MethodIndex);
                end
            otherwise
                msg='ERROR: SPM not recognized as .m-file.';
                project=logProject(msg,project,TaskIndex,MethodIndex);
                project.taskDone{TaskIndex}.error{end+1}=msg;
                return;
        end
        msg='Segmentation: realigning T1-W...';
        project=logProject(msg,project,TaskIndex,MethodIndex);
        global defaults
        spm_defaults;
        
        x=spm_coreg([pathout t1name '.img'],[pathout pdname '.img']);
        
        flags2.mean=0;
        flags2.interp=1;
        flags2.wrap=[0 0 0];
        M=spm_matrix(x);
        
        MM1=spm_get_space([pathout t1name '.img']);
        spm_get_space([pathout t1name '.img'],M*MM1);
        
        %        MM1=spm_get_space([pathout t2name '.img']);
        %        spm_get_space([pathout t2name '.img'],M*MM1);
        
        %        MM1=spm_get_space([pathout pdname '.img']);
        %        spm_get_space([pathout pdname '.img'],M*MM1);
        
        spm_reslice({[pathout pdname '.img'],[pathout t2name '.img'],[pathout t1name '.img']},flags2);
        
        [t1w,hdr1]=ReadAnalyzeImg([pathout,'r',t1name,'.img']);
        [t2w,hdr2]=ReadAnalyzeImg([pathout,'r',t2name,'.img']);
        [pdw,hdr3]=ReadAnalyzeImg([pathout,'r',pdname,'.img']);
        t1w(isnan(t1w))=0;
        t2w(t1w==0)=0;
        pdw(t1w==0)=0;
        hdr1.name=[pathout,t1name];
        hdr2.name=[pathout,t2name];
        hdr3.name=[pathout,pdname];
        delete([pathout,'*.mat']);
        delete([pathout,'r',t1name,'.*']);
        delete([pathout,'r',t2name,'.*']);
        delete([pathout,'r',pdname,'.*']);
        WriteAnalyzeImg(hdr1,t1w);
        WriteAnalyzeImg(hdr2,t2w);
        WriteAnalyzeImg(hdr3,pdw);
    end
end

%_____ Call to the program
if ismac
    cmdline=['"' path1,filesep,'volumemac" -f "',pathout(1:end-1),'" "',pathout(1:end-1),'" ',settings{5},' "',fullfile(pathout,'config'),'"'];
else
    cmdline=['"' path1,filesep,'volume" -f "',pathout(1:end-1),'" "',pathout(1:end-1),'" ',settings{5},' "',fullfile(pathout,'config'),'"'];
end
cd(path1);
result=unix(cmdline);

delete([pathout 'MR_*']);
movefile(fullfile(pathout,'config'),fullfile(pathout,'config_volume'));

diary off
if not(result==0)
    [project,msg]=logProject('Error in segmentation module.',project,TaskIndex,MethodIndex);
    project.taskDone{TaskIndex}.error{end+1}=msg;
    return
end

%_____ Set up output file names
diary on
project.taskDone{TaskIndex}.userdata.segout{1}.path=project.sysinfo.workspace;
project.taskDone{TaskIndex}.userdata.segout{2}.path=project.sysinfo.workspace;
project.taskDone{TaskIndex}.userdata.segout{3}.path=project.sysinfo.workspace;
project.taskDone{TaskIndex}.userdata.segout{1}.info='Segmented Gray Matter';
project.taskDone{TaskIndex}.userdata.segout{2}.info='Segmented White Matter';
project.taskDone{TaskIndex}.userdata.segout{3}.info='Segmented CSF';
project.taskDone{TaskIndex}.userdata.segout{1}.name='volume_seg1.img';
project.taskDone{TaskIndex}.userdata.segout{2}.name='volume_seg2.img';
project.taskDone{TaskIndex}.userdata.segout{3}.name='volume_seg3.img';

project.taskDone{TaskIndex}.userdata.volumes.path=project.sysinfo.workspace;
project.taskDone{TaskIndex}.userdata.volumes.info='Text file specifing the volume measures of each ROI';
project.taskDone{TaskIndex}.userdata.volumes.name='VOLUMES.DAT';
project.taskDone{TaskIndex}.userdata.air.path=project.sysinfo.workspace;
project.taskDone{TaskIndex}.userdata.air.info='AIR file generated to align T2-W and PD-W to T1-W image';
project.taskDone{TaskIndex}.userdata.air.name='air';
project.taskDone{TaskIndex}.userdata.t1.path=project.sysinfo.workspace;
project.taskDone{TaskIndex}.userdata.t1.info='T1-W image, useful for displaying';
project.taskDone{TaskIndex}.userdata.t1.name='volume.img';
project.taskDone{TaskIndex}.userdata.pd.path=project.sysinfo.workspace;
project.taskDone{TaskIndex}.userdata.pd.info='PD map image';
project.taskDone{TaskIndex}.userdata.pd.name='volume_PD.img';
project.taskDone{TaskIndex}.userdata.r1.path=project.sysinfo.workspace;
project.taskDone{TaskIndex}.userdata.r1.info='R1 map image';
project.taskDone{TaskIndex}.userdata.r1.name='volume_R1.img';
project.taskDone{TaskIndex}.userdata.r2.path=project.sysinfo.workspace;
project.taskDone{TaskIndex}.userdata.r2.info='R2 map image';
project.taskDone{TaskIndex}.userdata.r2.name='volume_R2.img';

cd ([project.sysinfo.workspace]);
diary off
project.taskDone{TaskIndex}.show{1,1}.name='R1R2T.TIF';
project.taskDone{TaskIndex}.show{1,1}.path=project.sysinfo.workspace;
project.taskDone{TaskIndex}.show{1,1}.info='Voxel distribution, R1 - R2 plane';
project.taskDone{TaskIndex}.show{1,2}.name='R1PDT.TIF';
project.taskDone{TaskIndex}.show{1,2}.path=project.sysinfo.workspace;
project.taskDone{TaskIndex}.show{1,2}.info='Voxel distribution, R1 - PD plane';
project.taskDone{TaskIndex}.show{1,3}.name='PDR2T.TIF';
project.taskDone{TaskIndex}.show{1,3}.path=project.sysinfo.workspace;
project.taskDone{TaskIndex}.show{1,3}.info='Voxel distribution, PD - R2 plane';

cd(pathout);
