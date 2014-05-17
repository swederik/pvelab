function project=CONFIG_Atlas(project,TaskIndex,MethodIndex,varargin)
global settings;
global origsettings;
global fig;
color=[210/255 210/255 210/255];
figuresize=get(0,'ScreenSize');       %returns for example [1 1 1024 768]
fig=figure('units','pixels','position',[figuresize(3)/2-200 figuresize(4)/2-200 400 400],'MenuBar','none','NumberTitle','off','Name','Options: atlas - Talairach','Color',color);
set(fig,'Resize','off');  %must be set after creation of figure, otherwise older versions of matlab may get confused
uicontrol('style','frame','units','pixels','position',[15 50 375 340],'BackgroundColor',color);
uicontrol('style','text','units','pixels','position',[20 378 180 20],'String','Talairach based atlas labeling','BackgroundColor',color);

%_____ Set default configuration if it does not exist
if(isempty(project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.default))
    settings={'ClassifyTalair.Mat','N','10','LOBES_ROI.dat','Y'};
    project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.default=settings;
end

if(isempty(project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.user))
    project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.user=project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.default;
end
settings=project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.user;
origsettings=settings;

cf=deblank(settings{1});
cy=0;
if settings{2}=='Y',
    cy=1;
end
sw=0;
if settings{5}=='Y',
    sw=1;
end
mv=str2num(settings{3});

uicontrol('parent',fig,'style','text','units','pixels','position',[30 282 80 20],'HorizontalAlignment','left','BackgroundColor',color,'Tag','configuratortext','string','Classify File','TooltipString','Set the path to a binary file containing the code of the ROI in the Talairach space');
u1=uicontrol('parent',fig,'style','edit','units','pixels','position',[110 285 270 20],'HorizontalAlignment','left','BackgroundColor',color,'string',cf,'TooltipString','Binary file containing labels of the Talairach boxes for ROI definition');
u2=uicontrol('parent',fig,'style','check','units','pixels','position',[30 240 210 40],'HorizontalAlignment','left','BackgroundColor',color,'string','Correction around Y axis','TooltipString','Enable this flag to automatically align inter-hemispheric scissure on the AC-PC line','Value',cy);
uicontrol('parent',fig,'style','text','units','pixels','position',[30 212 150 20],'HorizontalAlignment','left','BackgroundColor',color,'Tag','configuratortext','string','Minimum voxels of tissue','TooltipString','Minimum number of GM voxels to be considered brain');
u3=uicontrol('parent',fig,'style','edit','units','pixels','position',[180 215 30 20],'HorizontalAlignment','left','BackgroundColor',color,'string',sprintf('%d',mv),'TooltipString','Minimum number of GM voxels to be considered brain');
u4=uicontrol('parent',fig,'style','check','units','pixels','position',[30 170 210 40],'HorizontalAlignment','left','BackgroundColor',color,'string','Show results','TooltipString','Enable this flag to show the colored labeled brain','Value',sw);

uicontrol('parent',gcf,'style','pushbutton','units','pixels','position',[15 15 95 25],'HorizontalAlignment','left','string','Load defaults','Callback',{@UIbuttonDefault_callback,u1,u2,u3,u4},'TooltipString','Load Default values for the parameters');
uicontrol('parent',gcf,'style','pushbutton','units','pixels','position',[120 15 60 25],'HorizontalAlignment','left','string','Revert','Callback',{@UIbuttonRevert_callback,u1,u2,u3,u4,cf,cy,mv,sw},'TooltipString','Revert the parameters to the saved values');
uicontrol('parent',gcf,'style','pushbutton','units','pixels','position',[260 15 60 25],'HorizontalAlignment','left','string','Apply','Callback',{@UIbuttonApply_callback,u1,u2,u3,u4},'TooltipString','Save the values and exit');
uicontrol('parent',gcf,'style','pushbutton','units','pixels','position',[330 15 60 25],'HorizontalAlignment','left','string','Cancel','Callback',{@UIbuttonCancel_callback},'TooltipString','Exit without saving');

uiwait(fig);
project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.user=settings;

%--------------------------------------------------------------------
function UIbuttonApply_callback(h, eventdata,u1,u2,u3,u4)
global settings;
global origsettings;
global fig;

cf=get(u1,'String');
cy=get(u2,'Value');
mv=get(u3,'String');
sw=get(u4,'Value');
if cy==1,
    cy='Y';
else
    cy='N';
end
if sw==1,
    sw='Y';
else
    sw='N';
end
settings={cf,cy,mv,'LOBES_ROI.dat',sw};
uiresume(fig);
delete(gcf);

%--------------------------------------------------------------------
function UIbuttonDefault_callback(h, eventdata,u1,u2,u3,u4)
set(u1,'String','ClassifyTalair.Mat');
set(u2,'Value',0);
set(u3,'String','10');
set(u4,'Value',1);

%--------------------------------------------------------------------
function UIbuttonRevert_callback(h,eventdata,u1,u2,u3,u4,cf,cy,mv,sw)
set(u1,'String',cf);
set(u2,'Value',cy);
set(u3,'String',sprintf('%d',mv));
set(u4,'Value',sw);

%--------------------------------------------------------------------
function UIbuttonCancel_callback(h, eventdata, handles, varargin)
global settings;
global origsettings;
global fig;
settings=origsettings;
uiresume(fig);
delete(gcf);
