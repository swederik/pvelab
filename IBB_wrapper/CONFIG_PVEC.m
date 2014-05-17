function project=CONFIG_PVEC(project,TaskIndex,MethodIndex,varargin)
global settings;
global origsettings;
global fig;
color=[210/255 210/255 210/255];
figuresize=get(0,'ScreenSize');       %returns for example [1 1 1024 768]
fig=figure('units','pixels','position',[figuresize(3)/2-200 figuresize(4)/2-200 400 450],'MenuBar','none','NumberTitle','off','Name','Options: pve correction','Color',color);
set(fig,'Resize','off');  %must be set after creation of figure, otherwise older versions of matlab may get confused
uicontrol('style','frame','units','pixels','position',[15 50 375 390],'BackgroundColor',color);                        %progressframe
uicontrol('style','text','units','pixels','position',[20 428 180 20],'String','Multi method PVE correction','BackgroundColor',color);  %progressframe title

%_____ Set default configuration if it does not exist
if(isempty(project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.default))
    Def=DefaultSetup;
    settings={Def{1},Def{2},Def{3},Def{4},Def{5},Def{6},Def{7}};
    project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.default=settings;
end

if(isempty(project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.user))
    project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.user=project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.default;
end
settings=project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.user;
origsettings=settings;

rf=deblank(settings{1});
cs=0;
if settings{2}=='Y',
    cs=1;
end
fxy=str2num(settings{3});
fz=str2num(settings{4});
ov=str2num(settings{5});
sw=0;
if settings{6}=='Y',
    sw=1;
end
fl=settings{7};

uicontrol('parent',fig,'style','text','units','pixels','position',[30 382 80 20],'HorizontalAlignment','left','BackgroundColor',color,'Tag','configuratortext','string','ROI data File','TooltipString','Set the path to a text file containing the names and codes of the ROI');
u1=uicontrol('parent',fig,'style','edit','units','pixels','position',[110 385 270 20],'HorizontalAlignment','left','BackgroundColor',color,'string',rf,'TooltipString','Set the path to a text file containing the names and codes of the ROI');
u2=uicontrol('parent',fig,'style','check','units','pixels','position',[30 340 250 40],'HorizontalAlignment','left','BackgroundColor',color,'string','CSF flag','TooltipString','Enable this flag to force the program to consider CSF activity equal to zero','Value',cs);
uicontrol('parent',fig,'style','text','units','pixels','position',[30 312 150 20],'HorizontalAlignment','left','BackgroundColor',color,'string','In plane FWHM (mm)','TooltipString','Set this value to the in plane FWHM of your PET scanner');
u3=uicontrol('parent',fig,'style','edit','units','pixels','position',[180 315 50 20],'HorizontalAlignment','left','BackgroundColor',color,'string',sprintf('%.3f',fxy),'TooltipString','Set this value to the in plane FWHM of your PET scanner');
uicontrol('parent',fig,'style','text','units','pixels','position',[30 292 150 20],'HorizontalAlignment','left','BackgroundColor',color,'string','Axial FWHM (mm)','TooltipString','Set this value to the axial FWHM of your PET scanner');
u4=uicontrol('parent',fig,'style','edit','units','pixels','position',[180 295 50 20],'HorizontalAlignment','left','BackgroundColor',color,'string',sprintf('%.3f',fz),'TooltipString','Set this value to the axial FWHM of your PET scanner');
uicontrol('parent',fig,'style','text','units','pixels','position',[30 272 150 20],'HorizontalAlignment','left','BackgroundColor',color,'string','Overcorrection','TooltipString','Percentage of voxels to be considered overcorrected in Mueller-Gartner and Meltzer modules');
u5=uicontrol('parent',fig,'style','edit','units','pixels','position',[180 275 50 20],'HorizontalAlignment','left','BackgroundColor',color,'string',sprintf('%.3f',ov),'TooltipString','Percentage of voxels to be considered overcorrected in Mueller-Gartner and Meltzer modules');
u6=uicontrol('parent',fig,'style','check','units','pixels','position',[30 230 250 40],'HorizontalAlignment','left','BackgroundColor',color,'string','Show results','TooltipString','Enable this flag to show the virtual PET - real PET window','Value',sw);
um1=uicontrol('parent',fig,'style','check','units','pixels','position',[30 185 115 40],'HorizontalAlignment','left','BackgroundColor',color,'string','PVEC Rousset','TooltipString','Enable this flag to calculate the mean ROI valuses according to Rousset method','Value',bitget(fl,1));
um2=uicontrol('parent',fig,'style','check','units','pixels','position',[150 185 115 40],'HorizontalAlignment','left','BackgroundColor',color,'string','PVEC Meltzer','TooltipString','Enable this flag to calculate the PVE correction according to Meltzer method','Value',bitget(fl,2));
um3=uicontrol('parent',fig,'style','check','units','pixels','position',[270 185 115 40],'HorizontalAlignment','left','BackgroundColor',color,'string','PVEC MG','TooltipString','Enable this flag to calculate the PVE correction according to Mueller - Gartner method','Value',bitget(fl,3));
um4=uicontrol('parent',fig,'style','check','units','pixels','position',[30 140 115 40],'HorizontalAlignment','left','BackgroundColor',color,'string','PVEC PVEOut','TooltipString','Enable this flag to calculate the PVE correction according to PVEOut method','Value',bitget(fl,4));
um5=uicontrol('parent',fig,'style','check','units','pixels','position',[150 140 115 40],'HorizontalAlignment','left','BackgroundColor',color,'string','WMAE CS','TooltipString','Enable this flag to estimate the mean WM activity at the centre semiovale slices','Value',bitget(fl,6));
um6=uicontrol('parent',fig,'style','check','units','pixels','position',[270 140 115 40],'HorizontalAlignment','left','BackgroundColor',color,'string','WMAE Rousset','TooltipString','Enable this flag to estimate the mean WM activity using the Rousset method value','Value',bitget(fl,7));
um7=uicontrol('parent',fig,'style','check','units','pixels','position',[30 95 115 40],'HorizontalAlignment','left','BackgroundColor',color,'string','WMAE PVEOut','TooltipString','Enable this flag to estimate the mean WM activity with linear fitting','Value',bitget(fl,8));

uicontrol('parent',gcf,'style','pushbutton','units','pixels','position',[15 15 95 25],'HorizontalAlignment','left','string','Load defaults','Callback',{@UIbuttonDefault_callback,u1,u2,u3,u4,u5,u6,um1,um2,um3,um4,um5,um6,um7},'TooltipString','Load Default values for the parameters');
uicontrol('parent',gcf,'style','pushbutton','units','pixels','position',[120 15 60 25],'HorizontalAlignment','left','string','Revert','Callback',{@UIbuttonRevert_callback,u1,u2,u3,u4,u5,u6,um1,um2,um3,um4,um5,um6,um7,rf,cs,fxy,fz,ov,sw,fl},'TooltipString','Revert the parameters to the saved values');
uicontrol('parent',gcf,'style','pushbutton','units','pixels','position',[260 15 60 25],'HorizontalAlignment','left','string','Apply','Callback',{@UIbuttonApply_callback,u1,u2,u3,u4,u5,u6,um1,um2,um3,um4,um5,um6,um7},'TooltipString','Save the values and exit');
uicontrol('parent',gcf,'style','pushbutton','units','pixels','position',[330 15 60 25],'HorizontalAlignment','left','string','Cancel','Callback',{@UIbuttonCancel_callback},'TooltipString','Exit without saving');

uiwait(fig);
project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.user=settings;

%--------------------------------------------------------------------
function UIbuttonApply_callback(h, eventdata,u1,u2,u3,u4,u5,u6,um1,um2,um3,um4,um5,um6,um7)
global settings;
global origsettings;
global fig;

rf=get(u1,'String');
cs=get(u2,'Value');
fxy=get(u3,'String');
fz=get(u4,'String');
ov=get(u5,'String');
sw=get(u6,'Value');
if cs==1,
    cs='Y';
else
    cs='N';
end
if sw==1,
    sw='Y';
else
    sw='N';
end

fl=get(um1,'Value')+get(um2,'Value')*2+get(um3,'Value')*4+get(um4,'Value')*8+get(um5,'Value')*32+get(um6,'Value')*64+get(um7,'Value')*128;
settings={rf,cs,fxy,fz,ov,sw,fl};
uiresume(fig);
delete(gcf);

%--------------------------------------------------------------------
function UIbuttonDefault_callback(h, eventdata,u1,u2,u3,u4,u5,u6,um1,um2,um3,um4,um5,um6,um7)
Def=DefaultSetup;
set(u1,'String',Def{1});
set(u2,'Value',Def{2});
set(u3,'String',Def{3});
set(u4,'String',Def{4});
set(u5,'String',Def{5});
set(u6,'Value',Def{6});
fl=Def{7};
set(um1,'Value',bitget(fl,1));
set(um2,'Value',bitget(fl,2));
set(um3,'Value',bitget(fl,3));
set(um4,'Value',bitget(fl,4));
set(um5,'Value',bitget(fl,6));
set(um6,'Value',bitget(fl,7));
set(um7,'Value',bitget(fl,8));

%--------------------------------------------------------------------
function UIbuttonRevert_callback(h,eventdata,u1,u2,u3,u4,u5,u6,um1,um2,um3,um4,um5,um6,um7,rf,cs,fxy,fz,ov,sw,fl)
set(u1,'String',rf);
set(u2,'Value',cs);
set(u3,'String',sprintf('%.1f',fxy));
set(u4,'String',sprintf('%.1f',fz));
set(u5,'String',sprintf('%.6f',ov));
set(u6,'Value',sw);
set(um1,'Value',bitand(fl,1)>0);
set(um2,'Value',bitand(fl,2)>0);
set(um3,'Value',bitand(fl,4)>0);
set(um4,'Value',bitand(fl,8)>0);
set(um5,'Value',bitand(fl,32)>0);
set(um6,'Value',bitand(fl,64)>0);
set(um7,'Value',bitand(fl,128)>0);

%--------------------------------------------------------------------
function UIbuttonCancel_callback(h, eventdata, handles, varargin)
global settings;
global origsettings;
global fig;
settings=origsettings;
uiresume(fig);
delete(gcf);

%--------------------------------------------------------------------
function Def=DefaultSetup()
% Default user setup
%
fl=0;
fl=bitset(fl,1);   % PVE Rousset
fl=bitset(fl,2);   % PVE Meltzer
fl=bitset(fl,3);   % PVE MG
%fl=bitset(fl,4);   % PVE Alfano (PVEout)
%fl=bitset(fl,5);   % Unknown
fl=bitset(fl,6);   % WM CS (Semi ovali)
fl=bitset(fl,7);   % WM Rousset
%fl=bitset(fl,8);   % WM Alfano (linear method)

Def{1}='LOBES_ROI.dat';   % ROI data
Def{2}=1;                 % CSF flag - on
Def{3}='8.0';             % In plane FWHM mm
Def{4}='8.0';             % Axial FWHM mm
Def{5}='0.0';             % Overcorrection
Def{6}=1;                 % Show results - on   
Def{7}=fl;                % Methods turned on (se above)
