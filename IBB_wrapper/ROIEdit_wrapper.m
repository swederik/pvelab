function project=ROIEdit_wrapper(project,TaskIndex,MethodIndex,varargin)
%____________________________________________
% M. Comerci, 26092003, IBB
% SW version: 1.0.0

global img;
global hdr;
global clrmap;
global roiname;

%_____ Loading colormap
%clrmap=hot(256);
rand('seed',2);
clrmap=0.25+3*rand(256,3)/4;
clrmap(1,:)=[0 0 0];
roi=[];

%_____ Looking for atlas field
taskidx=-1;
for i=1:TaskIndex
    if isfield(project.taskDone{i},'userdata') & isfield(project.taskDone{i}.userdata,'atlas')
        taskidx=i;
    end
end

%_____ Set ROI-file name
if taskidx>0
if isfield(project.taskDone{taskidx}.userdata,'map')
    roiPath=project.taskDone{taskidx}.userdata.map.path;
    roiName=project.taskDone{taskidx}.userdata.map.name;
    roi=fullfile(roiPath,roiName);
end
end

%_____ Looking for roi field
taskidx=-1;
for i=1:TaskIndex
    if isfield(project.taskDone{i},'userdata') & isfield(project.taskDone{i}.userdata,'roi')
        taskidx=i;
    end
end

%_____ Set ROI-file name
if taskidx>0
if isfield(project.taskDone{taskidx}.userdata,'roi')
    roiPath=project.taskDone{taskidx}.userdata.roi.path;
    roiName=project.taskDone{taskidx}.userdata.roi.name;
    roi=fullfile(roiPath,roiName);
end
end

%_____ Show progress data
msg='ROIEdit started...';
project=logProject(msg,project,TaskIndex,MethodIndex); 

if length(roi)>0
    file=fopen(roi,'rb');
    if (file<0)
        error('Fatal error: roi data file not found or permission denied. Program aborted.');
    else
        string=fgets(file);
        string=fgets(file);
        roiname(255,1:3)='Air';
        roiname(1,1:2)='GM';
        roiname(2,1:2)='WM';
        roiname(3,1:3)='CSF';
        while ((string(1)~='\n')&(string(1)~=' ')&(string(1)~='\0')&(string(1)~=10)&(length(string)>3));
            temp=sscanf(string,'%d %s %x');
            num=temp(1);
            c=temp(end);
            r=floor(c/65536);
            g=floor((c-r*65536)/256);
            b=floor(c-r*65536-g*256);
            if ((num>=1)&(num<=256))
                clrmap(num,:)=[r g b]/255;
                aaa=length(temp);
                roiname(num,1:aaa-2)=temp(2:end-1)';                
            end
            string=fgets(file);
        end
    end 
end

%clrmap(2,:)=[.5 .5 .5];
clrmap(2,:)=[1 1 1];
clrmap(3,:)=[0 0 180/255];

%_____ Choose the file to edit
path0=project.sysinfo.systemdir;
[filein,pathin]=uigetfile('*.img','Select an Analyze file to edit...');

%_____ Show progress data
msg=['File ',fullfile(pathin,filein),' selected'];
project=logProject(msg,project,TaskIndex,MethodIndex); 

[img,hdr]=ReadAnalyzeImg(fullfile(pathin,filein),':','double');
img=(img-hdr.offset)*hdr.scale;
if length(hdr.dim)==3
    time=1;
else
    time=hdr.dim(4);
end
if time>1,
    error('ROIEdit: multi-frame images are not supported.');
    return
end
img=reshape(img,hdr.dim(1),hdr.dim(2),hdr.dim(3));
img=permute(img,[2 1 3]);

global fig;
global currslice;
global selectedpoints;
global u1;
global u2;
global u3;
global u4;
global u5;

currslice=ceil(hdr.dim(3)/2);
selectedpoints=[];
color=[210/255 210/255 210/255];
f=get(0,'ScreenSize');
f1=f(3)-20;
f2=f(4)-80;
fig=figure('units','pixels','position',[10 40 f1 f2],'MenuBar','none','NumberTitle','off','Name','ROIEdit','Color',color);
set(fig,'Resize','off'); %must be set after creation of figure, otherwise older versions of matlab may get confused

u1=uicontrol('parent',fig,'style','check','units','pixels','position',[f1-140 f2-30 130 20],'HorizontalAlignment','left','BackgroundColor',color,'string','Use color map','TooltipString','Color mapped data','Value',0,'Callback',{@DrawSlice2});
u2=uicontrol('parent',fig,'style','text','units','pixels','position',[f1-140 f2-60 130 30],'HorizontalAlignment','left','BackgroundColor',color,'Tag','configuratortext','string','Current:','TooltipString','Pixel value');
uicontrol('parent',fig,'style','text','units','pixels','position',[f1-140 f2-90 80 20],'HorizontalAlignment','left','BackgroundColor',color,'Tag','configuratortext','string','New value:','TooltipString','Pixel value');
u3=uicontrol('parent',fig,'style','edit','units','pixels','position',[f1-60 f2-90 50 20],'HorizontalAlignment','left','BackgroundColor',color,'string','0','TooltipString','Pixel value');
u5=uicontrol('parent',fig,'style','text','units','pixels','position',[f1-140 f2-320 130 20],'HorizontalAlignment','center','BackgroundColor',color,'Tag','configuratortext','string',['Slice ',num2str(currslice),'/',num2str(hdr.dim(3))],'TooltipString','Pixel value');

uicontrol('parent',fig,'style','pushbutton','units','pixels','position',[f1-115 f2-140 80 25],'HorizontalAlignment','center','string','Modify sel.','Callback',{@ModifyROI});
uicontrol('parent',fig,'style','pushbutton','units','pixels','position',[f1-115 f2-170 80 25],'HorizontalAlignment','center','string','Clear sel.','Callback',{@ClearSelection});
uicontrol('parent',fig,'style','pushbutton','units','pixels','position',[f1-115 f2-200 80 25],'HorizontalAlignment','center','string','Save','Callback',{@Save});
uicontrol('parent',fig,'style','pushbutton','units','pixels','position',[f1-115 f2-230 80 25],'HorizontalAlignment','center','string','Cancel','Callback',{@Cancel});
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

%_____ Show progress data
msg='ROIEdit terminated.';
project=logProject(msg,project,TaskIndex,MethodIndex); 

%--------------------------------------------------------------------
function Update(h, eventdata)
global u2;
global fr;
global currslice;
global img;
global hdr;
global roiname;

p=get(h,'currentpoint');
if p(1)>=0.03 & p(2)>=0.03 & p(1)<=(fr+0.03) & p(2)<=0.97
    value=img(round(((p(2)-0.03)/0.94)*(hdr.dim(2)-1))+1,round((p(1)-0.03)/fr*(hdr.dim(1)-1))+1,currslice);
    v=round(value);
    if v==0
        v=255;
    end
    if v<1
        v=1
    end
    if v>255
        v=255
    end
    set(u2,'string',['Current: ',num2str(value),' (',deblank(roiname(v,:)),')']);
end

%--------------------------------------------------------------------
function ImageClick(h, eventdata)
global fr;
global selectedpoints;
global hdr;

p=get(h,'currentpoint');
if p(1)>=0.03 & p(2)>=0.03 & p(1)<=(fr+0.03) & p(2)<=0.97
    selectedpoints=[selectedpoints;round(( (p(2)-0.03)/0.94)*(hdr.dim(2)-1))+1,round( ((p(1)-0.03))/fr*(hdr.dim(1)-1))+1];
    DrawSlice
end

%--------------------------------------------------------------------
function DrawSlice2(h, eventdata)
DrawSlice

%--------------------------------------------------------------------
function DrawSlice
global u1;
global currslice;
global selectedpoints;
global img;
global clrmap;

hold off
colormap (clrmap);
if get(u1,'value')==0
    colormap gray(256)
    imagesc(img(:,:,currslice));
    axis xy
else
    temp=img(:,:,currslice);
    temp(temp<0)=0;
    temp(temp>255)=255;
    image(temp);
    axis xy
end
hold on
if length(selectedpoints)>1
    plot(selectedpoints(:,2),selectedpoints(:,1),'or',selectedpoints(:,2),selectedpoints(:,1),'-y');
end
hold off

%--------------------------------------------------------------------
function ModifyROI(h, eventdata)
global fig;
global currslice;
global selectedpoints;
global u1;
global u2;
global u3;
global u4;
global img;
global hdr;
l=size(selectedpoints);
l=l(1);
newvalue=str2num(get(u3,'string'));
if l==0
    return
end
if l==1
    img(selectedpoints(1),selectedpoints(2),currslice)=newvalue;
    selectedpoints=[];
    DrawSlice
    return
end
if l==2
    ma=max([abs(selectedpoints(1,1)-selectedpoints(2,1)),abs(selectedpoints(1,2)-selectedpoints(2,2))]);
    for i=0:ma
        x=round((i*selectedpoints(1,1)+(ma-i)*selectedpoints(2,1))/ma);
        y=round((i*selectedpoints(1,2)+(ma-i)*selectedpoints(2,2))/ma);
        img(x,y,currslice)=newvalue;
    end
    selectedpoints=[];
    DrawSlice
    return
end
if ((selectedpoints(1,1)~=selectedpoints(l,1)) | (selectedpoints(1,2)~=selectedpoints(l,2)))
    selectedpoints=[selectedpoints;selectedpoints(1,1),selectedpoints(1,2)];
    l=l+1;
end
mask=zeros(hdr.dim(2),hdr.dim(1));
for j=2:l
    ma=max([abs(selectedpoints(j-1,1)-selectedpoints(j,1)),abs(selectedpoints(j-1,2)-selectedpoints(j,2))]);
    for i=0:ma
        x=round((i*selectedpoints(j-1,1)+(ma-i)*selectedpoints(j,1))/ma);
        y=round((i*selectedpoints(j-1,2)+(ma-i)*selectedpoints(j,2))/ma);
        mask(x,y)=1;
    end
end
mask=mask/2;

todo=[1,1;hdr.dim(2),1;1,hdr.dim(1);hdr.dim(2),hdr.dim(1)];

while length(todo)>0
    x=todo(1,1);
    y=todo(1,2);
    todo=todo(2:end,:);
    if mask(x,y)==0
        mask(x,y)=1;
        if x>1 & mask(x-1,y)==0
            todo=[todo;x-1,y];
        end
        if x<hdr.dim(2) & mask(x+1,y)==0
            todo=[todo;x+1,y];
        end
        if y>1 & mask(x,y-1)==0
            todo=[todo;x,y-1];
        end
        if y<hdr.dim(1) & mask(x,y+1)==0
            todo=[todo;x,y+1];
        end
    end    
end
mask(mask<1)=0;
mask=1-mask;
imagesc(mask);
temp=img(:,:,currslice);
temp((mask==1)&(temp>10))=newvalue;
img(:,:,currslice)=temp;
selectedpoints=[];
DrawSlice

%--------------------------------------------------------------------
function Save(h, eventdata)
global img;
global hdr;
global fig;

img=permute(img,[2 1 3]);
img=img/hdr.scale+hdr.offset;
img=reshape(img,hdr.dim(1)*hdr.dim(2)*hdr.dim(3),1);
WriteAnalyzeImg(hdr,img);

uiresume(fig);
close(fig);

%--------------------------------------------------------------------
function Cancel(h, eventdata)
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
    selectedpoints=[];
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
    selectedpoints=[];
    currslice=currslice-1;
    DrawSlice
    set(u5,'string',['Slice ',num2str(currslice),'/',num2str(hdr.dim(3))]);
end

%--------------------------------------------------------------------
function ClearSelection(h, eventdata)
global selectedpoints;
selectedpoints=[];
DrawSlice
