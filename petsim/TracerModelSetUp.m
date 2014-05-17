function varargout = TracerModelSetUp(varargin)
% TRACERMODELSETUP M-file for TracerModelSetUp.fig
%      TRACERMODELSETUP, by itself, creates a new TRACERMODELSETUP or raises the existing
%      singleton*.
%
%      H = TRACERMODELSETUP returns the handle to a new TRACERMODELSETUP or the handle to
%      the existing singleton*.
%
%      TRACERMODELSETUP('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in TRACERMODELSETUP.M with the given input arguments.
%
%      TRACERMODELSETUP('Property','Value',...) creates a new TRACERMODELSETUP or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before TracerModelSetUp_OpeningFunction gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to TracerModelSetUp_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help TracerModelSetUp

% Last Modified by GUIDE v2.5 06-Aug-2004 12:08:21

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @TracerModelSetUp_OpeningFcn, ...
                   'gui_OutputFcn',  @TracerModelSetUp_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin & isstr(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end



% End initialization code - DO NOT EDIT

function bloodcurvepar = getPredefinedBloodCurve(handles)
% Calculate the predefined blood curve 

btype = handles.bloodtype;
if  btype == 1 | btype == 2 | btype == 3 |btype == 4 | ...
        btype == 5 |btype == 6 |btype == 7 | btype == 8 |btype == 9 
        load blood_curves_pars.mat;
     	bloodpar = p(handles.bloodtype,:);
        bloodcurvepar = bloodpar;
end;


function setFrameTimesManual( step, numofsteps, handles )
   set( handles.StepTimeEdit, 'String', num2str( step ) );
   set( handles.NumOfStepEdit, 'String' , num2str( numofsteps ));
   set( handles.NumofStepText, 'Visible', 'on' );
   set( handles.FrameStepText, 'Visible', 'on' );
   set( handles.StepTimeEdit, 'Visible', 'on' );
   set( handles.NumOfStepEdit, 'Visible', 'on' );    
   set( handles.frameTimesFileNameText, 'Visible', 'off' );
   set( handles.frameTimesFileNameText, 'String', '' );        
    
function setFrameTimeName( fname, handles )
   set( handles.NumofStepText, 'Visible', 'off' );
   set( handles.FrameStepText, 'Visible', 'off' );
   set( handles.StepTimeEdit, 'Visible', 'off' );
   set( handles.NumOfStepEdit, 'Visible', 'off' );    
   set(handles.frameTimesFileNameText, 'String', fname );
   set( handles.frameTimesFileNameText, 'Visible', 'on' );

function showIsotope( thalf, handles )
    if ( handles.T_half == 20.4 ) popupmenuitem=1; end;
    if ( handles.T_half == 109.8 ) popupmenuitem=2; end;
    if ( handles.T_half == 2.03 ) popupmenuitem=3; end;
    if ( handles.T_half == 9.97 ) popupmenuitem=4; end;
    set( handles.IsotopePopupmenu, 'Value', popupmenuitem);
 
        
% --- Executes just before TracerModelSetUp is made visible.
function TracerModelSetUp_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to TracerModelSetUp (see VARARGIN)

% Choose default command line output for TracerModelSetUp

handles.output = hObject;

if ishandle(varargin{1}) % figure handle 
        % store the handle to main_gui figure 
        handles.PetAnalSimulator_gui = varargin{1}; 
else % handles structure 
        % save the handle for MainGUI's figure in the handles 
        %structure. 
        % get it from the handles structure that was used as input% 
       main_gui_handles = varargin{1}; 
       handles.PetAnalSimulator_gui = main_gui_handles.main_gui; 
end 

%%% default values
handles.bloodtype = 7;
handles.bloodcurvepar = getPredefinedBloodCurve( handles);
handles.T_half = 20.4; %C11 is the default [min]
handles.FrameStartTime = 0;
handles.FrameStopTime = 0;
set( handles.NumOfStepEdit, 'String', '0');
set( handles.StepTimeEdit, 'String', '0');

%%% load from the main if exists
main_gui_handles = guidata(handles.PetAnalSimulator_gui);
bloodcurvename=num2str( handles.bloodtype );
if isfield( main_gui_handles, 'bloodtype' )
    handles.bloodtype = main_gui_handles.bloodtype;
    bloodcurvename=num2str( handles.bloodtype );
    if handles.bloodtype == -1 
        bloodcurvename=main_gui_handles.BloodCurveFileName;
    end
end
set(handles.BloodCurveTypeEdit, 'String', bloodcurvename );


if isfield( main_gui_handles, 'bloodCurve' )
    handles.bloodcurvepar = main_gui_handles.bloodcurvepar;
end
    
if isfield( main_gui_handles, 'T_half' )
    handles.T_half=main_gui_handles.T_half;
    showIsotope( handles.T_half, handles );
end    
if isfield( main_gui_handles, 'FrameStartTime' )
    handles.FrameStartTime=main_gui_handles.FrameStartTime;
  
end
set( handles.FrameStartTimeEdit, 'String', num2str(handles.FrameStartTime));  

if isfield( main_gui_handles, 'FrameStopTime' )
    handles.FrameStopTime = main_gui_handles.FrameStopTime;
end;
set(  handles.FrameStopTimeEdit, 'String',num2str(handles.FrameStopTime));

if isfield(main_gui_handles,'TrackinModelFile' )
    set( handles.TrackinModelFileName, 'String', main_gui_handles.TrackinModelFile);
end


if isfield( main_gui_handles,'frameTimeMode' )
    handles.frameTimeMode=main_gui_handles.frameTimeMode;
    if strcmp(main_gui_handles.frameTimeMode,'manual')
           step=0;numofstep=0;
        if isfield(main_gui_handles,'StepTime')
            step=main_gui_handles.StepTime;
        end
        if isfield(main_gui_handles,'NumOfStep' )
            numofstep=main_gui_handles.NumOfStep;
        end 
        setFrameTimesManual(step, numofstep, handles );
    else
        handles.frameTimeFileName=main_gui_handles.frameTimeFileName;
        setFrameTimeName( main_gui_handles.frameTimeFileName, handles );
    end
        
    if isfield(main_gui_handles,'frame_times')
        handles.frame_times=main_gui_handles.frame_times;
        handles.frame_lengths=main_gui_handles.frame_lengths;
    	handles.tissue_ts=main_gui_handles.tissue_ts;    
    end
end


% Update handles structure
guidata(hObject, handles);

% pass the input kinetic konstants to the Edit boxes

NumOfKinparameters = size(main_gui_handles.KineticConstant,2);
for i = 1 : NumOfKinparameters
	for j = 1 : main_gui_handles.NumOfSegments
        eval( [' set(handles.Segm',num2str(j),'k',num2str(i), ...
                'Edit,''String'',main_gui_handles.KineticConstant(',num2str(j),',',num2str(i),') )'] );
	end
end


% Update handles structure
guidata(hObject, handles);

% UIWAIT makes TracerModelSetUp wait for user response (see UIRESUME)
%uiwait(handles.TracerModelSetUp_Figure);


% --- Outputs from this function are returned to the command line.
function varargout = TracerModelSetUp_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;




% --- Executes on button press in BloodCurveTypePushbutton.
function BloodCurveTypePushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to BloodCurveTypePushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
show_predef_bloodcurves;

% --- Executes during object creation, after setting all properties.
function BloodCurveTypeEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to BloodCurveTypeEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end


function BloodCurveTypeEdit_Callback(hObject, eventdata, handles)
% hObject    handle to BloodCurveTypeEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of BloodCurveTypeEdit as text
%        str2double(get(hObject,'String')) returns contents of BloodCurveTypeEdit as a double
handles.bloodtype = str2double(get(handles.BloodCurveTypeEdit,'String'));
handles.bloodcurvepar = getPredefinedBloodCurve(handles);
guidata(hObject, handles);


function [handles,ok]=calcFrameTimesManual( hObject, handles )
if isfield(handles, 'frameTimeMode' ) 
    if strcmp(handles.frameTimeMode,'manual' )
        StepNumber = str2double(get(handles.NumOfStepEdit,'string'));
        steptime=get(handles.StepTimeEdit,'string');
        frame_lengths = str2double(steptime)*ones(1,StepNumber);
        if ( StepNumber*steptime==0) 
            hm = msgbox('No frame times has been defined!','PETAnalSim Info' );
            ok=false;
            return;
        end
        tissue_ts(1)=0; 
        for i=1:StepNumber
            tissue_ts(i+1) = tissue_ts(i)+frame_lengths(i);
        end
        frame_times = tissue_ts(1:end-1)+frame_lengths/2;
        handles.frame_times = frame_times;
        handles.frame_lengths = frame_lengths;
        handles.tissue_ts = tissue_ts;

        % Update handles structure
        guidata(hObject, handles);
    end
else
    hm = msgbox('No frame times has been defined!','PETAnalSim Info' );
    ok=false;
    return;
end  
ok=true;

% --- Executes on button press in ClosePushbutton.
function ClosePushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to ClosePushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
selection = questdlg(['Apply current ' get(handles.TracerModelSetUp_Figure,'Name') '?'],...
                     ['Apply current ' get(handles.TracerModelSetUp_Figure,'Name') '...'],...
                     'Yes','No','Yes');
if strcmp(selection,'No')
    return;
end
% pass the input data to the PetAnalSimulator_gui handle
main_gui_handles = guidata(handles.PetAnalSimulator_gui);
NumOfKinparameters = size(main_gui_handles.KineticConstant,2);
for i = 1 : NumOfKinparameters
	for j = 1 : main_gui_handles.NumOfSegments
        main_gui_handles.KineticConstant(j,i) = ...
            eval( ['str2double(get(handles.Segm',num2str(j),'k',num2str(i),'Edit,''String''))'] );
	end
end

% calculate frame times if frame time set is manual
[handles,ok] = calcFrameTimesManual( hObject, handles);
if ~ok return; end;

% handles.bloodcurvepar = getPredefinedBloodCurve(handles);
main_gui_handles.bloodtype = handles.bloodtype;
main_gui_handles.bloodcurvepar = handles.bloodcurvepar;
main_gui_handles.T_half  = handles.T_half;
main_gui_handles.FrameStartTime = handles.FrameStartTime;
main_gui_handles.FrameStopTime = handles.FrameStopTime;
main_gui_handles.StepTime= str2double( get(handles.StepTimeEdit, 'String' ));
main_gui_handles.NumOfStep= str2double(get(handles.NumOfStepEdit, 'String' ));
if isfield( handles,'frameTimeMode' )
    main_gui_handles.frameTimeMode=handles.frameTimeMode;
end

if isfield( handles,'BloodCurveFileName')
    main_gui_handles.BloodCurveFileName= handles.BloodCurveFileName;
end

if isfield (handles,'TrackinModelFile' )
    main_gui_handles.TrackinModelFile=handles.TrackinModelFile;
end

if isfield (handles,'frameTimeFileName' )
    main_gui_handles.frameTimeFileName=handles.frameTimeFileName;
end

if  ~isfield(handles,'frame_times') 
    hm = msgbox('No frame times has been defined!','PETAnalSim Info' );
else
	main_gui_handles.frame_times = handles.frame_times;
	main_gui_handles.frame_lengths = handles.frame_lengths;
	main_gui_handles.tissue_ts = handles.tissue_ts;
       
    % calculate the tissue curves for the segments     
    tissue_as = zeros(main_gui_handles.NumOfSegments,length(handles.frame_times));
	for i = 1 : main_gui_handles.NumOfSegments
        tissue_as(i,:) = create_4CompTacs(main_gui_handles.KineticConstant(i,:), ...
            handles.tissue_ts,handles.bloodcurvepar     );
                %    .*(2.^(-handles.frame_times/handles.T_half)
	end
    main_gui_handles.tissue_as = tissue_as;
end
main_gui_handles.existValidModel=true;
% Update the handles for the main gui 
guidata(handles.PetAnalSimulator_gui,main_gui_handles); 
% Update current figures handles structure 
guidata(hObject, handles);
scrsz = get(0,'ScreenSize');
%delete(handles.TracerModelSetUp_Figure);



% --- Executes during object creation, after setting all properties.
function K1edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to K1edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function K1edit_Callback(hObject, eventdata, handles)
% hObject    handle to K1edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of K1edit as text
%        str2double(get(hObject,'String')) returns contents of K1edit as a double


% --- Executes during object creation, after setting all properties.
function k2edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to segm1k2edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function k2edit_Callback(hObject, eventdata, handles)
% hObject    handle to segm1k2edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of segm1k2edit as text
%        str2double(get(hObject,'String')) returns contents of segm1k2edit as a double


% --- Executes during object creation, after setting all properties.
function k3edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to segm1k3edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function k3edit_Callback(hObject, eventdata, handles)
% hObject    handle to segm1k3edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of segm1k3edit as text
%        str2double(get(hObject,'String')) returns contents of segm1k3edit as a double


% --- Executes during object creation, after setting all properties.
function k4edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to segm1k4edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function k4edit_Callback(hObject, eventdata, handles)
% hObject    handle to segm1k4edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of segm1k4edit as text
%        str2double(get(hObject,'String')) returns contents of segm1k4edit as a double


% --- Executes during object creation, after setting all properties.
function k5edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to segm1k5edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function k5edit_Callback(hObject, eventdata, handles)
% hObject    handle to segm1k5edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of segm1k5edit as text
%        str2double(get(hObject,'String')) returns contents of segm1k5edit as a double


% --- Executes during object creation, after setting all properties.
function k6edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to segm1k6edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function k6edit_Callback(hObject, eventdata, handles)
% hObject    handle to segm1k6edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of segm1k6edit as text
%        str2double(get(hObject,'String')) returns contents of segm1k6edit as a double


% --- Executes during object creation, after setting all properties.
function Vfedit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Vfedit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function Vfedit_Callback(hObject, eventdata, handles)
% hObject    handle to Vfedit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Vfedit as text
%        str2double(get(hObject,'String')) returns contents of Vfedit as a double


% --- Executes during object creation, after setting all properties.
function Segm1K1Edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Segm1K1Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function Segm1K1Edit_Callback(hObject, eventdata, handles)
% hObject    handle to Segm1K1Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Segm1K1Edit as text
%        str2double(get(hObject,'String')) returns contents of Segm1K1Edit as a double


% --- Executes during object creation, after setting all properties.
function Segm1k2Edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Segm1k2Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function Segm1k2Edit_Callback(hObject, eventdata, handles)
% hObject    handle to Segm1k2Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Segm1k2Edit as text
%        str2double(get(hObject,'String')) returns contents of Segm1k2Edit as a double


% --- Executes during object creation, after setting all properties.
function Segm1k3Edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Segm1k3Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function Segm1k3Edit_Callback(hObject, eventdata, handles)
% hObject    handle to Segm1k3Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Segm1k3Edit as text
%        str2double(get(hObject,'String')) returns contents of Segm1k3Edit as a double


% --- Executes during object creation, after setting all properties.
function Segm1k4Edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Segm1k4Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function Segm1k4Edit_Callback(hObject, eventdata, handles)
% hObject    handle to Segm1k4Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Segm1k4Edit as text
%        str2double(get(hObject,'String')) returns contents of Segm1k4Edit as a double


% --- Executes during object creation, after setting all properties.
function Segm1k5Edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Segm1k5Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function Segm1k5Edit_Callback(hObject, eventdata, handles)
% hObject    handle to Segm1k5Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Segm1k5Edit as text
%        str2double(get(hObject,'String')) returns contents of Segm1k5Edit as a double


% --- Executes during object creation, after setting all properties.
function Segm1k6Edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Segm1k6Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function Segm1k6Edit_Callback(hObject, eventdata, handles)
% hObject    handle to Segm1k6Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Segm1k6Edit as text
%        str2double(get(hObject,'String')) returns contents of Segm1k6Edit as a double


% --- Executes during object creation, after setting all properties.
function Segm1kEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Segm1k7Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function Segm1kEdit_Callback(hObject, eventdata, handles)
% hObject    handle to Segm1k7Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Segm1k7Edit as text
%        str2double(get(hObject,'String')) returns contents of Segm1k7Edit as a double


% --- Executes during object creation, after setting all properties.
function Segm2K1Edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Segm2K1Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function Segm2K1Edit_Callback(hObject, eventdata, handles)
% hObject    handle to Segm2K1Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Segm2K1Edit as text
%        str2double(get(hObject,'String')) returns contents of Segm2K1Edit as a double


% --- Executes during object creation, after setting all properties.
function Segm2k2Edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Segm2k2Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function Segm2k2Edit_Callback(hObject, eventdata, handles)
% hObject    handle to Segm2k2Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Segm2k2Edit as text
%        str2double(get(hObject,'String')) returns contents of Segm2k2Edit as a double


% --- Executes during object creation, after setting all properties.
function edit18_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit18 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function edit18_Callback(hObject, eventdata, handles)
% hObject    handle to edit18 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit18 as text
%        str2double(get(hObject,'String')) returns contents of edit18 as a double


% --- Executes during object creation, after setting all properties.
function Segm2k4Edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Segm2k4Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function Segm2k4Edit_Callback(hObject, eventdata, handles)
% hObject    handle to Segm2k4Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Segm2k4Edit as text
%        str2double(get(hObject,'String')) returns contents of Segm2k4Edit as a double


% --- Executes during object creation, after setting all properties.
function Segm2k5Edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Segm2k5Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function Segm2k5Edit_Callback(hObject, eventdata, handles)
% hObject    handle to Segm2k5Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Segm2k5Edit as text
%        str2double(get(hObject,'String')) returns contents of Segm2k5Edit as a double


% --- Executes during object creation, after setting all properties.
function Segm2k6Edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Segm2k6Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function Segm2k6Edit_Callback(hObject, eventdata, handles)
% hObject    handle to Segm2k6Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Segm2k6Edit as text
%        str2double(get(hObject,'String')) returns contents of Segm2k6Edit as a double


% --- Executes during object creation, after setting all properties.
function Segm2k7Edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Segm2k7Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function Segm2k7Edit_Callback(hObject, eventdata, handles)
% hObject    handle to Segm2k7Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Segm2k7Edit as text
%        str2double(get(hObject,'String')) returns contents of Segm2k7Edit as a double


% --- Executes during object creation, after setting all properties.
function SegmK1Edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Segm3K1Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function SegmK1Edit_Callback(hObject, eventdata, handles)
% hObject    handle to Segm3K1Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Segm3K1Edit as text
%        str2double(get(hObject,'String')) returns contents of Segm3K1Edit as a double


% --- Executes during object creation, after setting all properties.
function Segm3k2Edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Segm3k2Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function Segm3k2Edit_Callback(hObject, eventdata, handles)
% hObject    handle to Segm3k2Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Segm3k2Edit as text
%        str2double(get(hObject,'String')) returns contents of Segm3k2Edit as a double


% --- Executes during object creation, after setting all properties.
function Segm3k3Edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Segm3k3Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function Segm3k3Edit_Callback(hObject, eventdata, handles)
% hObject    handle to Segm3k3Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Segm3k3Edit as text
%        str2double(get(hObject,'String')) returns contents of Segm3k3Edit as a double


% --- Executes during object creation, after setting all properties.
function edit26_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit26 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function edit26_Callback(hObject, eventdata, handles)
% hObject    handle to edit26 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit26 as text
%        str2double(get(hObject,'String')) returns contents of edit26 as a double


% --- Executes during object creation, after setting all properties.
function Segmk5Edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Segm3k5Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function Segmk5Edit_Callback(hObject, eventdata, handles)
% hObject    handle to Segm3k5Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Segm3k5Edit as text
%        str2double(get(hObject,'String')) returns contents of Segm3k5Edit as a double


% --- Executes during object creation, after setting all properties.
function edit28_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit28 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function edit28_Callback(hObject, eventdata, handles)
% hObject    handle to edit28 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit28 as text
%        str2double(get(hObject,'String')) returns contents of edit28 as a double


% --- Executes during object creation, after setting all properties.
function Segm3k7tEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Segm3k7Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function Segm3k7tEdit_Callback(hObject, eventdata, handles)
% hObject    handle to Segm3k7Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Segm3k7Edit as text
%        str2double(get(hObject,'String')) returns contents of Segm3k7Edit as a double


% --- Executes during object creation, after setting all properties.
function edit30_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit30 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function edit30_Callback(hObject, eventdata, handles)
% hObject    handle to edit30 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit30 as text
%        str2double(get(hObject,'String')) returns contents of edit30 as a double


% --- Executes during object creation, after setting all properties.
function Segm4k2Edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Segm4k2Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function Segm4k2Edit_Callback(hObject, eventdata, handles)
% hObject    handle to Segm4k2Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Segm4k2Edit as text
%        str2double(get(hObject,'String')) returns contents of Segm4k2Edit as a double


% --- Executes during object creation, after setting all properties.
function Segm4k3Edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Segm4k3Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function Segm4k3Edit_Callback(hObject, eventdata, handles)
% hObject    handle to Segm4k3Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Segm4k3Edit as text
%        str2double(get(hObject,'String')) returns contents of Segm4k3Edit as a double


% --- Executes during object creation, after setting all properties.
function Segm4k4Edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Segm4k4Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function Segm4k4Edit_Callback(hObject, eventdata, handles)
% hObject    handle to Segm4k4Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Segm4k4Edit as text
%        str2double(get(hObject,'String')) returns contents of Segm4k4Edit as a double


% --- Executes during object creation, after setting all properties.
function Segm4k5Edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Segm4k5Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function Segm4k5Edit_Callback(hObject, eventdata, handles)
% hObject    handle to Segm4k5Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Segm4k5Edit as text
%        str2double(get(hObject,'String')) returns contents of Segm4k5Edit as a double


% --- Executes during object creation, after setting all properties.
function Segm4k6Edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Segm4k6Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function Segm4k6Edit_Callback(hObject, eventdata, handles)
% hObject    handle to Segm4k6Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Segm4k6Edit as text
%        str2double(get(hObject,'String')) returns contents of Segm4k6Edit as a double


% --- Executes during object creation, after setting all properties.
function Segm4k7Edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Segm4k7Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function Segm4k7Edit_Callback(hObject, eventdata, handles)
% hObject    handle to Segm4k7Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Segm4k7Edit as text
%        str2double(get(hObject,'String')) returns contents of Segm4k7Edit as a double


% --- Executes during object creation, after setting all properties.
function edit37_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit37 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function edit37_Callback(hObject, eventdata, handles)
% hObject    handle to edit37 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit37 as text
%        str2double(get(hObject,'String')) returns contents of edit37 as a double


% --- Executes during object creation, after setting all properties.
function edit38_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit38 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function edit38_Callback(hObject, eventdata, handles)
% hObject    handle to edit38 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit38 as text
%        str2double(get(hObject,'String')) returns contents of edit38 as a double


% --- Executes during object creation, after setting all properties.
function edit39_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit39 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function edit39_Callback(hObject, eventdata, handles)
% hObject    handle to edit39 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit39 as text
%        str2double(get(hObject,'String')) returns contents of edit39 as a double


% --- Executes during object creation, after setting all properties.
function edit40_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit40 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function edit40_Callback(hObject, eventdata, handles)
% hObject    handle to edit40 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit40 as text
%        str2double(get(hObject,'String')) returns contents of edit40 as a double


% --- Executes during object creation, after setting all properties.
function edit41_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit41 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function edit41_Callback(hObject, eventdata, handles)
% hObject    handle to edit41 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit41 as text
%        str2double(get(hObject,'String')) returns contents of edit41 as a double


% --- Executes during object creation, after setting all properties.
function edit42_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit42 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function edit42_Callback(hObject, eventdata, handles)
% hObject    handle to edit42 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit42 as text
%        str2double(get(hObject,'String')) returns contents of edit42 as a double


% --- Executes during object creation, after setting all properties.
function edit43_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit43 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function edit43_Callback(hObject, eventdata, handles)
% hObject    handle to edit43 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit43 as text
%        str2double(get(hObject,'String')) returns contents of edit43 as a double


% --- Executes during object creation, after setting all properties.
function edit44_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit44 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function edit44_Callback(hObject, eventdata, handles)
% hObject    handle to edit44 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit44 as text
%        str2double(get(hObject,'String')) returns contents of edit44 as a double


% --- Executes during object creation, after setting all properties.
function edit45_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit45 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function edit45_Callback(hObject, eventdata, handles)
% hObject    handle to edit45 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit45 as text
%        str2double(get(hObject,'String')) returns contents of edit45 as a double


% --- Executes during object creation, after setting all properties.
function edit46_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit46 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function edit46_Callback(hObject, eventdata, handles)
% hObject    handle to edit46 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit46 as text
%        str2double(get(hObject,'String')) returns contents of edit46 as a double


% --- Executes during object creation, after setting all properties.
function edit47_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit47 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function edit47_Callback(hObject, eventdata, handles)
% hObject    handle to edit47 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit47 as text
%        str2double(get(hObject,'String')) returns contents of edit47 as a double


% --- Executes during object creation, after setting all properties.
function edit48_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit48 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function edit48_Callback(hObject, eventdata, handles)
% hObject    handle to edit48 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit48 as text
%        str2double(get(hObject,'String')) returns contents of edit48 as a double


% --- Executes during object creation, after setting all properties.
function edit49_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit49 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function edit49_Callback(hObject, eventdata, handles)
% hObject    handle to edit49 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit49 as text
%        str2double(get(hObject,'String')) returns contents of edit49 as a double


% --- Executes during object creation, after setting all properties.
function edit50_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit50 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function edit50_Callback(hObject, eventdata, handles)
% hObject    handle to edit50 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit50 as text
%        str2double(get(hObject,'String')) returns contents of edit50 as a double


% --- Executes during object creation, after setting all properties.
function edit51_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit51 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function edit51_Callback(hObject, eventdata, handles)
% hObject    handle to edit51 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit51 as text
%        str2double(get(hObject,'String')) returns contents of edit51 as a double


% --- Executes during object creation, after setting all properties.
function edit52_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit52 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function edit52_Callback(hObject, eventdata, handles)
% hObject    handle to edit52 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit52 as text
%        str2double(get(hObject,'String')) returns contents of edit52 as a double


% --- Executes during object creation, after setting all properties.
function edit53_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit53 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function edit53_Callback(hObject, eventdata, handles)
% hObject    handle to edit53 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit53 as text
%        str2double(get(hObject,'String')) returns contents of edit53 as a double


% --- Executes during object creation, after setting all properties.
function edit54_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit54 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function edit54_Callback(hObject, eventdata, handles)
% hObject    handle to edit54 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit54 as text
%        str2double(get(hObject,'String')) returns contents of edit54 as a double


% --- Executes during object creation, after setting all properties.
function edit55_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit55 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function edit55_Callback(hObject, eventdata, handles)
% hObject    handle to edit55 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit55 as text
%        str2double(get(hObject,'String')) returns contents of edit55 as a double


% --- Executes during object creation, after setting all properties.
function edit56_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit56 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function edit56_Callback(hObject, eventdata, handles)
% hObject    handle to edit56 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit56 as text
%        str2double(get(hObject,'String')) returns contents of edit56 as a double


% --- Executes during object creation, after setting all properties.
function edit57_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit57 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function edit57_Callback(hObject, eventdata, handles)
% hObject    handle to edit57 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit57 as text
%        str2double(get(hObject,'String')) returns contents of edit57 as a double


% --- Executes during object creation, after setting all properties.
function edit58_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit58 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function edit58_Callback(hObject, eventdata, handles)
% hObject    handle to edit58 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit58 as text
%        str2double(get(hObject,'String')) returns contents of edit58 as a double


% --- Executes during object creation, after setting all properties.
function edit59_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit59 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function edit59_Callback(hObject, eventdata, handles)
% hObject    handle to edit59 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit59 as text
%        str2double(get(hObject,'String')) returns contents of edit59 as a double


% --- Executes during object creation, after setting all properties.
function edit60_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit60 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function edit60_Callback(hObject, eventdata, handles)
% hObject    handle to edit60 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit60 as text
%        str2double(get(hObject,'String')) returns contents of edit60 as a double


% --- Executes during object creation, after setting all properties.
function edit61_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit61 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function edit61_Callback(hObject, eventdata, handles)
% hObject    handle to edit61 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit61 as text
%        str2double(get(hObject,'String')) returns contents of edit61 as a double


% --- Executes during object creation, after setting all properties.
function edit62_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit62 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function edit62_Callback(hObject, eventdata, handles)
% hObject    handle to edit62 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit62 as text
%        str2double(get(hObject,'String')) returns contents of edit62 as a double


% --- Executes during object creation, after setting all properties.
function edit63_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit63 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function edit63_Callback(hObject, eventdata, handles)
% hObject    handle to edit63 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit63 as text
%        str2double(get(hObject,'String')) returns contents of edit63 as a double


% --- Executes during object creation, after setting all properties.
function edit64_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit64 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function edit64_Callback(hObject, eventdata, handles)
% hObject    handle to edit64 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit64 as text
%        str2double(get(hObject,'String')) returns contents of edit64 as a double


% --- Executes during object creation, after setting all properties.
function Segm5K1Edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Segm5K1Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function Segm5K1Edit_Callback(hObject, eventdata, handles)
% hObject    handle to Segm5K1Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Segm5K1Edit as text
%        str2double(get(hObject,'String')) returns contents of Segm5K1Edit as a double


% --- Executes during object creation, after setting all properties.
function Segm5k2Edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Segm5k2Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function Segm5k2Edit_Callback(hObject, eventdata, handles)
% hObject    handle to Segm5k2Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Segm5k2Edit as text
%        str2double(get(hObject,'String')) returns contents of Segm5k2Edit as a double


% --- Executes during object creation, after setting all properties.
function Segm6k3Edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Segm6k3Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function Segm6k3Edit_Callback(hObject, eventdata, handles)
% hObject    handle to Segm6k3Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Segm6k3Edit as text
%        str2double(get(hObject,'String')) returns contents of Segm6k3Edit as a double


% --- Executes during object creation, after setting all properties.
function Segm5k4Edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Segm5k4Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function Segm5k4Edit_Callback(hObject, eventdata, handles)
% hObject    handle to Segm5k4Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Segm5k4Edit as text
%        str2double(get(hObject,'String')) returns contents of Segm5k4Edit as a double


% --- Executes during object creation, after setting all properties.
function edit69_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit69 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function edit69_Callback(hObject, eventdata, handles)
% hObject    handle to edit69 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit69 as text
%        str2double(get(hObject,'String')) returns contents of edit69 as a double


% --- Executes during object creation, after setting all properties.
function Segmk6Edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Segmk5Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function Segmk6Edit_Callback(hObject, eventdata, handles)
% hObject    handle to Segmk5Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Segmk5Edit as text
%        str2double(get(hObject,'String')) returns contents of Segmk5Edit as a double


% --- Executes during object creation, after setting all properties.
function Segm5k7Edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Segm5k7Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function Segm5k7Edit_Callback(hObject, eventdata, handles)
% hObject    handle to Segm5k7Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Segm5k7Edit as text
%        str2double(get(hObject,'String')) returns contents of Segm5k7Edit as a double


% --- Executes during object creation, after setting all properties.
function edit72_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit72 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function edit72_Callback(hObject, eventdata, handles)
% hObject    handle to edit72 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit72 as text
%        str2double(get(hObject,'String')) returns contents of edit72 as a double


% --- Executes during object creation, after setting all properties.
function Segm6k2Edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Segm6k2Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function Segm6k2Edit_Callback(hObject, eventdata, handles)
% hObject    handle to Segm6k2Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Segm6k2Edit as text
%        str2double(get(hObject,'String')) returns contents of Segm6k2Edit as a double


% --- Executes during object creation, after setting all properties.
function edit74_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit74 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function edit74_Callback(hObject, eventdata, handles)
% hObject    handle to edit74 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit74 as text
%        str2double(get(hObject,'String')) returns contents of edit74 as a double


% --- Executes during object creation, after setting all properties.
function Segm6k4Edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Segm6k4Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function Segm6k4Edit_Callback(hObject, eventdata, handles)
% hObject    handle to Segm6k4Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Segm6k4Edit as text
%        str2double(get(hObject,'String')) returns contents of Segm6k4Edit as a double


% --- Executes during object creation, after setting all properties.
function Segm6k5Edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Segm6k5Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function Segm6k5Edit_Callback(hObject, eventdata, handles)
% hObject    handle to Segm6k5Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Segm6k5Edit as text
%        str2double(get(hObject,'String')) returns contents of Segm6k5Edit as a double


% --- Executes during object creation, after setting all properties.
function Segm6k6Edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Segm6k6Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function Segm6k6Edit_Callback(hObject, eventdata, handles)
% hObject    handle to Segm6k6Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Segm6k6Edit as text
%        str2double(get(hObject,'String')) returns contents of Segm6k6Edit as a double


% --- Executes during object creation, after setting all properties.
function Segm6k7Edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Segm6k7Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function Segm6k7Edit_Callback(hObject, eventdata, handles)
% hObject    handle to Segm6k7Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Segm6k7Edit as text
%        str2double(get(hObject,'String')) returns contents of Segm6k7Edit as a double


% --- Executes during object creation, after setting all properties.
function Segm7K1Edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Segm7K1Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function Segm7K1Edit_Callback(hObject, eventdata, handles)
% hObject    handle to Segm7K1Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Segm7K1Edit as text
%        str2double(get(hObject,'String')) returns contents of Segm7K1Edit as a double


% --- Executes during object creation, after setting all properties.
function Segm7k2Edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Segm7k2Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function Segm7k2Edit_Callback(hObject, eventdata, handles)
% hObject    handle to Segm7k2Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Segm7k2Edit as text
%        str2double(get(hObject,'String')) returns contents of Segm7k2Edit as a double


% --- Executes during object creation, after setting all properties.
function Segm7k3Edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Segm7k3Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function Segm7k3Edit_Callback(hObject, eventdata, handles)
% hObject    handle to Segm7k3Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Segm7k3Edit as text
%        str2double(get(hObject,'String')) returns contents of Segm7k3Edit as a double


% --- Executes during object creation, after setting all properties.
function Segmk4Edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Segm7k4Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function Segmk4Edit_Callback(hObject, eventdata, handles)
% hObject    handle to Segm7k4Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Segm7k4Edit as text
%        str2double(get(hObject,'String')) returns contents of Segm7k4Edit as a double


% --- Executes during object creation, after setting all properties.
function Segm7k5Edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Segm7k5Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function Segm7k5Edit_Callback(hObject, eventdata, handles)
% hObject    handle to Segm7k5Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Segm7k5Edit as text
%        str2double(get(hObject,'String')) returns contents of Segm7k5Edit as a double


% --- Executes during object creation, after setting all properties.
function Segm7k6Edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Segm7k6Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function Segm7k6Edit_Callback(hObject, eventdata, handles)
% hObject    handle to Segm7k6Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Segm7k6Edit as text
%        str2double(get(hObject,'String')) returns contents of Segm7k6Edit as a double


% --- Executes during object creation, after setting all properties.
function Segm7k7Edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Segm7k7Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function Segm7k7Edit_Callback(hObject, eventdata, handles)
% hObject    handle to Segm7k7Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Segm7k7Edit as text
%        str2double(get(hObject,'String')) returns contents of Segm7k7Edit as a double


% --- Executes during object creation, after setting all properties.
function edit86_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit86 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function edit86_Callback(hObject, eventdata, handles)
% hObject    handle to edit86 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit86 as text
%        str2double(get(hObject,'String')) returns contents of edit86 as a double


% --- Executes during object creation, after setting all properties.
function Segm8k2Edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Segm8k2Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function Segm8k2Edit_Callback(hObject, eventdata, handles)
% hObject    handle to Segm8k2Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Segm8k2Edit as text
%        str2double(get(hObject,'String')) returns contents of Segm8k2Edit as a double


% --- Executes during object creation, after setting all properties.
function Segm8k3Edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Segm8k3Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function Segm8k3Edit_Callback(hObject, eventdata, handles)
% hObject    handle to Segm8k3Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Segm8k3Edit as text
%        str2double(get(hObject,'String')) returns contents of Segm8k3Edit as a double


% --- Executes during object creation, after setting all properties.
function Segm8k4Edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Segm8k4Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function Segm8k4Edit_Callback(hObject, eventdata, handles)
% hObject    handle to Segm8k4Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Segm8k4Edit as text
%        str2double(get(hObject,'String')) returns contents of Segm8k4Edit as a double


% --- Executes during object creation, after setting all properties.
function edit90_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit90 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function edit90_Callback(hObject, eventdata, handles)
% hObject    handle to edit90 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit90 as text
%        str2double(get(hObject,'String')) returns contents of edit90 as a double


% --- Executes during object creation, after setting all properties.
function Segm8k6Edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Segm8k6Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function Segm8k6Edit_Callback(hObject, eventdata, handles)
% hObject    handle to Segm8k6Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Segm8k6Edit as text
%        str2double(get(hObject,'String')) returns contents of Segm8k6Edit as a double


% --- Executes during object creation, after setting all properties.
function Segm8k7Edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Segm8k7Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function Segm8k7Edit_Callback(hObject, eventdata, handles)
% hObject    handle to Segm8k7Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Segm8k7Edit as text
%        str2double(get(hObject,'String')) returns contents of Segm8k7Edit as a double


% --- Executes during object creation, after setting all properties.
function Segm3K1Edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Segm3K1Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function Segm3K1Edit_Callback(hObject, eventdata, handles)
% hObject    handle to Segm3K1Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Segm3K1Edit as text
%        str2double(get(hObject,'String')) returns contents of Segm3K1Edit as a double


% --- Executes during object creation, after setting all properties.
function Segm4K1Edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Segm4K1Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function Segm4K1Edit_Callback(hObject, eventdata, handles)
% hObject    handle to Segm4K1Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Segm4K1Edit as text
%        str2double(get(hObject,'String')) returns contents of Segm4K1Edit as a double


% --- Executes during object creation, after setting all properties.
function Segm6K1Edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Segm6K1Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function Segm6K1Edit_Callback(hObject, eventdata, handles)
% hObject    handle to Segm6K1Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Segm6K1Edit as text
%        str2double(get(hObject,'String')) returns contents of Segm6K1Edit as a double


% --- Executes during object creation, after setting all properties.
function Segm8K1Edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Segm8K1Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function Segm8K1Edit_Callback(hObject, eventdata, handles)
% hObject    handle to Segm8K1Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Segm8K1Edit as text
%        str2double(get(hObject,'String')) returns contents of Segm8K1Edit as a double


% --- Executes during object creation, after setting all properties.
function Segm2k3Edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Segm2k3Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function Segm2k3Edit_Callback(hObject, eventdata, handles)
% hObject    handle to Segm2k3Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Segm2k3Edit as text
%        str2double(get(hObject,'String')) returns contents of Segm2k3Edit as a double


% --- Executes during object creation, after setting all properties.
function Segm5k3Edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Segm5k3Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function Segm5k3Edit_Callback(hObject, eventdata, handles)
% hObject    handle to Segm5k3Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Segm5k3Edit as text
%        str2double(get(hObject,'String')) returns contents of Segm5k3Edit as a double


% --- Executes during object creation, after setting all properties.
function Segm3k4Edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Segm3k4Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function Segm3k4Edit_Callback(hObject, eventdata, handles)
% hObject    handle to Segm3k4Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Segm3k4Edit as text
%        str2double(get(hObject,'String')) returns contents of Segm3k4Edit as a double


% --- Executes during object creation, after setting all properties.
function Segm7k4Edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Segm7k4Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function Segm7k4Edit_Callback(hObject, eventdata, handles)
% hObject    handle to Segm7k4Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Segm7k4Edit as text
%        str2double(get(hObject,'String')) returns contents of Segm7k4Edit as a double


% --- Executes during object creation, after setting all properties.
function Segm3k5Edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Segm3k5Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function Segm3k5Edit_Callback(hObject, eventdata, handles)
% hObject    handle to Segm3k5Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Segm3k5Edit as text
%        str2double(get(hObject,'String')) returns contents of Segm3k5Edit as a double


% --- Executes during object creation, after setting all properties.
function Segm5k5Edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Segm5k5Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function Segm5k5Edit_Callback(hObject, eventdata, handles)
% hObject    handle to Segm5k5Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Segm5k5Edit as text
%        str2double(get(hObject,'String')) returns contents of Segm5k5Edit as a double


% --- Executes during object creation, after setting all properties.
function Segm8k5Edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Segm8k5Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function Segm8k5Edit_Callback(hObject, eventdata, handles)
% hObject    handle to Segm8k5Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Segm8k5Edit as text
%        str2double(get(hObject,'String')) returns contents of Segm8k5Edit as a double


% --- Executes during object creation, after setting all properties.
function Segm3k6Edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Segm3k6Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function Segm3k6Edit_Callback(hObject, eventdata, handles)
% hObject    handle to Segm3k6Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Segm3k6Edit as text
%        str2double(get(hObject,'String')) returns contents of Segm3k6Edit as a double


% --- Executes on button press in ShowModelbutton.
function ShowModelbutton_Callback(hObject, eventdata, handles)
% hObject    handle to ShowModelbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
ViewModelImage = imread('ViewModel.png');
scrsz = get(0,'ScreenSize');
PlotLeft =  scrsz(3)/16; PlotBottom =  scrsz(4)/4;
PlotHeight = scrsz(4)*2/3;
PlotWidth = PlotHeight*1.5; 
figure('name','Kinetic Model Configuration','NumberTitle','off',...
    'position',[PlotLeft PlotBottom PlotWidth PlotHeight],'menubar','none');
image(ViewModelImage);axis off;


% --- Executes during object creation, after setting all properties.
function Segm1k1Edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Segm1k1Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function Segm1k1Edit_Callback(hObject, eventdata, handles)
% hObject    handle to Segm1k1Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Segm1k1Edit as text
%        str2double(get(hObject,'String')) returns contents of Segm1k1Edit as a double


% --- Executes during object creation, after setting all properties.
function Segm2k1Edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Segm2k1Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function Segm2k1Edit_Callback(hObject, eventdata, handles)
% hObject    handle to Segm2k1Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Segm2k1Edit as text
%        str2double(get(hObject,'String')) returns contents of Segm2k1Edit as a double


% --- Executes during object creation, after setting all properties.
function Segm3k1Edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Segm3k1Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function Segm3k1Edit_Callback(hObject, eventdata, handles)
% hObject    handle to Segm3k1Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Segm3k1Edit as text
%        str2double(get(hObject,'String')) returns contents of Segm3k1Edit as a double


% --- Executes during object creation, after setting all properties.
function Segm4k1Edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Segm4k1Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function Segm4k1Edit_Callback(hObject, eventdata, handles)
% hObject    handle to Segm4k1Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Segm4k1Edit as text
%        str2double(get(hObject,'String')) returns contents of Segm4k1Edit as a double


% --- Executes during object creation, after setting all properties.
function Segm5k1Edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Segm5k1Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function Segm5k1Edit_Callback(hObject, eventdata, handles)
% hObject    handle to Segm5k1Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Segm5k1Edit as text
%        str2double(get(hObject,'String')) returns contents of Segm5k1Edit as a double


% --- Executes during object creation, after setting all properties.
function Segm6k1Edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Segm6k1Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function Segm6k1Edit_Callback(hObject, eventdata, handles)
% hObject    handle to Segm6k1Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Segm6k1Edit as text
%        str2double(get(hObject,'String')) returns contents of Segm6k1Edit as a double


% --- Executes during object creation, after setting all properties.
function Segm7k1Edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Segm7k1Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function Segm7k1Edit_Callback(hObject, eventdata, handles)
% hObject    handle to Segm7k1Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Segm7k1Edit as text
%        str2double(get(hObject,'String')) returns contents of Segm7k1Edit as a double


% --- Executes during object creation, after setting all properties.
function Segm8k1Edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Segm8k1Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function Segm8k1Edit_Callback(hObject, eventdata, handles)
% hObject    handle to Segm8k1Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Segm8k1Edit as text
%        str2double(get(hObject,'String')) returns contents of Segm8k1Edit as a double


% --- Executes during object creation, after setting all properties.
function Segm1k7Edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Segm1k7Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function Segm1k7Edit_Callback(hObject, eventdata, handles)
% hObject    handle to Segm1k7Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Segm1k7Edit as text
%        str2double(get(hObject,'String')) returns contents of Segm1k7Edit as a double


% --- Executes during object creation, after setting all properties.
function Segm3k7Edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Segm3k7Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function Segm3k7Edit_Callback(hObject, eventdata, handles)
% hObject    handle to Segm3k7Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Segm3k7Edit as text
%        str2double(get(hObject,'String')) returns contents of Segm3k7Edit as a double


% --- Executes during object creation, after setting all properties.
function Segm5k6Edit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Segm5k6Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function Segm5k6Edit_Callback(hObject, eventdata, handles)
% hObject    handle to Segm5k6Edit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Segm5k6Edit as text
%        str2double(get(hObject,'String')) returns contents of Segm5k6Edit as a double


% --- Executes during object creation, after setting all properties.
function FrameStartTimeEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to FrameStartTimeEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end


function FrameStartTimeEdit_Callback(hObject, eventdata, handles)
% hObject    handle to FrameStartTimeEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of FrameStartTimeEdit as text
%        str2double(get(hObject,'String')) returns contents of FrameStartTimeEdit as a double
handles.FrameStartTime = str2double(get(handles.FrameStartTimeEdit,'String'));
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function FrameStopTimeEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to FrameStopTimeEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end


function FrameStopTimeEdit_Callback(hObject, eventdata, handles)
% hObject    handle to FrameStopTimeEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of FrameStopTimeEdit as text
%        str2double(get(hObject,'String')) returns contents of FrameStopTimeEdit as a double
handles.FrameStopTime = str2double(get(handles.FrameStopTimeEdit,'String'));
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function IsotopePopupmenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to IsotopePopupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end
set(hObject, 'String', {'C-11', 'F-18','O-15', 'N-13'});

% Update handles structure
guidata(hObject, handles);



% --- Executes on selection change in IsotopePopupmenu.
function IsotopePopupmenu_Callback(hObject, eventdata, handles)
% hObject    handle to IsotopePopupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns IsotopePopupmenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from IsotopePopupmenu
contents = get(hObject,'String');
SelectedIsotope = contents{get(hObject,'Value')};
switch SelectedIsotope
	case 'C-11'
        handles.T_half = 20.4;% [min]        
	case 'F-18'
        handles.T_half = 109.8;% [min]        
	case 'O-15'
        handles.T_half = 2.03; %122.24/60;% [min]        
	case 'N-13'
        handles.T_half = 9.97;% [min]        
end

% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in ShowTactCurvePushbutton.
function ShowTactCurvePushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to ShowTactCurvePushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


[handles,ok] = calcFrameTimesManual( hObject, handles);
if ~ok return; end;

main_gui_handles = guidata(handles.PetAnalSimulator_gui);
NumOfKinparameters = size(main_gui_handles.KineticConstant,2);
for i = 1 : NumOfKinparameters
	for j = 1 : main_gui_handles.NumOfSegments
        main_gui_handles.KineticConstant(j,i) = ...
            eval( ['str2double(get(handles.Segm',num2str(j),'k',num2str(i),'Edit,''String''))'] );
	end
end

% Update the handles for the main gui 
guidata(handles.PetAnalSimulator_gui,main_gui_handles); 
% Update current figures handles structure 
guidata(hObject, handles);

tissue_as = zeros(main_gui_handles.NumOfSegments,length(handles.frame_times));

%creating the fine blood_act_curve
dtime=max(handles.tissue_ts)/10000;	%~5sec
fine_ts=[0:dtime:max(handles.tissue_ts)];
blood_act_curve = bloodcurve(fine_ts, handles.bloodcurvepar);

figure('name','Defined Tact curves relating to the segments','NumberTitle','off');
plot( fine_ts, blood_act_curve,'k-');
xlabel('Frame times [min]');
ylabel('Activity concentration [nCi/ml]');

hold on;
for i = 1 : main_gui_handles.NumOfSegments
    tissue_as(i,:) = create_4CompTacs(main_gui_handles.KineticConstant(i,:), ...
        handles.tissue_ts, handles.bloodcurvepar );
%        .*(2.^(-handles.frame_times/handles.T_half));
    plot( handles.frame_times, tissue_as(i,:),'color',main_gui_handles.SegmentColor(i,:) );hold on;
end


% --- Executes on button press in SetupFrameTimesPushbutton.
function SetupFrameTimesPushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to SetupFrameTimesPushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

setFrameTimesManual( 0, 0, handles );
handles.frameTimeMode='manual';

% Update handles structure
guidata(hObject, handles);



% --- Executes on button press in SaveModelpushbutton.
function SaveModelpushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to SaveModelpushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% [handles,ok]=calcFrameTimesManual( hObject, handles);
% if ~ok 
% %if ~isfield(handles,'frame_times')
%     hm = msgbox('No frame times has been defined!','PETAnalSim Info' );
%     return;
% end
[handles,ok]=calcFrameTimesManual( hObject, handles);
guidata(hObject, handles);

main_gui_handles = guidata(handles.PetAnalSimulator_gui);
NumOfKinparameters = size(main_gui_handles.KineticConstant,2);
TracKinModel.KineticConstant = zeros(size(main_gui_handles.KineticConstant));

for i = 1 : NumOfKinparameters
	for j = 1 : main_gui_handles.NumOfSegments
        TracKinModel.KineticConstant(j,i) = ...
            eval( ['str2double(get(handles.Segm',num2str(j),'k',num2str(i),'Edit,''String''))'] );
	end
end
TracKinModel.bloodtype = handles.bloodtype;
%handles.bloodcurvepar = getPredefinedBloodCurve( handles );
TracKinModel.bloodcurvepar = handles.bloodcurvepar;
TracKinModel.T_half  = handles.T_half;
TracKinModel.FrameStartTime = handles.FrameStartTime;
TracKinModel.FrameStopTime = handles.FrameStopTime;
TracKinModel.frame_times = handles.frame_times;
TracKinModel.frame_lengths = handles.frame_lengths;
TracKinModel.tissue_ts = handles.tissue_ts;

TracKinModel.frameTimeMode=handles.frameTimeMode;
if strcmp(handles.frameTimeMode,'manual')
    TracKinModel.StepTime=str2num(get(handles.StepTimeEdit,'String'));
    TracKinModel.NumOfStep=str2num(get(handles.NumOfStepEdit,'String'));
else
    TracKinModel.frameTimesFileName=handles.frameTimeFileName;
end

if ( handles.bloodtype == -1 )
    TracKinModel.bloodCurveFileName = handles.BloodCurveFileName;
end;
    
%saving the model parameters 
[modelfilename, pathname] = uiputfile('*_TKinModel.mat', 'Save TK. model as');
if ~modelfilename;return;end
modelfilename = strrep( modelfilename, '_TKinModel.mat', '' );
save([pathname,modelfilename,'_TKinModel.mat'],'TracKinModel');

% --- Executes on button press in LoadModelpushbutton.
function LoadModelpushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to LoadModelpushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

[modelfilename, pathname] = uigetfile('**_TKinModel.mat', 'Load TK. model mat file');
if ~modelfilename; return; end

tmpstruct = load([pathname,modelfilename]);
% set up the model variables  
handles.bloodtype = tmpstruct.TracKinModel.bloodtype;
if isfield( tmpstruct.TracKinModel,'bloodCurve' ); % this will be obsolete
    handles.bloodcurvepar = tmpstruct.TracKinModel.bloodCurve;
end;
if isfield( tmpstruct.TracKinModel,'bloodCurvepar' );
    handles.bloodcurvepar = tmpstruct.TracKinModel.bloodcurvepar;
end;
handles.T_half = tmpstruct.TracKinModel.T_half;
handles.FrameStartTime = tmpstruct.TracKinModel.FrameStartTime;
handles.FrameStopTime = tmpstruct.TracKinModel.FrameStopTime;
handles.frame_times = tmpstruct.TracKinModel.frame_times;
handles.frame_lengths = tmpstruct.TracKinModel.frame_lengths;
handles.tissue_ts = tmpstruct.TracKinModel.tissue_ts;

% reads some GUI specific variable and display the new values in the GUI 
if isfield( tmpstruct.TracKinModel, 'frameTimeMode' )
    handles.frameTimeMode=tmpstruct.TracKinModel.frameTimeMode;
    if strcmp(handles.frameTimeMode,'manual')
       setFrameTimesManual( tmpstruct.TracKinModel.StepTime, tmpstruct.TracKinModel.NumOfStep, handles )
   else
       handles.frameTimeFileName=tmpstruct.TracKinModel.frameTimesFileName;
       setFrameTimeName( tmpstruct.TracKinModel.frameTimesFileName, handles );
   end;
else
      handles.frameTimeMode='manual';
      setFrameTimesManual( 0,0, handles );
end;

if ( handles.bloodtype == -1 && isfield( tmpstruct.TracKinModel,'bloodCurveFileName') )
    handles.BloodCurveFileName=tmpstruct.TracKinModel.bloodCurveFileName;
    set( handles.BloodCurveTypeEdit, 'string', handles.BloodCurveFileName );
else
    set(handles.BloodCurveTypeEdit,'String',handles.bloodtype);
end;

main_gui_handles = guidata(handles.PetAnalSimulator_gui);
NumOfKinparameters = size(main_gui_handles.KineticConstant,2);
for i = 1 : NumOfKinparameters
	for j = 1 : main_gui_handles.NumOfSegments
        eval( [' set(handles.Segm',num2str(j),'k',num2str(i), ...
                'Edit,''String'',tmpstruct.TracKinModel.KineticConstant(',num2str(j),',',num2str(i),') )'] );
	end
end

set(handles.FrameStartTimeEdit,'String',handles.FrameStartTime);
set(handles.FrameStopTimeEdit,'String',handles.FrameStopTime);

showIsotope( handles.T_half, handles );
set( handles.TrackinModelFileName, 'string', strrep( modelfilename, '_TKinModel.mat', ''  ));
handles.TrackinModelFile = strrep( modelfilename, '_TKinModel.mat', ''  );
% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in loadBloodCurve.
function loadBloodCurve_Callback(hObject, eventdata, handles)
% hObject    handle to loadBloodCurve (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if ~isfield(handles,'frame_times')
    hm = msgbox('No frame times has been defined!','PETAnalSim Info' );
    return;
end
[fname, path]=uigetfile('*.txt','Select blood curve file');
if ~fname return; end;
handles.bloodtype = -1;
handles.bloodcurvepar = loadBloodCurve([path fname]);
set( handles.BloodCurveTypeEdit, 'string', fname );
handles.BloodCurveFileName = [path fname];
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function StepTimeEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to StepTimeEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function StepTimeEdit_Callback(hObject, eventdata, handles)
% hObject    handle to StepTimeEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of StepTimeEdit as text
%        str2double(get(hObject,'String')) returns contents of StepTimeEdit as a double


% --- Executes during object creation, after setting all properties.
function NumOfStepEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to NumOfStepEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function NumOfStepEdit_Callback(hObject, eventdata, handles)
% hObject    handle to NumOfStepEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of NumOfStepEdit as text
%        str2double(get(hObject,'String')) returns contents of NumOfStepEdit as a double




% --- Executes on button press in LoadFrameTimesPushbutton.
function LoadFrameTimesPushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to LoadFrameTimesPushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[fname, path]=uigetfile('*.txt','Select framelengths file');
if ~fname return; end
frame_lengths = load([path fname],'-ASCII')';

tissue_ts(1)=0; 
for i=1:length(frame_lengths)
    tissue_ts(i+1) = tissue_ts(i)+frame_lengths(i);
end
frame_times = tissue_ts(1:end-1)+frame_lengths/2;
handles.frame_times = frame_times;
handles.frame_lengths = frame_lengths;
handles.tissue_ts = tissue_ts;
handles.frameTimeFileName=[path fname];
setFrameTimeName(fname, handles);
handles.frameTimeMode='file';

% Update handles structure
guidata(hObject, handles);


