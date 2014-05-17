function project=CONFIG_Atlas2(project,TaskIndex,MethodIndex,varargin)
global settings;
global origsettings;
global fig;
color=[210/255 210/255 210/255];
figuresize=get(0,'ScreenSize');       %returns for example [1 1 1024 768]
fig=figure('units','pixels','position',[figuresize(3)/2-200 figuresize(4)/2-200 400 400],'MenuBar','none','NumberTitle','off','Name','Options: atlas - MNI','Color',color);
set(fig,'Resize','off');  %must be set after creation of figure, otherwise older versions of matlab may get confused
uicontrol('style','frame','units','pixels','position',[15 50 375 340],'BackgroundColor',color);
uicontrol('style','text','units','pixels','position',[20 378 180 20],'String','MNI atlas based labeling','BackgroundColor',color);

%_____ Set default configuration if it does not exist
if(isempty(project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.default))
    settings={'Y'};
    project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.default=settings;
end

if(isempty(project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.user))
    project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.user=project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.default;
end
settings=project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.user;
origsettings=settings;

sw=0;
if settings{1}=='Y',
    sw=1;
end

u1=uicontrol('parent',fig,'style','check','units','pixels','position',[30 240 210 40],'HorizontalAlignment','left','BackgroundColor',color,'string','Show results','TooltipString','Enable this flag to show the colored labeled brain','Value',sw);

uicontrol('parent',gcf,'style','pushbutton','units','pixels','position',[15 15 95 25],'HorizontalAlignment','left','string','Load defaults','Callback',{@UIbuttonDefault_callback,u1},'TooltipString','Load Default values for the parameters');
uicontrol('parent',gcf,'style','pushbutton','units','pixels','position',[120 15 60 25],'HorizontalAlignment','left','string','Revert','Callback',{@UIbuttonRevert_callback,u1,sw},'TooltipString','Revert the parameters to the saved values');
uicontrol('parent',gcf,'style','pushbutton','units','pixels','position',[260 15 60 25],'HorizontalAlignment','left','string','Apply','Callback',{@UIbuttonApply_callback,u1},'TooltipString','Save the values and exit');
uicontrol('parent',gcf,'style','pushbutton','units','pixels','position',[330 15 60 25],'HorizontalAlignment','left','string','Cancel','Callback',{@UIbuttonCancel_callback},'TooltipString','Exit without saving');

uiwait(fig);
project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.user=settings;

%--------------------------------------------------------------------
function UIbuttonApply_callback(h, eventdata,u1)
global settings;
global origsettings;
global fig;

sw=get(u1,'Value');
if sw==1,
    sw='Y';
else
    sw='N';
end
settings={sw};
uiresume(fig);
delete(gcf);

%--------------------------------------------------------------------
function UIbuttonDefault_callback(h, eventdata,u1)
set(u1,'Value',1);

%--------------------------------------------------------------------
function UIbuttonRevert_callback(h,eventdata,u1,sw)
set(u1,'Value',sw);

%--------------------------------------------------------------------
function UIbuttonCancel_callback(h, eventdata, handles, varargin)
global settings;
global origsettings;
global fig;
settings=origsettings;
uiresume(fig);
delete(gcf);
