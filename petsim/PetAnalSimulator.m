function varargout = PetAnalSimulator(varargin)
% PETANALSIMULATOR Application M-file for PetAnalSimulator.fig
%    FIG = PETANALSIMULATOR launch PetAnalSimulator GUI.
%    PETANALSIMULATOR('callback_name', ...) invoke the named callback.

% Last Modified by GUIDE v2.5 07-Oct-2004 11:10:54

% if nargin == 0  % LAUNCH GUI
% 
% 	fig = openfig(mfilename,'reuse');
% 
% 	% Use system color scheme for figure:
% 	set(fig,'Color',get(0,'defaultUicontrolBackgroundColor'));
% 
% 	% Generate a structure of handles to pass to callbacks, and store it. 
% 	handles = guihandles(fig);
% 	guidata(fig, handles);
% 
% 	if nargout > 0
% 		varargout{1} = fig;
% 	end
% 
% elseif ischar(varargin{1}) % INVOKE NAMED SUBFUNCTION OR CALLBACK
% 
% 	try
% 		if (nargout)
% 			[varargout{1:nargout}] = feval(varargin{:}); % FEVAL switchyard
% 		else
% 			feval(varargin{:}); % FEVAL switchyard
% 		end
% 	catch
% 		disp(lasterr);
% 	end
% 
% end

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @PetAnalSimulator_OpeningFcn, ...
                   'gui_OutputFcn',  @PetAnalSimulator_OutputFcn, ...
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

% --- Executes just before PetAnalSimulator is made visible.
function PetAnalSimulator_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to TracerModelSetUp (see VARARGIN)

% Choose default command line output for TracerModelSetUp
handles.output = hObject;

% setup defaults
handles.MaxNumOfSegments = 8;
handles.NumOfSegments = 8;
handles.SegmentColor(1,1:3) = [1 0.5 0.25];
handles.SegmentColor(2,1:3) = [0 0.5 1];
handles.SegmentColor(3,1:3) = [0 1 0.25];
handles.SegmentColor(4,1:3) = [1 0 0];
handles.SegmentColor(5,1:3) = [0.5 1 1];
handles.SegmentColor(6,1:3) = [0 0.5 0.25];
handles.SegmentColor(7,1:3) = [1 0.5 1];
handles.SegmentColor(8,1:3) = [1 1 0.5];
handles.KineticConstant = zeros(handles.MaxNumOfSegments,7);
handles.diam = 200; % the diameter of the ellipse for scatter correction
handles.existValidModel=false;

handles.cameraparfile=which( 'ge4096.def' );
set( handles.cameraDefFileName, 'string', 'ge4096.def' );


guidata(hObject, handles); 

% --- Outputs from this function are returned to the command line.
function varargout = PetAnalSimulator_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --------------------------------------------------------------------
function varargout = LoadMRIFile_Callback(hObject, eventdata, handles, varargin)

[FilesSelected, dir_path] = uiListFiles( 'Start', '*.img' );

if length(FilesSelected) == 0;
     return;
end
handles.FileNames = FilesSelected;
handles.dirname = dir_path;
guidata(handles.PetAnalSimulatorFigure,handles);
for i=1:length( FilesSelected )
  tmp(i)=cellstr([dir_path char(FilesSelected(i))]);
end
set(handles.InputFileNameEdit,'String', tmp(1) );

%
% View the segmented mri input
%

[SegmentedmriImg, mrihdr] = loadSegmentedMRI( FilesSelected, dir_path );
SegmentedmriImg3D = reshape(SegmentedmriImg,[mrihdr.dim(1) mrihdr.dim(2) mrihdr.dim(3)]);
for i = 1 : handles.MaxNumOfSegments
    SizeOfSegment = length(find( SegmentedmriImg3D == i));
    if SizeOfSegment == 0
        break;
    end
end
handles.NumOfSegments = i-1;

% update the GUI handle structure
guidata(hObject, handles); 

if handles.NumOfSegments == 0
    hm = msgbox(['There is no segment in the loaded volume.', ...
            'The segments should be labelled by consecutive integers from 1 to 8!'],'PETAnalSim Info' );
    handles.SegmentedmriImg = [];
    handles.mrihdr = [];
else
    handles.SegmentedmriImg = SegmentedmriImg;
    handles.mrihdr = mrihdr;
end
% update the GUI handle structure
guidata(hObject, handles); 

imaVOL = flipdim(permute(SegmentedmriImg3D,[2 1 3]),1);

FigDataIn = mia_Start3dCursor(imaVOL,[mrihdr.siz(1), mrihdr.siz(2) mrihdr.siz(3)], ...
    'colour8',0, handles.MaxNumOfSegments);


% FigDataIn = mia_Start3dCursor(imaVOL,[mrihdr.siz(1), mrihdr.siz(2) mrihdr.siz(3)], ...
%     'colour8',0, handles.MaxNumOfSegments);


% --------------------------------------------------------------------
function varargout = StartSimulationPushbutton_Callback(hObject, eventdata, handles, varargin)
if isempty(handles.mrihdr)
    hm = msgbox('No segmented MRI file was selected.','PETAnalSim Info' );
    return;
end

if (length( handles.cameraparfile ) ==0 )
      hm = msgbox(['The definition file not found.', ...
            'Please specify a caera definition file, or check the upper and lower cases of in the file name.'],'PETAnalSim Info' );
    return;
end;

if (~handles.existValidModel )
      hm = msgbox(['The tracer model is invalid.', ...
            'Please specify or load a tracer kinetic model.'],'PETAnalSim Info' );
    return;
end;

%%%%%%%%TMP
% 
% trv{1}='r05';
% trv{2}='r06';
% trv{3}='r07';
% trv{4}='r08';
% trv{5}='r09';
% trv{6}='r1';
% trv{7}='r11';
% trv{8}='r12';
% trv{9}='r13';
% trv{10}='r14';
% trv{11}='r15';
% blr(1)=0.5;
% blr(2)=0.6;
% blr(3)=0.7;
% blr(4)=0.8;
% blr(5)=0.9;
% blr(6)=1.0;
% blr(7)=1.1;
% blr(8)=1.2;
% blr(9)=1.3;
% blr(10)=1.4;
% blr(11)=1.5;
% 
% bloodcurvepar = handles.bloodcurvepar;
% 
% for files=1:1
% %for files=4:length( trv )
% 
% tratio=trv{files};
% bloodratio = blr(files);

   
disp(' ');
disp('Starting the PET image simulation.');
handles.SegmentedmriName = char(handles.FileNames);
handles.SegmentedmriPath = char(handles.dirname);
handles.outputfilename = get(handles.OtputFilenameEdit,'String');
%handles.outputfilename = [get(handles.OtputFilenameEdit,'String') '_' tratio] ;
handles.AttYes = get(handles.AttYesCheckbox,'Value');
handles.RandYes = get(handles.RandYesCheckbox,'Value');
handles.ScattYes = get(handles.ScattYesCheckbox,'Value');
handles.DecayYes = get(handles.DecayYesCheckbox,'Value');
handles.noise_fact = str2num(get(handles.NoiseLevelEdit,'String'));
handles.saveEachTimeFrames = get( handles.saveTimeFramesBox, 'Value' );

handles.SpatialResolutionYes = get( handles.PSFYesCheckbox, 'Value' );


% if handles.noise_fact > 10 | handles.noise_fact < 0
%     handles.noise_fact = 1;
%     set(handles.NoiseLevelEdit,'String','1');
% end
if handles.bloodtype > 9 | handles.bloodtype < -2
    handles.bloodtype = 7;
    set(handles.BloodCurveTypeEdit,'String','7');
end

handles.noise_fact = str2num(get(handles.NoiseLevelEdit,'String'));



% update the GUI handle structure
guidata(hObject, handles); 

petAnalSimMain(handles);


% --------------------------------------------------------------------
function varargout = InputFileNameEdit_Callback(h, eventdata, handles, varargin)
% --------------------------------------------------------------------
function varargout = LoadModelPushbutton_Callback(h, eventdata, handles, varargin)
% --------------------------------------------------------------------
function varargout = UsedPETTracerEdit_Callback(h, eventdata, handles, varargin)
% --------------------------------------------------------------------
function varargout = CBF_GMedit_Callback(h, eventdata, handles, varargin)
% --------------------------------------------------------------------
function varargout = CBF_WMedit_Callback(h, eventdata, handles, varargin)
% --------------------------------------------------------------------
function varargout = PC_GMedit_Callback(h, eventdata, handles, varargin)
% --------------------------------------------------------------------
function varargout = PC_WMedit_Callback(h, eventdata, handles, varargin)
% --------------------------------------------------------------------
function varargout = BloodCurveTypePushbutton_Callback(h, eventdata, handles, varargin)
show_predef_bloodcurves;

% --------------------------------------------------------------------
function varargout = BloodCurveTypeEdit_Callback(h, eventdata, handles, varargin)
% --------------------------------------------------------------------
function varargout = AttYesCheckbox_Callback(h, eventdata, handles, varargin)
% --------------------------------------------------------------------
function varargout = ScattYesCheckbox_Callback(h, eventdata, handles, varargin)
% --------------------------------------------------------------------
function varargout = RandYesCheckbox_Callback(h, eventdata, handles, varargin)
% --------------------------------------------------------------------
function varargout = NoiseLevelEdit_Callback(h, eventdata, handles, varargin)
% --------------------------------------------------------------------
function varargout = OtputFilenameEdit_Callback(h, eventdata, handles, varargin)
% --------------------------------------------------------------------
function varargout = ExitPushbutton_Callback(h, eventdata, handles, varargin)
delete(handles.PetAnalSimulatorFigure);



% --------------------------------------------------------------------
function varargout = LoadScannerParPushbutton_Callback(h, eventdata, handles, varargin)


% --- Executes during object creation, after setting all properties.
function listbox2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listbox2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end


% --- Executes on selection change in listbox2.
function listbox2_Callback(hObject, eventdata, handles)
% hObject    handle to listbox2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns listbox2 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listbox2


% --- Executes during object creation, after setting all properties.
function popupmenu2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end


% --- Executes on selection change in popupmenu2.
function popupmenu2_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns popupmenu2 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu2


% --- Executes during object creation, after setting all properties.
function edit10_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit10 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function edit10_Callback(hObject, eventdata, handles)
% hObject    handle to edit10 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit10 as text
%        str2double(get(hObject,'String')) returns contents of edit10 as a double


% --- Executes during object creation, after setting all properties.
function edit11_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit11 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function edit11_Callback(hObject, eventdata, handles)
% hObject    handle to edit11 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit11 as text
%        str2double(get(hObject,'String')) returns contents of edit11 as a double


% --- Executes on button press in TracerModelSetUp_pushbutton.
function TracerModelSetUp_pushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to TracerModelSetUp_pushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

 TracerModelSetUp(handles.PetAnalSimulatorFigure);

 
 


% --- Executes on button press in PSFYesCheckbox.
function PSFYesCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to PSFYesCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of PSFYesCheckbox


% --- Executes on button press in LoadCameraParFilepushbutton.
function LoadCameraParFilepushbutton_Callback(hObject, eventdata, handles)
% hObject    handle to LoadCameraParFilepushbutton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

[fname, path]=uigetfile('*.def');
if ~fname return; end
handles.cameraparfile=[path fname];
guidata(hObject, handles);
set( handles.cameraDefFileName, 'string', fname );



% --- Executes on button press in saveTimeFramesBox.
function saveTimeFramesBox_Callback(hObject, eventdata, handles)
% hObject    handle to saveTimeFramesBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of saveTimeFramesBox


% --- Executes on button press in CreateDefaultDefinition.
function CreateDefaultDefinition_Callback(hObject, eventdata, handles)
% hObject    handle to CreateDefaultDefinition (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

defaultdefinition=which( 'ge4096.def' );
if (length( defaultdefinition ) ==0 )
      hm = msgbox(['The default definition file ge4096.def not found.', ...
            'Please check location or the upper and lower cases of  the file.'],'PETAnalSim Info' );
    return;
end;

[fname,dir,filter]=uiputfile( '*.def' );
if  ~fname return; end
if length( strfind( fname,'.def' ) )==0
    fname =[fname '.def'];
end;
owndefinition=[dir fname];
copyfile ( defaultdefinition, owndefinition );
open( owndefinition );
handles.cameraparfile=owndefinition;
guidata(hObject, handles);
set( handles.cameraDefFileName, 'string', fname );


% --- Executes during object creation, after setting all properties.
function PreviewSliceNumber_CreateFcn(hObject, eventdata, handles)
% hObject    handle to PreviewSliceNumber (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc
    set(hObject,'BackgroundColor','white');
else
    set(hObject,'BackgroundColor',get(0,'defaultUicontrolBackgroundColor'));
end



function PreviewSliceNumber_Callback(hObject, eventdata, handles)
% hObject    handle to PreviewSliceNumber (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of PreviewSliceNumber as text
%        str2double(get(hObject,'String')) returns contents of PreviewSliceNumber as a double


% --- Executes on button press in PreviewSlice.
function PreviewSlice_Callback(hObject, eventdata, handles)
% hObject    handle to PreviewSlice (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if (~isfield( handles, 'mrihdr' ) || isempty(handles.mrihdr) )
    hm = msgbox('No segmented MRI file was selected.','PETAnalSim Info' );
    return;
end

if (length( handles.cameraparfile ) ==0 )
      hm = msgbox(['The definition file not found.', ...
            'Please specify a camera definition file, or check the upper and lower cases of in the file name.'],'PETAnalSim Info' );
    return;
end;

if (~handles.existValidModel )
      hm = msgbox(['The tracer model is invalid.', ...
            'Please specify or load a tracer kinetic model.'],'PETAnalSim Info' );
    return;
end;


slicenumber = str2num(get( handles.PreviewSliceNumber, 'String' ));

AttYes = get(handles.AttYesCheckbox,'Value');
RandYes = get(handles.RandYesCheckbox,'Value');
ScattYes = get(handles.ScattYesCheckbox,'Value');
DecayYes = get(handles.DecayYesCheckbox,'Value');
noise_fact = str2num(get(handles.NoiseLevelEdit,'String'));
SpatialResolutionYes = get( handles.PSFYesCheckbox, 'Value' );
diam = handles.diam;
camera=loadCameraParameters( handles.cameraparfile ); 
frameStartTime = handles.FrameStartTime;
frameStopTime = handles.FrameStopTime;

TracKinModel.MaxNumOfSegments = handles.MaxNumOfSegments;
TracKinModel.NumOfSegments =  handles.NumOfSegments; 
TracKinModel.T_half = handles.T_half;
TracKinModel.frame_times = handles.frame_times;
TracKinModel.frame_lengths = handles.frame_lengths;
TracKinModel.tissue_ts = handles.tissue_ts;
TracKinModel.tissue_as = handles.tissue_as;


TotpetSliceNumberForSim =fix(handles.mrihdr.dim(3)*handles.mrihdr.siz(3)/camera.axialPixelSize);

if ( slicenumber<1 || slicenumber > TotpetSliceNumberForSim )
    sn=num2str( TotpetSliceNumberForSim );
    msg=['Wrong slice number! The slice number should be between 1 and ' sn];
    msg=[msg ' (current simulated PET slices).'];
    hm = msgbox( msg,'Preview Error' );
    return;
end;


SegmentedResampledmriImg3D=CreateSegmentedResampledMRI( handles );

 [sumima, images] = Create_DynPetImage(noise_fact,SegmentedResampledmriImg3D(:,:,slicenumber),slicenumber, ...
            AttYes,ScattYes,diam, RandYes,DecayYes,SpatialResolutionYes, ...
            TracKinModel, camera, frameStartTime, frameStopTime, 1);
 sumima=flipud(sumima');      

 sumima = imresize(sumima,[handles.mrihdr.dim(1) handles.mrihdr.dim(2)] ,'bilinear');
figure;
imagesc( sumima );
colorbar; map=colormap('spectral'); 
   


% --- Executes on button press in DecayYesCheckbox.
function DecayYesCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to DecayYesCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of DecayYesCheckbox


