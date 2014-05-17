function project=CONFIG_Seg(project,TaskIndex,MethodIndex,varargin)
global settings;
global origsettings;
global fig;
color=[210/255 210/255 210/255];
figuresize=get(0,'ScreenSize');       %returns for example [1 1 1024 768]
fig=figure('units','pixels','position',[figuresize(3)/2-200 figuresize(4)/2-200 400 400],'MenuBar','none','NumberTitle','off','Name','Options: segmentation','Color',color);
set(fig,'Resize','off');  %must be set after creation of figure, otherwise older versions of matlab may get confused
uicontrol('style','frame','units','pixels','position',[15 50 375 340],'BackgroundColor',color);
uicontrol('style','text','units','pixels','position',[20 378 95 20],'String','Segmentation','BackgroundColor',color);

%_____ Set default configuration if not exist
if(isempty(project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.default))
    settings={'320.0','Y','Y','N','1.0'};
    project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.default=settings;
end

if(isempty(project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.user))
    project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.user=project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.default;
end
settings=project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.user;
origsettings=settings;

pdnoise=str2num(settings{1});
drawbox=0;
if settings{2}=='Y',
    drawbox=1;
end
gaussfit=0;
if settings{3}=='Y',
    gaussfit=1;
end
align=0;
if settings{4}=='Y',
    align=1;
end
t1scale=str2num(settings{5});

uicontrol('parent',gcf,'style','text','units','pixels','position',[30 282 150 20],'HorizontalAlignment','left','BackgroundColor',color,'Tag','configuratortext','string','Background noise of PD','TooltipString','Set this value to the minimum value that a voxel must have in the PD-w signal to be considered valid tissue');
u1=uicontrol('parent',gcf,'style','edit','units','pixels','position',[180 285 60 20],'HorizontalAlignment','left','BackgroundColor',color,'string',sprintf('%.1f',pdnoise),'TooltipString','Set this value to the minimum value that a voxel must have in the PD-w signal to be considered valid tissue');
u2=uicontrol('parent',gcf,'style','check','units','pixels','position',[30 240 210 40],'HorizontalAlignment','left','BackgroundColor',color,'string','Draw box','TooltipString','Enable this flag if you want to draw the box in the voxel distribution images','Value',drawbox);
u3=uicontrol('parent',gcf,'style','check','units','pixels','position',[30 200 210 40],'HorizontalAlignment','left','BackgroundColor',color,'string','Gaussian fitting','TooltipString','Enable this flag if you want perform Gaussian fitting when calculating GM-WM threshold on R1','Value',gaussfit);
u4=uicontrol('parent',gcf,'style','check','units','pixels','position',[30 160 210 40],'HorizontalAlignment','left','BackgroundColor',color,'string','Align before segmenting','TooltipString','Enable this flag if you want to perform AUTOMATIC pre-alignment of T2-W and PD-W series to the T1-W one','Value',align);
uicontrol('parent',gcf,'style','text','units','pixels','position',[30 122 150 20],'HorizontalAlignment','left','BackgroundColor',color,'Tag','configuratortext','string','T1 scale factor','TooltipString','Set this value to the scale factor for the T1-w signal');
u5=uicontrol('parent',gcf,'style','edit','units','pixels','position',[180 125 60 20],'HorizontalAlignment','left','BackgroundColor',color,'string',sprintf('%.6f',t1scale),'TooltipString','Set this value to the scale factor for the T1-w signal');

uicontrol('parent',gcf,'style','pushbutton','units','pixels','position',[15 15 95 25],'HorizontalAlignment','left','string','Load defaults','Callback',{@UIbuttonDefault_callback,u1,u2,u3,u4,u5},'TooltipString','Load Default values for the parameters');
uicontrol('parent',gcf,'style','pushbutton','units','pixels','position',[120 15 60 25],'HorizontalAlignment','left','string','Revert','Callback',{@UIbuttonRevert_callback,u1,u2,u3,u4,u5,pdnoise,drawbox,gaussfit,align,t1scale},'TooltipString','Revert the parameters to the saved values');
uicontrol('parent',gcf,'style','pushbutton','units','pixels','position',[260 15 60 25],'HorizontalAlignment','left','string','Apply','Callback',{@UIbuttonApply_callback,u1,u2,u3,u4,u5},'TooltipString','Save the values and exit');
uicontrol('parent',gcf,'style','pushbutton','units','pixels','position',[330 15 60 25],'HorizontalAlignment','left','string','Cancel','Callback',{@UIbuttonCancel_callback},'TooltipString','Exit without saving');

uiwait(fig);
project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.user=settings;

%--------------------------------------------------------------------
function UIbuttonApply_callback(h, eventdata,u1,u2,u3,u4,u5)
global settings;
global origsettings;
global fig;
p=get(u1,'String');
d=get(u2,'Value');
g=get(u3,'Value');
a=get(u4,'Value');
t=get(u5,'String');
if d==1,
    d='Y';
else
    d='N';
end
if g==1,
    g='Y';
else
    g='N';
end
if a==1,
    a='Y';
else
    a='N';
end
settings={p,d,g,a,t};
uiresume(fig);
delete(gcf);

%--------------------------------------------------------------------
function UIbuttonDefault_callback(h, eventdata,u1,u2,u3,u4,u5)
set(u1,'String','320.0');
set(u2,'Value',1);
set(u3,'Value',1);
set(u4,'Value',0);
set(u5,'String','1.000000');

%--------------------------------------------------------------------
function UIbuttonRevert_callback(h,eventdata,u1,u2,u3,u4,u5,pdnoise,drawbox,gaussfit,align,t1scale)
set(u1,'String',sprintf('%.1f',pdnoise));
set(u2,'Value',drawbox);
set(u3,'Value',gaussfit);
set(u4,'Value',align);
set(u5,'String',sprintf('%.6f',t1scale));

%--------------------------------------------------------------------
function UIbuttonCancel_callback(h, eventdata, handles, varargin)
global settings;
global origsettings;
global fig;
settings=origsettings;
uiresume(fig);
delete(gcf);
