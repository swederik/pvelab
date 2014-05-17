function project=configApplyrois_wrapper(project,TaskIndex,MethodIndex,varargin)
% This method is called by the pipeline program. 
% It configures settings for the applyrois atlas method. 
% That is: It selects which ROI-templates applyrois uses.
%
% By Thomas Rask 250104, NRU
%

%____________________________Load settings________________________________

%Defaults settings exist?
if(isempty(project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.default))    
    % No defaults exists... create
    %_____ Define ROIsets
    RoiSets.BundleRoi='nru_all';
    sysDir=project.sysinfo.systemdir;
    stdDir=[sysDir,filesep,'NRU_lib',filesep,'applyrois',filesep,'stdrois',filesep,RoiSets.BundleRoi];
    if ~exist(stdDir,'file')
        stdDir=[sysDir,filesep,'..',filesep,'applyrois',filesep,'stdrois',filesep,RoiSets.BundleRoi];
    end
    %Select 10 non-atrophytemplates or as many as available
    k=1;
    while (k<=10)
      TemplDir=[stdDir,filesep,sprintf('n%02i',k)];
      if (exist(TemplDir,'dir')~=0)
        RoiSets.Sets{k}=TemplDir;
	k=k+1;
      else
	k=11;
      end	
    end
    RoiSets.SetName='roi';
    RoiSets.TemplateType='T1';
    
    project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.default.RoiSets=RoiSets;
end
userConfig=project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.default;

% User defined setting exist?
if(isempty(project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.user))    
    %User settings does not exist in project, use default
    project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.user=userConfig;
else
    %User settings do exist
    userConfig=project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.user;
end;

%____________________________Handle GUI____________________________________



%_______create GUI
color=[252/255 252/255 254/255];
Pos=project.handles.data.figuresize;
fWidth=500;
fHight=320;
Pos(1)=Pos(1)+Pos(3)/2-fWidth/2;
Pos(2)=Pos(2)+Pos(4)/2-fHight/2;
Pos(3)=fWidth;
Pos(4)=fHight;
hFig=figure('tag','configApplyrois_wrapper_fig','position',Pos,'name','Configure Applyrois','menubar','none','resize','off','numberTitle','off','Color',color);%,'visible','off');
set(hFig,'userdata',project);

%Frame
frHight=fHight-55;
frPos=[6,fHight-frHight-5,fWidth-10,frHight];
uicontrol('parent',hFig,'style','frame','position',frPos,'BackgroundColor',color)

%Create listbox
uicontrol('parent',hFig,'style','text','position',[18,fHight-43,360,20],'string','Selected ROI-template set for applyrois to use:','HorizontalAlignment','left','BackgroundColor',color);
felt1=uicontrol('parent',hFig,'string',{},'min',1,'max',100,'style','listbox','position',[18,fHight-frHight+80,410,frHight-123],'HorizontalAlignment','left');

% Fill listbox
if exist(fullfile(userConfig.RoiSets.Sets{1},[userConfig.RoiSets.SetName,'.mat']),'file')==2
    RoiSetExt='.mat';
else
    RoiSetExt='.img';
end
list1={};
for i=1:length(userConfig.RoiSets.Sets)
    list1{end+1}=[fullfile(userConfig.RoiSets.Sets{i},[userConfig.RoiSets.SetName,RoiSetExt]),', ',userConfig.RoiSets.TemplateType,'.img'];
end
set(felt1,'tag','ApplyroisListbox','string',list1,'userdata',userConfig);

uicontrol('parent',hFig,'style','pushbutton','position',[435,fHight-60,52,20],'string','New','callback',@Add_callback,'userdata',felt1);
uicontrol('parent',hFig,'style','pushbutton','position',[435,fHight-83,52,20],'string','Remove','callback',@Remove_callback,'userdata',felt1);

%Buttons
bHight=fHight-frHight-30;
Inf.TaskIndex=TaskIndex;
Inf.MethodIndex=MethodIndex;
Inf.felt1=felt1;
uicontrol('parent',hFig,'style','pushbutton','position',[435,fHight-113,52,20],'string','Default','callback',@Default_callback,'userdata',Inf);

% Defaults for method listbox
StrText{1}='AIR: 12. aligment param';
StrText{2}='AIR: Affine reslice param';
StrText{3}='Warp: Warping param';
StrText{4}='Warp: Warp reslice param ';
StrText{5}='Applyrois: General param ';
uicontrol('parent',hFig,'style','text','position',[18,fHight-frHight+45,360,20],'string','Defaults for estimation and reslicing algorithms:','HorizontalAlignment','left','BackgroundColor',color);
defaultsAlgorithms=uicontrol('parent',hFig,'style','listbox','max',1,'min',0,'position',[18,fHight-frHight+18,410,25],...
    'string',StrText,'callback',@DefaultsAlgorithms_callback);
set(defaultsAlgorithms,'tag','ApplyroisDefAlg','UserData',Inf);

butOk=uicontrol('parent',hFig,'style','pushbutton','position',[175,15,70,bHight],'string','Ok','userdata',Inf,'callback',@Ok_callback);
butCan=uicontrol('parent',hFig,'style','pushbutton','position',[255,15,70,bHight],'string','Cancel','userdata',Inf,'callback',@Cancel_callback);

%Get changed project and out
uiwait(hFig);
if ishandle(hFig)
    project=get(hFig,'userdata');
    delete(hFig);
end

function Ok_callback(Handle,varargin)
%_____Retrieve info
Inf=get(Handle,'userdata');
TaskIndex=Inf.TaskIndex;
MethodIndex=Inf.MethodIndex;
ImageIndex=1;
felt1=Inf.felt1;
userConfig=get(felt1,'userdata');
hFig=get(Handle,'parent');
project=get(hFig,'userdata');

%_____Make changes to project
RoiSets.Sets={};
list1=get(felt1,'string');
for n=1:length(list1)
    Str=list1{n};
    q=find(Str==',');
    [RoiSets.Sets{n}]=fileparts(Str(1:q(1)-1));
end

RoiSets.TemplateType=userConfig.RoiSets.TemplateType;
RoiSets.SetName=userConfig.RoiSets.SetName;
RoiSets.BundleRoi=userConfig.RoiSets.BundleRoi;

project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.user.RoiSets=RoiSets;

% Retrieve changes made to the defaults for the algoritms
if isfield(userConfig,'ApplyroisDef')
    ApplyroisDef=userConfig.ApplyroisDef;
    project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.user.ApplyroisDef=ApplyroisDef;
end

set(hFig,'userdata',project);
uiresume(hFig);


function Cancel_callback(Handle,varargin)
%_____Retrieve info
Inf=get(Handle,'userdata');
TaskIndex=Inf.TaskIndex;
MethodIndex=Inf.MethodIndex;

hFig=get(Handle,'parent');
project=get(hFig,'userdata');

%_____Make changes to project
    msg='User abort, cancel pressed...';
    project=logProject(msg,project,TaskIndex,MethodIndex);

set(hFig,'userdata',project);
uiresume(hFig);

function Add_callback(Handle,varargin)
Felt=get(Handle,'userdata');
try
    userConfig.RoiSets=LoadRoiSets_Callback;
    list1={};
    if exist(fullfile(userConfig.RoiSets.Sets{1},[userConfig.RoiSets.SetName,'.mat']),'file')==2
        RoiSetExt='.mat';
    else
        RoiSetExt='.img';
    end
    for i=1:length(userConfig.RoiSets.Sets)
        list1{end+1}=[fullfile(userConfig.RoiSets.Sets{i},[userConfig.RoiSets.SetName,RoiSetExt]),', ',userConfig.RoiSets.TemplateType,'.img'];
    end
    set(Felt,'string',list1,'userdata',userConfig);
catch
end
    
function Default_callback(Handle,varargin)
Ans=questdlg('Are you sure you want to load default settings?','Load default settings','Yes','No','No');
if strcmp(Ans,'Yes')
    Inf=get(Handle,'userdata');
    TaskIndex=Inf.TaskIndex;
    MethodIndex=Inf.MethodIndex;
    Felt=Inf.felt1;
    project=get(get(Felt,'parent'),'userdata');
    userConfig=project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.default;
    %Fill listbox
    list1={};
    for i=1:length(userConfig.RoiSets.Sets)
        list1{end+1}=[fullfile(userConfig.RoiSets.Sets{i},[userConfig.RoiSets.SetName,'.mat']),', ',userConfig.RoiSets.TemplateType,'.img'];
    end
    set(Felt,'string',list1,'userdata',userConfig);
end


function Remove_callback(Handle,varargin)
Felt=get(Handle,'userdata');
list1=get(Felt,'string');
selected1=get(Felt,'value');
Ans=questdlg('Are you sure you want to delete the selected entries?','Remove selected entries','Yes','No','No');
if strcmp(Ans,'Yes')
    list2={};
    for n=1:length(list1)
        if all(n~=selected1)
            list2{end+1}=list1{n};
        end
    end
    set(Felt,'value',1);
    set(Felt,'string',list2);
end


function DefaultsAlgorithms_callback(Handle,varargin)
Felt=get(Handle,'userdata');
Data=get(Felt.felt1,'UserData');
if isfield(Data,'ApplyroisDef')
    ApplyroisDef=Data.ApplyroisDef;
else
    ApplyroisDef={};
end

DefaultsToChange=get(Handle,'value');
%
switch DefaultsToChange
    case 1
        disp('Change parameters for 12. parameter alignment');
        if ~isfield(ApplyroisDef,'AIR12');
            ApplyroisDef.AIR12={};
        end   
        ApplyroisDef.AIR12=ChangeDefaultsAIR12(ApplyroisDef.AIR12);
    case 2
        disp('Change parameters for reslicing before warping');
        if ~isfield(ApplyroisDef,'AIRreslice');
            ApplyroisDef.AIRreslice={};
        end   
        ApplyroisDef.AIRreslice=ChangeDefaultsAIRreslice(ApplyroisDef.AIRreslice);
   case 3
        disp('Change parameters for warping');
        if ~isfield(ApplyroisDef,'WARP');
            ApplyroisDef.WARP={};
        end   
        ApplyroisDef.WARP=ChangeDefaultsWARP(ApplyroisDef.WARP);
    case 4
        disp('Change parameters for reslicing template MRs');
        if ~isfield(ApplyroisDef,'WARPreslice');
            ApplyroisDef.WARPreslice={};
        end   
        ApplyroisDef.WARPreslice=ChangeDefaultsWARPreslice(ApplyroisDef.WARPreslice);
    case 5
        disp('Change parameters for general applyrois parameters');
        if ~isfield(ApplyroisDef,'General');
            ApplyroisDef.General={};
        end
         ApplyroisDef.General=ChangeDefaultsGeneral(ApplyroisDef.General);
  otherwise
        applyrois_disp('Unknown defaults for applyrois');
end
%
if ~isempty(ApplyroisDef)
    Data.ApplyroisDef=ApplyroisDef;
    set(Felt.felt1,'UserData',Data);
end



function AIR12=ChangeDefaultsAIR12(AIR12)
%
% Functions that opens a userinterface for changing the defualts for the
% 12. parameter AIR aligment
%
if isempty(AIR12)
    AIR12.m=12;
    AIR12.t1=50;
    AIR12.t2=50;
    AIR12.b1=[6.0 6.0 6.0];
    AIR12.b2=[6.0 6.0 6.0];
    AIR12.p1=1;
    AIR12.p2=1;
    AIR12.x=3;
    AIR12.s=[81 1 3];
    AIR12.r=25;
    AIR12.h=5;
    AIR12.c=0.00001;
end
QuestTitle='Defaults for call of AIR: alignlinear';
lineNo=1;
[QuestStr,QuestDef]=SetQuestStrDef(AIR12);
QuestAnswer=inputdlg(QuestStr,QuestTitle,lineNo,QuestDef);
if ~isempty(QuestAnswer)
    AIR12=GetQuestStrDef(QuestStr,QuestAnswer);
end


function AIRreslice=ChangeDefaultsAIRreslice(AIRreslice)
%
% Functions that opens a user interface for changing the defaults for the
% AIR reslicing done before warping
%
if isempty(AIRreslice)
    AIRreslice.n=1;
end
QuestTitle='Defaults for call of AIR: reslice';
lineNo=1;
[QuestStr,QuestDef]=SetQuestStrDef(AIRreslice);
QuestAnswer=inputdlg(QuestStr,QuestTitle,lineNo,QuestDef);
if ~isempty(QuestAnswer)
    AIRreslice=GetQuestStrDef(QuestStr,QuestAnswer);
end


function WARP=ChangeDefaultsWARP(WARP)
%
% Functions that opens a user interface for changing the defaults for the
% WARP reslicing of the template MRs
%
if isempty(WARP)
    WARP.method=3;  % Mutual information
    WARP.repeat=8;
    WARP.outputfileformat=3;
    WARP.logfile='warp.log';
    WARP.resx=[32 64 128];
    WARP.resy=[32 64 128];
    WARP.resz=[20 40 80];
    WARP.alpha=[0.11 0.08 0.06];
    WARP.min_rel_change=0;
    WARP.search=2;
    WARP.segx=4;
    WARP.segy=4;
    WARP.segz=4;
    WARP.auto=0;
    WARP.sig_level='silent';
    WARP.d_filter_fwhm=0.1;
    % Unfortunately this parameter destroys estimation, even if it set to 1
    %WARP.no_reconcile=1;
end
QuestTitle='Defaults for call of WARP: compute_warp';
lineNo=1;
[QuestStr,QuestDef]=SetQuestStrDef(WARP);
QuestAnswer=inputdlg(QuestStr,QuestTitle,lineNo,QuestDef);
if ~isempty(QuestAnswer)
    WARP=GetQuestStrDef(QuestStr,QuestAnswer);
end


function WARPreslice=ChangeDefaultsWARPreslice(WARPreslice)
%
% Functions that opens a user interface for changing the defaults for the
% WARP reslicing of the template MRs
%
if isempty(WARPreslice)
    WARPreslice.T=[1 1 1];
end
QuestTitle='Defaults for call of WARP: warp_reslice';
lineNo=1;
[QuestStr,QuestDef]=SetQuestStrDef(WARPreslice);
QuestAnswer=inputdlg(QuestStr,QuestTitle,lineNo,QuestDef);
if ~isempty(QuestAnswer)
    WARPreslice=GetQuestStrDef(QuestStr,QuestAnswer);
end


function General=ChangeDefaultsGeneral(General)
%
% Functions that opens a user interface for changing the defaults for the
% applyrois general parameters
%
if isempty(General)
    General.FilterWidth='';
end
QuestTitle='Defaults for applyrois';
lineNo=1;
[QuestStr,QuestDef]=SetQuestStrDef(General);
QuestAnswer=inputdlg(QuestStr,QuestTitle,lineNo,QuestDef);
if ~isempty(QuestAnswer)
    General=GetQuestStrDef(QuestStr,QuestAnswer);
end


function [QuestStr,QuestDef]=SetQuestStrDef(ParameterStruct);
%
% Function that converts structure with elements to something that can be
% used as input to inputdlg
%
QuestStr=fieldnames(ParameterStruct);
for i=1:length(QuestStr)
    if isnumeric(ParameterStruct.(QuestStr{i}))
        QuestDef{i}=num2str(ParameterStruct.(QuestStr{i}));
    else
        QuestDef{i}=ParameterStruct.(QuestStr{i});
    end
end


function ParameterStruct=GetQuestStrDef(QuestStr,QuestAnswer);
%
% Function that converts structure with elements to something that can be
% used as input to inputdlg
%
if ~isempty(QuestAnswer)
    for i=1:length(QuestStr)
        if ~isempty(str2num(QuestAnswer{i}))
            ParameterStruct.(QuestStr{i})=str2num(QuestAnswer{i});
        else
            ParameterStruct.(QuestStr{i})=QuestAnswer{i};
        end
    end
else
    ParameterStruct={};
end
