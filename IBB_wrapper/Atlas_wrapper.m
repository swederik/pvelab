function project=Atlas_wrapper(project,TaskIndex,MethodIndex,varargin)
% Atlas_wrapper function performs the Talairach atlas based labeling
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
% SW version: 1.0.12 16112005
% ____________________________________________

%_____ Show message in the log window
msg='Talairach based ROI definition: progress data in Matlab command window...';
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

%_____ Looking for segoutResliced field
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

%_____ Set default configuration if it does not exist
if (isempty(project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.default))
    settings={'ClassifyTalair.Mat','N','10','LOBES_ROI.dat','Y'};
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
f2=0;
f3=0;
f4=0;

for k=1:i-1
    c=[config{k} '                  '];
    if strcmp(c(1:13),'ClassifyFile=');
        c=[c(1:13) settings{1} '       '];
        f1=1;
    end
    if strcmp(c(1:9),'CorrectY=');
        c=[c(1:9) settings{2} '       '];
        f2=1;
    end
    if strcmp(c(1:7),'MinVox=');
        c=[c(1:7) settings{3} '       '];
        f3=1;
    end
    if strcmp(c(1:8),'ROIFile=');
        c=[c(1:8) settings{4} '           '];
        f4=1;
    end
    fprintf(fid,'%s\n',deblank(c));
end
if f1==0
    fprintf(fid,'ClassifyFile=%s\n',deblank(settings{1}));
end
if f2==0
    fprintf(fid,'CorrectY=%s\n',settings{2});
end
if f3==0
    fprintf(fid,'MinVox=%s\n',settings{3});
end
if f4==0
    fprintf(fid,'ROIFile=%s\n',deblank(settings{4}));
end
fclose(fid);

global img;
global hdr;
global flip;
global ACFlag;
global ACx ACy ACz PCx PCy PCz;
global str;

ACFlag=1; %1 = selecting AC point, 0 = selecting PC point;
str{1}='PC';
str{2}='AC';

if ~strcmpi(spm('Ver'),'spm8')
    global defaults
    spm_defaults;
    flip=defaults.analyze.flip;
end

filein='r_volume.img';
pathin=pathout;

%_____ Show progress data
msg=['File ',fullfile(pathin,filein)];
project=logProject(msg,project,TaskIndex,MethodIndex);

[img,hdr]=ReadAnalyzeImg(fullfile(pathin,filein),':','double');
img=(img-hdr.offset)*hdr.scale;
img=reshape(img,hdr.dim(1),hdr.dim(2),hdr.dim(3));
img=permute(img,[2 1 3]);

ACx=round(hdr.dim(2)/2);
PCx=ACx;
ACy=round(hdr.dim(1)/2-4);
PCy=round(hdr.dim(1)/2+4);
ACz=round(hdr.dim(3)/3);
PCz=ACz;

strACPC=sprintf('Currently setting %s\nAC=(%d,%d,%d)\nPC=(%d,%d,%d)',cell2mat(str(ACFlag+1)),hdr.dim(2)-ACx,hdr.dim(1)-ACy,ACz-1,hdr.dim(2)-PCx,hdr.dim(1)-PCy,PCz-1);

global fig;
global currslice;
global u2;
global u5;

currslice=round(hdr.dim(3)*0.33);
color=[210/255 210/255 210/255];
f=get(0,'ScreenSize');
f1=f(3)-20;
f2=f(4)-80;
fig=figure('units','pixels','position',[10 40 f1 f2],'MenuBar','none','NumberTitle','off','Name','Talairach Atlas','Color',color);
set(fig,'Resize','off'); %must be set after creation of figure, otherwise older versions of matlab may get confused

u2=uicontrol('parent',fig,'style','text','units','pixels','position',[f1-140 f2-120 150 80],'HorizontalAlignment','left','BackgroundColor',color,'Tag','configuratortext','string',strACPC,'TooltipString','AC PC');
u5=uicontrol('parent',fig,'style','text','units','pixels','position',[f1-140 f2-320 130 20],'HorizontalAlignment','center','BackgroundColor',color,'Tag','configuratortext','string',['Slice ',num2str(currslice),'/',num2str(hdr.dim(3))],'TooltipString','Slice');

uicontrol('parent',fig,'style','pushbutton','units','pixels','position',[f1-115 f2-170 80 25],'HorizontalAlignment','center','string','AC','Callback',{@AC});
uicontrol('parent',fig,'style','pushbutton','units','pixels','position',[f1-115 f2-200 80 25],'HorizontalAlignment','center','string','PC','Callback',{@PC});
uicontrol('parent',fig,'style','pushbutton','units','pixels','position',[f1-115 f2-230 80 25],'HorizontalAlignment','center','string','Ok','Callback',{@Ok});
uicontrol('parent',fig,'style','pushbutton','units','pixels','position',[f1-115 f2-260 80 25],'HorizontalAlignment','center','string','+','Callback',{@Up});
uicontrol('parent',fig,'style','pushbutton','units','pixels','position',[f1-115 f2-290 80 25],'HorizontalAlignment','center','string','-','Callback',{@Down});

global fr;
fr=0.97-150/f1;
u4=axes('position',[0.03 0.03 fr .94]);
set(fig,'WindowButtonMotionFcn',{@Update})
set(fig,'units','normalized')
set(fig,'WindowButtonDownFcn',{@ImageClick})
DrawSlice;
uiwait(fig);

acpc=sprintf('-acpc %d,%d,%d,%d,%d,%d',hdr.dim(2)-ACx,hdr.dim(1)-ACy,ACz-1,hdr.dim(2)-PCx,hdr.dim(1)-PCy,PCz-1);

%_____ Call to the program
flg='';
if defaults.analyze.flip==0
    flg=' -f';
end
cd(path1);
if ismac
    if settings{5}=='Y'
        cmdline=['"' path1 filesep,'pvemac"',flg,' -w -p ',acpc,' "',pathout,'r_volume_seg1.img"',' dummy',' "',fullfile(pathout,'config'),'"'];
    else
        cmdline=['"' path1 filesep,'pvemac"',flg,' -k -p ',acpc,' "',pathout,'r_volume_seg1.img"',' dummy',' "',fullfile(pathout,'config'),'"'];
    end
else
    ccc=computer;
    suff='';
    if ccc(end)=='4'
        suff='64';
    end

    if settings{5}=='Y'
        cmdline=['"' path1 filesep,'pve',suff,'"',flg,' -w -p ',acpc,' "',pathout,'r_volume_seg1.img"',' dummy',' "',fullfile(pathout,'config'),'"'];
    else
        cmdline=['"' path1 filesep,'pve',suff,'"',flg,' -k -p ',acpc,' "',pathout,'r_volume_seg1.img"',' dummy',' "',fullfile(pathout,'config'),'"'];
    end
end
result=unix(cmdline);

diary off
if result~=0
    [project,msg]=logProject('Error in atlas method.',project,TaskIndex,MethodIndex);
    project.taskDone{TaskIndex}.error{end+1}=msg;
    return
end

movefile(fullfile(pathout,'config'),fullfile(pathout,'config_atlas_talair'));
copyfile(fullfile(path1,settings{4}),fullfile(pathout,settings{4}));
copyfile(fullfile(path1,settings{1}),fullfile(pathout,settings{1}));

%_____ Set up output file names
project.taskDone{TaskIndex}.userdata.atlas.name='r_volume_GMROI.img';
project.taskDone{TaskIndex}.userdata.atlas.path=project.sysinfo.workspace;
project.taskDone{TaskIndex}.userdata.atlas.info='Normalized labeled brain according to Talairach atlas';

%copy dat file to project dir
%copyfile([path1,filesep,deblank(settings{4})],project.sysinfo.workspace);

project.taskDone{TaskIndex}.userdata.t1.path=project.sysinfo.workspace;
project.taskDone{TaskIndex}.userdata.t1.info='registered T1-W image';
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
project.taskDone{TaskIndex}.userdata.talair.path=project.sysinfo.workspace;
project.taskDone{TaskIndex}.userdata.talair.info='registered labeled gray matter image, interpolated to cubic voxels';
project.taskDone{TaskIndex}.userdata.talair.name='r_volume_Talair.img';
% not there
% project.taskDone{TaskIndex}.userdata.postxy.path=project.sysinfo.workspace;
% project.taskDone{TaskIndex}.userdata.postxy.info='Coronal projection of the segmented Gray Matter after normalization before the Y correction';
% project.taskDone{TaskIndex}.userdata.postxy.name='r_volume_PostXY.tiff';
project.taskDone{TaskIndex}.userdata.norm.path=project.sysinfo.workspace;
project.taskDone{TaskIndex}.userdata.norm.info='normalization matrix used, in ASCII format';
project.taskDone{TaskIndex}.userdata.norm.name='r_volume_Talair.Mat';
project.taskDone{TaskIndex}.userdata.box.path=project.sysinfo.workspace;
project.taskDone{TaskIndex}.userdata.box.info='coordinates of the box surrounding the brain';
project.taskDone{TaskIndex}.userdata.box.name='r_volume_Box_limits.Mat';
% not there
% project.taskDone{TaskIndex}.userdata.binmap.name=deblank(settings{1});
% project.taskDone{TaskIndex}.userdata.binmap.path=project.sysinfo.workspace;
% project.taskDone{TaskIndex}.userdata.binmap.info='Binary file containing the Talairach Atlas ROI''s codes';
project.taskDone{TaskIndex}.userdata.map.name=settings{4};
project.taskDone{TaskIndex}.userdata.map.path=pathout;
project.taskDone{TaskIndex}.userdata.map.info='ASCII file containing the Talairach Atlas ROI''s codes';
project.taskDone{TaskIndex}.show{1,1}.name='r_volume_1.tiff';
project.taskDone{TaskIndex}.show{1,1}.path=project.sysinfo.workspace;
project.taskDone{TaskIndex}.show{1,1}.info='Coronal projection of the segmented Gray Matter';
project.taskDone{TaskIndex}.show{1,2}.name='r_volume_2.tiff';
project.taskDone{TaskIndex}.show{1,2}.path=project.sysinfo.workspace;
project.taskDone{TaskIndex}.show{1,2}.info='Sagittal projection of the segmented Gray Matter';
project.taskDone{TaskIndex}.show{1,3}.name='r_volume_3.tiff';
project.taskDone{TaskIndex}.show{1,3}.path=project.sysinfo.workspace;
project.taskDone{TaskIndex}.show{1,3}.info='Trasversal projection of the segmented Gray Matter';
project.taskDone{TaskIndex}.show{1,4}.name='r_volume_PostXYZ.tiff';
project.taskDone{TaskIndex}.show{1,4}.path=project.sysinfo.workspace;
project.taskDone{TaskIndex}.show{1,4}.info='Coronal projection of the segmented Gray Matter after normalization';
project.taskDone{TaskIndex}.show{1,5}.name='r_volume_PostXZ.tiff';
project.taskDone{TaskIndex}.show{1,5}.path=project.sysinfo.workspace;
project.taskDone{TaskIndex}.show{1,5}.info='Projection of the segmented Gray Matter after normalization';
%project.taskDone{TaskIndex}.show{1,6}.name='r_volume_GMROI.img';
%project.taskDone{TaskIndex}.show{1,6}.path=project.sysinfo.workspace;
%project.taskDone{TaskIndex}.show{1,6}.info='Labeled segmented image';
cd(pathout);

%--------------------------------------------------------------------
function AC(h, eventdata)
global ACFlag;
ACFlag=1;
DrawSlice

%--------------------------------------------------------------------
function PC(h, eventdata)
global ACFlag;
ACFlag=0;
DrawSlice

%--------------------------------------------------------------------
function Update(h, eventdata)
global fr;
global currslice;
global img;
global hdr;
p=get(h,'currentpoint');
if p(1)>=0.03 & p(2)>=0.03 & p(1)<=(fr+0.03) & p(2)<=0.97
    value=img(round(((p(2)-0.03)/0.94)*(hdr.dim(2)-1))+1,round((p(1)-0.03)/fr*(hdr.dim(1)-1))+1,currslice);
    v=round(value);
    if v==0
        v=255;
    end
    if v<1
        v=1;
    end
    if v>255
        v=255;
    end
end

%--------------------------------------------------------------------
function ImageClick(h, eventdata)
global fr;
global hdr;
global currslice;
global ACFlag;
global ACx ACy ACz PCx PCy PCz;

p=get(h,'currentpoint');
if p(1)>=0.03 & p(2)>=0.03 & p(1)<=(fr+0.03) & p(2)<=0.97
    y=round(((p(2)-0.03)/0.94)*(hdr.dim(2)-1))+1;
    x=round( ((p(1)-0.03))/fr*(hdr.dim(1)-1))+1;
    z=currslice;
    if ACFlag==1
        ACx=x;
        ACy=y;
        ACz=z;
    else
        PCx=x;
        PCy=y;
        PCz=z;
    end
    DrawSlice
end

%--------------------------------------------------------------------
function DrawSlice
global u1;
global u2;
global currslice;
global img;
global hdr;
global flip;
global ACFlag;
global ACx ACy ACz PCx PCy PCz;
global str;

strACPC=sprintf('Currently setting %s\nAC=(%d,%d,%d)\nPC=(%d,%d,%d)',cell2mat(str(ACFlag+1)),hdr.dim(2)-ACx,hdr.dim(1)-ACy,ACz-1,hdr.dim(2)-PCx,hdr.dim(1)-PCy,PCz-1);
set(u2,'string',strACPC);

hold off
colormap gray(256)
if flip==1
    imagesc(fliplr(img(:,:,currslice)));
else
    imagesc(img(:,:,currslice));
end
axis xy

%--------------------------------------------------------------------
function Ok(h, eventdata)
global fig;
uiresume(fig);
close(fig);

%--------------------------------------------------------------------
function Up(h, eventdata)
global currslice;
global hdr;
global u5;
global selectedpoints;
if currslice<hdr.dim(3)
    currslice=currslice+1;
    DrawSlice
    set(u5,'string',['Slice ',num2str(currslice),'/',num2str(hdr.dim(3))]);
end

%--------------------------------------------------------------------
function Down(h, eventdata)
global currslice;
global hdr;
global u5;
global selectedpoints;
if currslice>1
    currslice=currslice-1;
    DrawSlice
    set(u5,'string',['Slice ',num2str(currslice),'/',num2str(hdr.dim(3))]);
end
