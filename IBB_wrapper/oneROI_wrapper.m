function project=oneROI_wrapper(project,TaskIndex,MethodIndex,varargin)
% oneROI_wrapper function creates a GMROI file with one GM ROI
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
% ____________________________________________
% M. Comerci, 19052004, IBB
%
% SW version: 1.0.0 19052004
% ____________________________________________

%_____ Show message in the log window
msg='Creating GMROI file from resliced segmented...';
project=logProject(msg,project,TaskIndex,MethodIndex); 

path0=project.sysinfo.systemdir;
pathout=[project.sysinfo.workspace filesep];
path1=[path0 filesep 'IBB_wrapper' filesep 'pve'];

%_____ Initialize
noModalities=length(project.pipeline.imageModality);
ImageIndex=project.pipeline.imageIndex(1);

%_____ Start command window logging
if(isempty(project.sysinfo.logfile.name))
    [pathstr,name,ext] = fileparts(project.sysinfo.prjfile);
    project.sysinfo.logfile.name=[name,'.log'];
end

%_____ Looking for segoutResliced field
taskidx=0;
for i=1:TaskIndex
 if isfield(project.taskDone{i},'userdata')
  if isfield(project.taskDone{i}.userdata,'segoutReslice')
   taskidx=i;
  end
 end
end

if taskidx==0
 [project,msg]=logProject('Error: can not find the segmented file names from reslice method.',project,TaskIndex,MethodIndex); 
 project.taskDone{TaskIndex}.error{end+1}=msg;            
 return
end

%_____ Copying input files to workspace
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

msg='Reading GM...';
project=logProject(msg,project,TaskIndex,MethodIndex); 

seg1path=project.taskDone{taskidx}.userdata.segoutReslice{1}.path;
seg1name=project.taskDone{taskidx}.userdata.segoutReslice{1}.name;

ffs=fullfile(seg1path,seg1name);
[seg1,hseg]=ReadAnalyzeImg(ffs);
seg1=double(seg1);

msg='Reading WM...';
project=logProject(msg,project,TaskIndex,MethodIndex); 

seg2path=project.taskDone{taskidx}.userdata.segoutReslice{2}.path;
seg2name=project.taskDone{taskidx}.userdata.segoutReslice{2}.name;

ffs=fullfile(seg2path,seg2name);
[seg2,hseg]=ReadAnalyzeImg(ffs);
seg2=double(seg2);

seg3=seg1*0;
%_____ Looking for segoutResliced field
if isfield(project.taskDone{taskidx}.userdata.segoutReslice{3},'path')
 msg='Reading CSF...';
 project=logProject(msg,project,TaskIndex,MethodIndex); 

 seg3path=project.taskDone{taskidx}.userdata.segoutReslice{3}.path;
 seg3name=project.taskDone{taskidx}.userdata.segoutReslice{3}.name;
 
 ffs=fullfile(seg3path,seg3name);
 [seg3,hseg]=ReadAnalyzeImg(ffs);
 seg3=double(seg3);
end

msg='Calculating GMROI file from resliced segmented...';
project=logProject(msg,project,TaskIndex,MethodIndex); 

seg4=255-(seg1+seg2+seg3);
[dummy,index]=max([seg1 seg2 seg3 seg4]');
gmroi=zeros(size(seg1));
gmroi(index==1)=51;
gmroi(index==2)=2;
gmroi(index==3)=3;

msg='Writing GMROI file...';
project=logProject(msg,project,TaskIndex,MethodIndex); 

hseg.name=fullfile(pathout,'r_volume_GMROI.img');
hseg.scale=1;
hseg.offset=0;
hseg.pre=8;
hseg.lim=[255 0];
WriteAnalyzeImg(hseg,gmroi);

%_____ Set up output file names
project.taskDone{TaskIndex}.userdata.atlas.name='r_volume_GMROI.img';
project.taskDone{TaskIndex}.userdata.atlas.path=project.sysinfo.workspace;
project.taskDone{TaskIndex}.userdata.atlas.info='Labeled segmented image';
%copy dat file to project dir
copyfile([path1,filesep,'ONE_ROI.dat'],project.sysinfo.workspace);

project.taskDone{TaskIndex}.userdata.t1.path=project.sysinfo.workspace;
project.taskDone{TaskIndex}.userdata.t1.info='registered T1-W image';
project.taskDone{TaskIndex}.userdata.t1.name='r_volume.img';
project.taskDone{TaskIndex}.userdata.map.name='ONE_ROI.dat';
project.taskDone{TaskIndex}.userdata.map.path=project.sysinfo.workspace;
project.taskDone{TaskIndex}.userdata.map.info='ASCII file containing the Atlas ROI''s codes';
project.taskDone{TaskIndex}.show{1,1}.name='r_volume_GMROI.img';
project.taskDone{TaskIndex}.show{1,1}.path=project.sysinfo.workspace;
project.taskDone{TaskIndex}.show{1,1}.info='Labeled segmented image';
project.taskDone{TaskIndex}.show{1,2}.name='r_volume.img';
project.taskDone{TaskIndex}.show{1,2}.path=project.sysinfo.workspace;
project.taskDone{TaskIndex}.show{1,2}.info='registered T1-W image';

