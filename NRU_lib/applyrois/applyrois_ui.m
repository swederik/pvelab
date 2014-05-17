function varargout = applyrois_ui(varargin)
% APPLYROIS_UI Application M-file for applyrois_ui.fig
%    FIG = APPLYROIS_UI launch applyrois_ui GUI.
%    APPLYROIS_UI('callback_name', ...) invoke the named callback.

% Last Modified by GUIDE v2.5 11-Aug-2009 11:43:01

if nargin == 0  % LAUNCH GUI

	fig = openfig(mfilename,'reuse');

	% Use system color scheme for figure:
	set(fig,'Color',get(0,'defaultUicontrolBackgroundColor'));

	% Generate a structure of handles to pass to callbacks, and store it. 
	handles = guihandles(fig);
	guidata(fig, handles);

	if nargout > 0
		varargout{1} = fig;
	end

    InitializeUserInterface(fig);
    
elseif ischar(varargin{1}) % INVOKE NAMED SUBFUNCTION OR CALLBACK

	try
		if (nargout)
			[varargout{1:nargout}] = feval(varargin{:}); % FEVAL switchyard
		else
			feval(varargin{:}); % FEVAL switchyard
		end
	catch
		disp(lasterr);
	end

    SaveUserInterfaceData;
    
end


%| ABOUT CALLBACKS:
%| GUIDE automatically appends subfunction prototypes to this file, and 
%| sets objects' callback properties to call them through the FEVAL 
%| switchyard above. This comment describes that mechanism.
%|
%| Each callback subfunction declaration has the following form:
%| <SUBFUNCTION_NAME>(H, EVENTDATA, HANDLES, VARARGIN)
%|
%| The subfunction name is composed using the object's Tag and the 
%| callback type separated by '_', e.g. 'slider2_Callback',
%| 'figure1_CloseRequestFcn', 'axis1_ButtondownFcn'.
%|
%| H is the callback object's handle (obtained using GCBO).
%|
%| EVENTDATA is empty, but reserved for future use.
%|
%| HANDLES is a structure containing handles of components in GUI using
%| tags as fieldnames, e.g. handles.figure1, handles.slider2. This
%| structure is created at GUI startup using GUIHANDLES and stored in
%| the figure's application data using GUIDATA. A copy of the structure
%| is passed to each callback.  You can store additional information in
%| this structure at GUI startup, and you can change the structure
%| during callbacks.  Call guidata(h, handles) after changing your
%| copy to replace the stored original so that subsequent callbacks see
%| the updates. Type "help guihandles" and "help guidata" for more
%| information.
%|
%| VARARGIN contains any extra arguments you have passed to the
%| callback. Specify the extra arguments by editing the callback
%| property in the inspector. By default, GUIDE sets the property to:
%| <MFILENAME>('<SUBFUNCTION_NAME>', gcbo, [], guidata(gcbo))
%| Add any extra arguments after the last argument, before the final
%| closing parenthesis.


% --------------------------------------------------------------------
function [] = InitializeUserInterface(fig)
%
% Load already entered userinterface data and set files already selected
%
if (exist('applyroisUI.mat')==2)
    LoadedData=load('applyroisUI');
    applyroisUI=LoadedData.applyroisUI;
    Names=fieldnames(applyroisUI);
    for i=1:length(Names)
        h=findobj(fig,'tag',Names{i});
        Val=eval(['applyroisUI.' Names{i} ';']);
        if ~isstruct(Val)   %Special case for defaults
            if ~isnumeric(Val)
                set(h,'string',Val);
            else
                set(h,'value',Val);
            end
        end
    end
end
h=findobj(fig,'tag','ROIvolumeName');
if ~strcmp(get(h,'string'),'None selected')
    set(h,'Enable','on');
end    
h=findobj(fig,'tag','GM_WM_file');
if ~strcmp(get(h,'string'),'None selected')
    set(h,'Enable','on');
end



% --------------------------------------------------------------------
function [] = SaveUserInterfaceData()
%
% Save data entered into userinterface for loading next time
% 
if (exist('applyroisUI.mat')==2)
    LoadedData=load('applyroisUI');
    applyroisUI=LoadedData.applyroisUI;
end    
h=findobj('tag','FunctionalScan');
applyroisUI.FunctionalScan=get(h,'string');
h=findobj('tag','StructuralScan');
applyroisUI.StructuralScan=get(h,'string');
h=findobj('tag','StructuralScanType');
applyroisUI.StructuralScanType=get(h,'string');
h=findobj('tag','ROIsetName');
applyroisUI.ROIsetName=get(h,'string');
h=findobj('tag','AlignmentFile');
applyroisUI.AlignmentFile=get(h,'string');
h=findobj('tag','GM_WM_file');
applyroisUI.GM_WM_file=get(h,'string');
h=findobj('tag','RoiSetsSelected');
applyroisUI.RoiSetsSelected=get(h,'string');
h=findobj('tag','ROIvolumeName');
applyroisUI.ROIvolumeName=get(h,'string');
h=findobj('tag','CreateMRvolumes');
applyroisUI.CreateMRvolumes=get(h,'value');
h=findobj('tag','DoWarp');
applyroisUI.DoWarp=get(h,'value');
save('applyroisUI','applyroisUI');


% --------------------------------------------------------------------
function varargout = FunctionalScan_Callback(h, eventdata, handles, varargin)




% --------------------------------------------------------------------
function varargout = AlignmentFile_Callback(h, eventdata, handles, varargin)




% --------------------------------------------------------------------
function varargout = StructuralScan_Callback(h, eventdata, handles, varargin)




% --------------------------------------------------------------------
function varargout = edit5_Callback(h, eventdata, handles, varargin)




% --------------------------------------------------------------------
function varargout = RoiSetsSelected_Callback(h, eventdata, handles, varargin)




% --------------------------------------------------------------------
function varargout = pushbutton1_Callback(h, eventdata, handles, varargin)




% --------------------------------------------------------------------
function varargout = ROIvolumeName_Callback(h, eventdata, handles, varargin)




% --------------------------------------------------------------------
function varargout = pushbutton2_Callback(h, eventdata, handles, varargin)




% --------------------------------------------------------------------
function varargout = LoadFunctionalScan_Callback(h, eventdata, handles, varargin)
applyrois_disp('Load functional scan buttom pressed');
[FileName PathName] = ...
  uigetfile('*.img', 'Name of file containing functional scan');
if (FileName==0)
  error('Functional scan file has to be defined');
end
h=findobj('tag','FunctionalScan');
set(h,'string',[PathName FileName]);



% --------------------------------------------------------------------
function varargout = LoadStructuralScan_Callback(h, eventdata, handles, varargin)
applyrois_disp('Load structural scan buttom pressed');
[FileName PathName] = ...
    uigetfile('*.img', 'Name of file containing structural scan');
if (FileName==0)
    error('Structural scan file has to be defined');
end
h=findobj('tag','StructuralScan');
set(h,'string',[PathName FileName]);




% --------------------------------------------------------------------
function varargout = LoadAlignmentFile_Callback(h, eventdata, handles, varargin)
applyrois_disp('Load alignment file buttom pressed');
[FileName PathName] = ...
  uigetfile('*.air', 'Name of file containing transformation matrix (Structural->Functional)');
if (FileName==0)
  error('Transformation matrix (AIR file) has to be defined');
end
h=findobj('tag','AlignmentFile');
set(h,'string',[PathName FileName]);



% --------------------------------------------------------------------
function varargout = Load_GM_WM_file_Callback(h, eventdata, handles, varargin)
applyrois_disp('Define GM/WM segmentation file');
[FileName, PathName] = ...
  uigetfile('*.img', 'Name of file with GM/WM segmentation');
if (FileName==0)
  error('No  file with GM/WM segmentation defined');
end
h=findobj('tag','GM_WM_file');
set(h,'string',[PathName FileName]);
set(h,'Enable','on');


% --------------------------------------------------------------------
function varargout = LoadRoiSets_Callback(h, eventdata, handles, varargin)
applyrois_disp('Load ROI sets buttom pressed');
%
FileInfo=which('applyrois');
[StdRoiPath,StdRoiName,Ext]=fileparts(FileInfo);
StdRoiPath=[StdRoiPath filesep 'stdrois'];
BundleRoiSetPath=FindDirName(StdRoiPath,1);
BundleRoiPath=[StdRoiPath filesep BundleRoiSetPath{1}];
RoiSetsSelected=FindDirName(BundleRoiPath,0);
h=findobj('tag','RoiSetsSelected');
for i=1:length(RoiSetsSelected)
  StdROIs{i}=[BundleRoiPath filesep RoiSetsSelected{i}];
end  
set(h,'string',StdROIs,'value',1);
%
% Select ROI set
%
d = dir([BundleRoiPath filesep RoiSetsSelected{1} filesep '*.mat']);
if (length(d)~=0)  %.mat files available (editroi ROI files)
  Counter=1;
  for i=1:length(d)
    if (~strncmp(d(i).name,'.',1))&(~strncmp(d(i).name,'..',2))...
            &(~strncmp(d(i).name,'CVS',3))&(d(i).isdir==0)
        QuestDlg(Counter) = {d(i).name};
        Counter=Counter+1;
    end
  end
  if length(QuestDlg)>1
    [s,v] = listdlg('PromptString','Which standard ROIs to use?',...
        'SelectionMode','single',...
        'ListString',QuestDlg);
    if v==0
        error('No selection made');
    end
    StdRoiName=QuestDlg{s};
  else
    StdRoiName=QuestDlg{1};
  end
else               % assuming volume (analyze) ROI files
  d = dir([BundleRoiPath filesep RoiSetsSelected{1} filesep '*.img']);
  Counter=1;
  for i=1:length(d)
    if (~strncmp(d(i).name,'.',1))&(~strncmp(d(i).name,'..',2))...
            &(~strncmp(d(i).name,'CVS',3))&(d(i).isdir==0)
        QuestDlg(Counter) = {d(i).name};
        Counter=Counter+1;
    end
  end
  if length(QuestDlg)>1
    [s,v] = listdlg('PromptString','Which standard ROIs to use?',...
        'SelectionMode','single',...
        'ListString',QuestDlg);
    if v==0
        error('No selection made');
    end
    StdRoiName=QuestDlg{s};
  else
    StdRoiName=QuestDlg{1};
  end
end
%
[fp,ROIsetName,ext]=fileparts(StdRoiName);
h=findobj('tag','ROIsetName');
set(h,'String',ROIsetName);
%
% Select type of structural scan
%
d = dir([BundleRoiPath filesep RoiSetsSelected{1} filesep '*.img']);
Counter=1;
for i=1:length(d)
    if (~strncmp(d(i).name,'.',1))&(~strncmp(d(i).name,'..',2))...
            &(~strncmp(d(i).name,'CVS',3))&(d(i).isdir==0)
        QuestDlg(Counter) = {d(i).name};
        Counter=Counter+1;
    end
end
if length(QuestDlg)>1
    [s,v] = listdlg('PromptString','Which type of structural scan?',...
        'SelectionMode','single',...
        'ListString',QuestDlg);
    if v==0
        error('No selection made');
    end
    StructuralScanTempl=QuestDlg{s};
else
    StructuralScanTempl=QuestDlg{1};
end
[fp,StructuralScanType,ext]=fileparts(StructuralScanTempl);
h=findobj('tag','StructuralScanType');
set(h,'String',StructuralScanType);


% --------------------------------------------------------------------
function SelectedDirs=FindDirName(BaseDir,RoiSetsSelection);
%
% Functions that either return cell array of dirs which has been selected.
% If 'definition.txt' is present in the dirs this txt string is used for
% selection else the dir name is used 
%
d = dir(BaseDir);
Counter=1;
for i=1:length(d)
  if (~strncmp(d(i).name,'.',1))&(~strncmp(d(i).name,'..',2))...
	&(~strncmp(d(i).name,'CVS',3))&(d(i).isdir==1)
    str(Counter) = {d(i).name};
    Counter=Counter+1;
  end
end
for i=1:length(str)
    DefinitionFile=fullfile(BaseDir,str{i},'definition.txt');
    if exist(DefinitionFile)==2
        pid=fopen(DefinitionFile,'r');
        if (pid~=-1)
            QuestDlg{i}=fgetl(pid);
            fclose(pid);
        else
            QuestDlg{i}=str{i};
        end
    else
        QuestDlg{i}=str{i};
    end
end
if (RoiSetsSelection==1)
   [s,v] = listdlg('PromptString','Which standard ROI bundles to use?',...
       'SelectionMode','single',...
       'ListString',QuestDlg);
else
   [s,v] = listdlg('PromptString','Which templates to use?',...
       'SelectionMode','multiple',...
       'ListString',QuestDlg);
end
if v==0
    error('No selection made');
end
SelectedDirs={str{s}};
            


% --------------------------------------------------------------------
function varargout = DefineNameOfVolumeFile_Callback(h, eventdata, handles, varargin)
applyrois_disp('Define output volume name buttom pressed');
[FileName, PathName] = ...
  uiputfile('*.img', 'Name of volume file for storing ROIs');
if (FileName==0)
  error('No volume file for storing ROIs are defined');
end
h=findobj('tag','ROIvolumeName');
set(h,'string',[PathName FileName]);
set(h,'Enable','on');




% --------------------------------------------------------------------
function varargout = StartProcessing_Callback(h, eventdata, handles, varargin)
applyrois_disp('Start processing buttom pressed');
Error=0;
h=findobj('tag','FunctionalScan');
FunctionalScan=get(h,'string');
if strcmp(FunctionalScan,'None selected')
    Error=1;
end
%
h=findobj('tag','StructuralScan');
StructuralScan=get(h,'string');
if strcmp(StructuralScan,'None selected')
    Error=1;
end    
h=findobj('tag','AlignmentFile');
AlignmentFile=get(h,'string');
if strcmp(AlignmentFile,'None selected')
    Error=1;
end    
h=findobj('tag','GM_WM_file');
GM_WM_file=get(h,'string');
if strcmp(GM_WM_file,'None selected')
   GM_WM_file='';
end
h=findobj('tag','RoiSetsSelected');
ROI.Sets=get(h,'string');
if strcmp(ROI.Sets,'None selected')
    Error=1;
end    
h=findobj('tag','ROIsetName');
ROI.SetName=get(h,'string');
if strcmp(ROI.SetName,'Unknown')
   ROI.SetName='';
end
h=findobj('tag','StructuralScanType');
ROI.TemplateType=get(h,'string');
if strcmp(ROI.TemplateType,'Unknown')
   ROI.TemplateType='';
end
h=findobj('tag','ROIvolumeName');
RoiVolumeName=get(h,'string');
if strcmp(RoiVolumeName,'None selected')
   RoiVolumeName='';
end
h=findobj('tag','CreateMRvolumes');
CreateMRvolumes=get(h,'value');
if CreateMRvolumes~=0
   CreateMRvolumes=1;
end
h=findobj('tag','DoWarp');
DoWarp=get(h,'value');
if DoWarp~=0
   DoWarp=1;
end
%
if (exist('applyroisUI.mat')==2)
    LoadedData=load('applyroisUI');
    applyroisUI=LoadedData.applyroisUI;
end
if isfield(applyroisUI,'Defaults')
    Defaults=applyroisUI.Defaults;
else
    Defaults=[];
end
%
if Error
   errordlg('Either functional scan, structural scan, alignment file or ROI set missing');
else
   %
   h=findobj('tag','applyrois_ui');
   set(h,'pointer','watch');
   applyrois(FunctionalScan,StructuralScan,AlignmentFile,ROI,...
       RoiVolumeName,GM_WM_file,CreateMRvolumes,Defaults,DoWarp);
   set(h,'pointer','arrow');
end




% --------------------------------------------------------------------
function varargout = ClrGmWmFile_Callback(h, eventdata, handles, varargin)
applyrois_disp('Clear GM WM file buttom pressed');
h=findobj('tag','GM_WM_file');
set(h,'string','None selected');



% --------------------------------------------------------------------
function varargout = ClrRoiSets_Callback(h, eventdata, handles, varargin)
applyrois_disp('Clear ROI set buttom pressed');
h=findobj('tag','RoiSetsSelected');
set(h,'string','None selected');
h=findobj('tag','StructuralScanType');
set(h,'string','Unknown');
h=findobj('tag','ROIsetName');
set(h,'string','Unknown');



% --------------------------------------------------------------------
function varargout = ClrRoiVolume_Callback(h, eventdata, handles, varargin)
applyrois_disp('Clear ROI volume file buttom pressed');
h=findobj('tag','ROIvolumeName');
set(h,'string','None selected');



% --------------------------------------------------------------------
function varargout = ClrAlignmentFile_Callback(h, eventdata, handles, varargin)
applyrois_disp('Clear Alignement file buttom pressed');
h=findobj('tag','AlignmentFile');
set(h,'string','None selected');



% --------------------------------------------------------------------
function varargout = ClrStructuralFile_Callback(h, eventdata, handles, varargin)
applyrois_disp('Clear structural buttom pressed');
h=findobj('tag','StructuralScan');
set(h,'string','None selected');




% --------------------------------------------------------------------
function varargout = ClrFunctionalFile_Callback(h, eventdata, handles, varargin)
applyrois_disp('Clear Functional scan buttom pressed');
h=findobj('tag','FunctionalScan');
set(h,'string','None selected');


% --- Executes on button press in CreateMRvolumes.
function CreateMRvolumes_Callback(hObject, eventdata, handles)
% hObject    handle to CreateMRvolumes (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of CreateMRvolumes
applyrois_disp('Create MR volume buttom pressed');



%---------------------------------------------------------------------
function [] = applyrois_disp(txt_str);
%
% wrapper for disp, so it is easy to disable listing of which buttoms have
% been pressed, switch the commented/uncomment line
%
disp(txt_str);
%a=1;


% --- Executes on button press in Defaults.
function Defaults_Callback(hObject, eventdata, handles)
% hObject    handle to Defaults (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
applyrois_disp('Defaults buttom pressed');
if (exist('applyroisUI.mat')==2)
    LoadedData=load('applyroisUI');
    applyroisUI=LoadedData.applyroisUI;
end
if ~exist('applyroisUI')||~isfield(applyroisUI,'Defaults')
    applyroisUI.Defaults=[];
end
%
DefaultsToChange=get(findobj('Tag','Defaults'),'Value');
set(findobj('Tag','Defaults'),'Value',1);
%
switch DefaultsToChange
    case 2
        applyrois_disp('12. parameter alignment');
        if isfield(applyroisUI.Defaults,'AIR12');
            Defaults.AIR12=applyroisUI.Defaults.AIR12;
        else
            Defaults.AIR12='';
        end   
        applyroisUI.Defaults.AIR12=ChangeDefaultsAIR12(Defaults.AIR12);
    case 3
        applyrois_disp('reslicing before warping');
         if isfield(applyroisUI.Defaults,'AIRreslice');
            Defaults.AIRreslice=applyroisUI.Defaults.AIRreslice;
        else
            Defaults.AIRreslice='';
        end   
        applyroisUI.Defaults.AIRreslice=ChangeDefaultsAIRreslice(Defaults.AIRreslice);
   case 4
        applyrois_disp('warping');
         if isfield(applyroisUI.Defaults,'WARP');
            Defaults.WARP=applyroisUI.Defaults.WARP;
        else
            Defaults.WARP='';
        end   
        applyroisUI.Defaults.WARP=ChangeDefaultsWARP(Defaults.WARP);
    case 5
        applyrois_disp('reslicing template MRs');
        if isfield(applyroisUI.Defaults,'WARPreslice');
            Defaults.WARPreslice=applyroisUI.Defaults.WARPreslice;
        else
            Defaults.WARPreslice='';
        end   
        applyroisUI.Defaults.WARPreslice=ChangeDefaultsWARPreslice(Defaults.WARPreslice);
    case 6
        applyrois_disp('General applyrois defaults');
        if isfield(applyroisUI.Defaults,'General');
            Defaults.General=applyroisUI.Defaults.General;
        else
            Defaults.General='';
        end   
        applyroisUI.Defaults.General=ChangeDefaultsGeneral(Defaults.General);
   otherwise
        applyrois_disp('Unknown default');
end
%
save('applyroisUI','applyroisUI');


% --- Executes on button press in StructuralScantypeTxt.
function StructuralScantypeTxt_Callback(hObject, eventdata, handles)
% hObject    handle to StructuralScantypeTxt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in StructuralScanType.
function StructuralScanType_Callback(hObject, eventdata, handles)
% hObject    handle to StructuralScanType (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


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
AIR12=GetQuestStrDef(QuestStr,QuestAnswer);



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
AIRreslice=GetQuestStrDef(QuestStr,QuestAnswer);


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
WARP=GetQuestStrDef(QuestStr,QuestAnswer);


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
WARPreslice=GetQuestStrDef(QuestStr,QuestAnswer);


function General=ChangeDefaultsGeneral(General)
%
% Functions that opens a user interface for changing the defaults for the
% WARP reslicing of the template MRs
%
if isempty(General)
    General.FilterWidth='';
end
QuestTitle='Defaults for applyrois';
lineNo=1;
[QuestStr,QuestDef]=SetQuestStrDef(General);
QuestAnswer=inputdlg(QuestStr,QuestTitle,lineNo,QuestDef);
General=GetQuestStrDef(QuestStr,QuestAnswer);


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
for i=1:length(QuestStr)
    if ~isempty(str2num(QuestAnswer{i}))
        ParameterStruct.(QuestStr{i})=str2num(QuestAnswer{i});
    else
        ParameterStruct.(QuestStr{i})=QuestAnswer{i};    
    end
end


% --- If Enable == 'on', executes on mouse press in 5 pixel border.
% --- Otherwise, executes on mouse press in 5 pixel border or over DefineNameOfVolumeFile.
function DefineNameOfVolumeFile_ButtonDownFcn(hObject, eventdata, handles)
% hObject    handle to DefineNameOfVolumeFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in DoWarp.
function DoWarp_Callback(hObject, eventdata, handles)
% hObject    handle to DoWarp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of DoWarp
