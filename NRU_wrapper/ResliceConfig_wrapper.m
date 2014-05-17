function project=ResliceConfig_wrapper(project,TaskIndex,MethodIndex,varargin)
% ResliceConfig_wrapper
%
% Temporaly UserConfig is saved in the 'UserData' field in the fig. sturcture of
%   the configurator window. On exit this is handled back to project w. updated settings
%
% Default if nt exist: 'sinc'
% userConfig fields:
%       .method: One of {'linear','nearest','sinc'}
%       .SincParms.SincSize:
%       .SincParms.SincFactor:
%       .resizeTo.ModalityIndex: Which modality should be used as target e.g. ->PET, ->MR
%       .resizeTo.fixedSize: All modalities to a given voxelsize
%
% Input:
%   project     : Structure containing all information of actual pipeline
%   TaskIndex   : Index to active task in the project structure
%   MethodIndex : Index to used method in a TaskIndex in the project structure
%   varargin{1} : When close GUI, 'h_Reslice=varargin{1}'
%
% Output:
%   project     : Return updated project       
%
% Uses special functions:
%   ReadAnalyzeHdr
%____________________________________________
%SW version: 300703TD, By T. Dyrby and M. Twadark, 300703, NRU

%____Init parameters 
global Output_xyz_names;
global InterpolationTag;
global InterpolationNames;
global offset
global noModalities;


%In PVeLav only use the 2 first modalities: PET and T1
noModalities=2;
modalityConvention={'PET','T1-W','T2-W','PD-W'};
Output_xyz_names={'x','y','z'};
InterpolationTag={'linear','nearest','sinc'};
InterpolationNames={'linear','nearest neighbour','sinc'};

offset=30;

%_____ Set default configuration if not exist
if(isempty(project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.default))           
    userConfig.method='linear';
    userConfig.SincParms.SincFac=[2 2 2];
    userConfig.SincParms.SincSize=[5 5 5];
    userConfig.resizeTo.ModalityIndex=[1];% Reslice to an image modality 'project.taskDone[TaskIndex].inputfiles.{ImageIndex,ModalityIndex}'
    userConfig.resizeTo.fixedSize=[3;3;3];% Reslice all to fixed voxel size
    project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.default=userConfig;       
end       

if(isempty(project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.user))    
    project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.user=project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.default;
end
userConfig=project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.user;

project_task=sprintf('get(findobj(''Tag'',''tag_Reslice''),''UserData'')');


%______ Reslice mainWindow
if(ishandle(findobj('tag','tag_Reslice')))    
    h_Reslice=findobj('tag','tag_Reslice');
else 
    h_Reslice=figure;
    figuresize=get(0,'ScreenSize');  %returns for example [1 1 1024 768]  
    %____define GUI values here
    color=[252/255 252/255 254/255]; %main window is [252/255 252/255 254/255], windows gray is [192/255 192/255 192/255]
    windowheight=310;  
    windowwidth=330;
    frame1_height=120; %upper frame
    frame2_height=120; %lower frame
    margen=10;
    set(h_Reslice,...
        'units','pixels',...
        'position',[figuresize(3)/2-windowwidth/2 figuresize(4)/2-windowheight/2 windowwidth windowheight],...
        'MenuBar','none',...
        'NumberTitle','off',...
        'Name',project.pipeline.taskSetup{TaskIndex,MethodIndex}.method,...
        'Color',color,...
        'NextPlot','add',...
        'tag','tag_Reslice',...
        'resize','off',...
        'CloserequestFcn',{@ExitresliceConfig_callback, project_task,TaskIndex,MethodIndex});  
    
    %___create frames and frame discription, calculate frame position
    frame1_size=[margen 50+frame2_height+margen windowwidth-2*margen frame1_height]; %do not edit size here [x y width height]
    frame2_size=[margen 50 windowwidth-2*margen frame2_height];                      %do not edit size here [x y width height]
    uicontrol('style','frame','units','pixels','position',[frame2_size],'BackgroundColor',color);  
    uicontrol('style','frame','units','pixels','position',[frame1_size],'BackgroundColor',color);   
    uicontrol('parent',h_Reslice,...
        'HorizontalAlignment','center',...
        'style','text',...
        'units','pixels',...
        'position',[30 50+frame2_height+margen+frame1_height-13 65 20],...
        'String','Resampling',...
        'tag','description',...
        'BackgroundColor',color);
    
    uicontrol('parent',h_Reslice,...
        'HorizontalAlignment','center',...
        'style','text',...
        'units','pixels',...
        'position',[30 50+frame2_height-13 65 20],...
        'String','Interpolation',...
        'tag','description',...
        'BackgroundColor',color);
end

%Store temporary project in h_Reslice
set(h_Reslice,'UserData',project);



%____ Buttons setup: Apply, Cancel and Load Defaults
%Apply button
uicontrol('parent',h_Reslice,...
    'HorizontalAlignment','left',...
    'style','pushbutton',...
    'units','pixels',...
    'position',[windowwidth-100 15 80 25],...
    'String','Apply',...
    'Callback',{@ExitresliceConfig_callback, project_task,TaskIndex,MethodIndex},...   
    'tag','tag_apply'...
    );

%Cancel button
uicontrol('parent',h_Reslice,...
    'HorizontalAlignment','left',...
    'style','pushbutton',...
    'units','pixels',...
    'position',[windowwidth-190 15 80 25],...
    'String','Cancel',...
    'Callback',{@ExitresliceConfig_callback, project_task,TaskIndex,MethodIndex},...  
    'tag','tag_cancel'...
    );  

%load defaults button
uicontrol('parent',h_Reslice,...
    'HorizontalAlignment','left',...
    'style','pushbutton',...
    'units','pixels',...
    'position',[20 15 80 25],...
    'String','Load defaults',...
    'Callback',{@ExitresliceConfig_callback, project_task,TaskIndex,MethodIndex},...
    'tag','tag_loaddefault'...  
    );   


%___________________ Setup Resampling field ________
%______ Resampling: Resize input to type: (1)->Fixed size or (2)->ModalityIndex
%Select type of resizeTo
if(~isempty(userConfig.resizeTo.ModalityIndex))
    %Resize type (2):ModalityIndex is selceted    
    FixedValue=0;
    FixedEnableDis='off';
    not_FixedEnableDis='on';
    SelectedModalityIndex=userConfig.resizeTo.ModalityIndex;
    Output_xyz_values=[0,0,0];
else
    %Resize type (1):FixedSize is selected
    FixedValue=1;
    FixedEnableDis='on';
    not_FixedEnableDis='off';
    SelectedModalityIndex=noModalities+1;
    Output_xyz_values=userConfig.resizeTo.fixedSize; % Load FixedSize from configrator
end


%______ Listbox for resize type (2) ModalityIndex: ->PET, ->MR through ModalityIndex
%Make list of available outputsformats/modalities
for(ModalityIndex=1:noModalities)        
    ModalityList{ModalityIndex}=['---> ',modalityConvention{ModalityIndex}];
end%for
ModalityList{end+1}=['---> ','Specify custom size'];

%explaining text 
uicontrol('parent',h_Reslice,...
        'HorizontalAlignment','left',...
        'style','text',...
        'units','pixels',...
        'position',[22 270 230 20],...
        'String','adjust output image voxel size',...
        'tag','description',...
        'BackgroundColor',color);


%Listbox Resampling: ->PET, ->MR through ModalityIndex
uicontrol('parent',h_Reslice,...
    'HorizontalAlignment','left',...
    'style','popupmenu',...
    'units','pixels',...
    'position',[22 245 140 25],...
    'String',ModalityList,...
    'tag','tag_ModalityIndex',... 
    'Value',SelectedModalityIndex,...
    'Visible','on',... 
    'Callback',{@fixedSize_Callback,TaskIndex,MethodIndex,h_Reslice});   


% Textbox where voxelsize is shown [x,y,z]
for(i=1:3)
    uicontrol('parent',h_Reslice,...
        'HorizontalAlignment','left',...
        'style','text',...
        'units','pixels',...
        'position',[175 290-offset*i 50 20],...        
        'string',Output_xyz_names{i},...
        'tag',['tag_Fixedtext_',Output_xyz_names{i}],...
        'BackgroundColor',color,...
        'Visible',FixedEnableDis);    
    
    uicontrol('parent',h_Reslice,...
        'HorizontalAlignment','left',...
        'style','edit',...
        'units','pixels',...
        'position',[185 290-offset*i 50 20],...
        'String',Output_xyz_values(i),...
        'tag',['tag_fixed_',Output_xyz_names{i}],...        
        'Visible',FixedEnableDis);   
end %for

% picture of brain and axis orientation
brainaxes=imread('XYZ_brain.bmp');
uicontrol('parent',h_Reslice,...
    'style','pushbutton',...
    'units','pixels',...
    'position',[248 201 58 80],...
    'tag','tag_brainaxes',...
    'cdata',brainaxes,...
    'enable','inactive',...
    'Visible',FixedEnableDis,...
    'BackgroundColor',[192/255 192/255 192/255]);  

% text reminding voxel units
uicontrol('parent',h_Reslice,...
        'HorizontalAlignment','left',...
        'style','text',...
        'units','pixels',...
        'position',[198 184 110 14],...        
        'string','voxel units are mm',...
        'tag','tag_unittext',...
        'BackgroundColor',color,...
        'Visible',FixedEnableDis);    

%___________________ Setup Interpolation field ________

%_____Type of Interpolation (1)Linear, (2) Nearest, (3)Billinear, (4)Sinc
%If method=Reslice: Sinc do not work!
for(i=1:length(InterpolationNames))
    
    if(strcmp(userConfig.method,InterpolationTag{i}))
        EnableDisable=1;
    else
        EnableDisable=0;
    end
    
    uicontrol('parent',h_Reslice,...
        'HorizontalAlignment','left',...
        'style','radiobutton',...
        'units','pixels',...
        'position',[25 154-offset*i 120 25],...
        'String',InterpolationNames{i},...
        'tag',['tag_',InterpolationTag{i}],...
        'Value',EnableDisable,...
        'Callback',{@MutalRadiobuttons_callback},...
        'Visible','on',...
        'BackgroundColor',color);   
end%for


%Only for sinc interpolation
if(strcmp(userConfig.method,InterpolationTag{3}))
    SincEnableDis='on';
else
    SincEnableDis='off';
end
    
for(i=1:3)
    uicontrol('parent',h_Reslice,...
        'HorizontalAlignment','left',...
        'style','text',...
        'units','pixels',...
        'position',[175 154-offset*i 120 20],...
        'string',Output_xyz_names{i},...
        'tag','text_sinc',...
        'BackgroundColor',color,...
        'Visible',SincEnableDis); 
    
    % .SincParms.SincSize:
    uicontrol('parent',h_Reslice,...
        'HorizontalAlignment','left',...
        'style','edit',...
        'units','pixels',...
        'position',[185 154-offset*i 50 20],...
        'String',num2str(userConfig.SincParms.SincSize(i)),...
        'tag',['tag_SincSize_',Output_xyz_names{i}],...        
        'Visible',SincEnableDis,...
        'Enable','on');   

    % .SincParms.SincFac:
     uicontrol('parent',h_Reslice,...
        'HorizontalAlignment','left',...
        'style','edit',...
        'units','pixels',...
        'position',[205+50 154-offset*i 50 20],...
        'String',num2str(userConfig.SincParms.SincFac(i)),...
        'tag',['tag_SincFactor_',Output_xyz_names{i}],...        
        'Visible',SincEnableDis,...
        'Enable','on');   
end %for

%___text for sinc factor and size
uicontrol('parent',h_Reslice,...
    'HorizontalAlignment','center',...
    'style','text',...
    'units','pixels',...
    'position',[185 148 50 16],...        
    'string','size',...
    'tag','tag_SincText',...
    'BackgroundColor',color,...
    'Visible',SincEnableDis);    
uicontrol('parent',h_Reslice,...
    'HorizontalAlignment','center',...
    'style','text',...
    'units','pixels',...
    'position',[205+50 148 50 16],...        
    'string','factor',...
    'tag','tag_SincText',...
    'BackgroundColor',color,...
    'Visible',SincEnableDis);    
    
    
%_____Wait for UIRESUME when user press 'ok', 'cancel' or 'default'
uiwait(h_Reslice)

%____ Get updatede project temporaly stored in the configurator fig
project=get(h_Reslice,'UserData');

delete(h_Reslice)

drawnow


function fixedSize_Callback(h,eventdata,TaskIndex,MethodIndex,h_Reslice)
% If Fixedsized is selcted or an Imagemodality Index
%
% Uses special functions:
%____________________________________________
% M. Twadark and T. Dyrby, 0310703, NRU
%SW version: 310703TD

global Output_xyz_names;
global InterpolationTag;
global InterpolationNames;
global noModalities;

%______ Resampling: Resize input to type: (1)->Fixed size or (2)->ModalityIndex
%Select type of resizeTo

%Load configuration
project=get(h_Reslice,'UserData');
userConfig=project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.user;
if(get(findobj('tag','tag_ModalityIndex'),'Value')>noModalities)  %tag_ModalityIndex   tag_fixedsize'
    %Resize type (3):ModalityIndex is selceted    
    FixedValue=3;
    FixedEnableDis='off';
    not_FixedEnableDis='on';
    if(isempty(userConfig.resizeTo.ModalityIndex))
        userConfig.resizeTo.ModalityIndex=1;
    end
    SelectedModalityIndex=userConfig.resizeTo.ModalityIndex;
    Output_xyz_values=[0,0,0];
else
    %Resize type (1):FixedSize is selected
    FixedValue=1;
    FixedEnableDis='on';
    not_FixedEnableDis='off';
    SelectedModalityIndex=1;
    Output_xyz_values=userConfig.resizeTo.fixedSize; % Load FixedSize from configrator
end


set(findobj('tag','tag_Fixedtext'),...
    'Visible',not_FixedEnableDis);

% Textbox where voxelsize is shown [x,y,z]
for(i=1:3)
    set(findobj('tag',['tag_Fixedtext_',Output_xyz_names{i}]),...
        'string',Output_xyz_names{i},...
        'Visible',not_FixedEnableDis);    
    
    set(findobj('tag',['tag_fixed_',Output_xyz_names{i}]),...
        'Visible',not_FixedEnableDis);   
end

% Picture of brain explaining XYZ axis orientation
set(findobj('tag','tag_brainaxes'),...
        'Visible',not_FixedEnableDis);   

    % text reminding voxel units
set(findobj('tag','tag_unittext'),...
        'Visible',not_FixedEnableDis);     
     

function MutalRadiobuttons_callback(h,eventdata)
% Mutal activation of radio buttons 
%
% Uses special functions:
%____________________________________________
% M. Twadark and T. Dyrby, 0310703, NRU
%SW version: 310703TD
global Output_xyz_names;
global InterpolationTag;
global InterpolationNames;

for(i=1:length(InterpolationTag))
    if(strcmp(get(h,'tag'),['tag_',InterpolationTag{i}]))
        continue
    end
    set(findobj('tag',['tag_',InterpolationTag{i}]),'Value',0);
end%for

%Below only for Sinc interpolation
if(strcmp(get(h,'tag'),['tag_',InterpolationTag{3}]))
    SincEnableDis='on';
else
    SincEnableDis='off';
end
    
for(i=1:3)
    % .Text
    set(findobj('tag','text_sinc'),...
        'Visible',SincEnableDis); 
    
    % .SincParms.SincSize:
    set(findobj('tag',['tag_SincSize_',Output_xyz_names{i}]),...
        'Visible',SincEnableDis); 
    
    % .SincParms.SincFac:
    set(findobj('tag',['tag_SincFactor_',Output_xyz_names{i}]),...
        'Visible',SincEnableDis);     
end %for

% .sinc text 
set(findobj('tag','tag_SincText'),...
        'Visible',SincEnableDis); 


function project=ExitresliceConfig_callback(h,eventdata,project_task,TaskIndex,MethodIndex,varargin)
%
% Save new settings and exit configurator
%
% Uses special functions:
%____________________________________________
% M. Twadark and T. Dyrby, 0310703, NRU
%SW version: 310703TD
global Output_xyz_names;
global InterpolationTag;
global InterpolationNames;
global noModalities;

project=eval(project_task);

h_Reslice=findobj('tag','tag_Reslice');

%___ Button pressed leave configurator
switch(lower(get(h,'tag')))
    
%_____ Apply settings
case 'tag_apply'
    
    %______ Updates configurator settings
    %Get resampling settings
    if(get(findobj('tag','tag_ModalityIndex'),'Value')>noModalities)
        %Fixedsize are selected
        for(i=1:3)     
            FixedSize=get(findobj('tag',['tag_fixed_',Output_xyz_names{i}]),'string');

            if(FixedSize==0)
                project=logProject('Fixed Size parameters: >0 !!!',project,TaskIndex,MethodIndex);
                return
            end
            
            if(sum(isletter(FixedSize)))
                project=logProject('FixedSize parameters must be NUMERIC!!!',project,TaskIndex,MethodIndex);
                return
            end
            userConfig.resizeTo.fixedSize(i)=str2num(FixedSize);
        end
        userConfig.resizeTo.ModalityIndex=[];   
        
    else%ModalityIndex are selected
        userConfig.resizeTo.ModalityIndex=get(findobj('tag','tag_ModalityIndex'),'Value');   
        userConfig.resizeTo.fixedSize=[];       
    end    
    
    %_____ Get interpolation settings
    for(i=1:length(InterpolationTag))
        %Find selected method
        if(get(findobj('tag',(['tag_',InterpolationTag{i}])),'Value')==1)
            userConfig.method=InterpolationTag{i};        
            break
        end
    end%for
    
    %If sinc interpolation. read SincFactor and SincSize    
    for(i=1:3)
        % .SincParms.SincSize:
        SincSize=get(findobj('tag',['tag_SincSize_',Output_xyz_names{i}]),'String');     
        
        % .SincParms.SincFac:
        SincFac=get(findobj('tag',['tag_SincFactor_',Output_xyz_names{i}]),'String');     
        
        if((SincSize)==0 | SincFac==0)
            project=logProject('Sinc parameters: >0 !!!',project,TaskIndex,MethodIndex);
            return
        end
        if(sum(isletter(SincSize)) | sum(isletter(SincFac)))
            project=logProject('Sinc parameters must be NUMERIC!!!',project,TaskIndex,MethodIndex);
            return
        end
        userConfig.SincParms.SincSize(i)=str2num(SincSize);
        userConfig.SincParms.SincFac(i)=str2num(SincFac);
        
    end     
  
    
    project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.user=userConfig;
    
%______ Load defaults    
case 'tag_loaddefault'
    userConfig=project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.default;
    %Only update when 'APPLY' is pressed!!
   % project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.user=userConfig;
    
    %Update project in Config fig
    set(h_Reslice,'userdata',project);
    
    if(~isempty(userConfig.resizeTo.ModalityIndex))        
        % If modality index
        set(findobj('tag','tag_ModalityIndex'),'Value',userConfig.resizeTo.ModalityIndex);   
    else
        %If fixedsize
        set(findobj('tag','tag_ModalityIndex'),'Value',noModalities+1);   
         for(i=1:3)     
             set(findobj('tag',['tag_fixed_',Output_xyz_names{i}]),'string',(userConfig.resizeTo.fixedSize(i)));   
         end            
    end
    
    fixedSize_Callback([],[],TaskIndex,MethodIndex,h_Reslice)
    
   %_____ Set interpolation settings
    for(i=1:length(InterpolationTag))
        %Find selected method
        if(strcmp(InterpolationTag{i},userConfig.method))
            set(findobj('tag',(['tag_',InterpolationTag{i}])),'Value',i);
            break
        end
    end%
        
    for(i=1:3)
      % .SincParms.SincSize:
        set(findobj('tag',['tag_SincSize_',Output_xyz_names{i}]),'String',num2str(userConfig.SincParms.SincSize(i)));     
        
        % .SincParms.SincFac:
        set(findobj('tag',['tag_SincFactor_',Output_xyz_names{i}]),'String',num2str(userConfig.SincParms.SincFac(i)));     
    end
        
    fixedSize_Callback([],[],TaskIndex,MethodIndex,h_Reslice)
    
    %Interpolation method?
    for(i=1:length(InterpolationTag))
        %Find selected method
        if(strcmp(userConfig.method,InterpolationNames{i}))
            set(findobj('tag',['tag_',InterpolationTag{i}]),'value',1);
            MutalRadiobuttons_callback(findobj('tag',['tag_',InterpolationTag{i}]),[]);                  
            break
        end
    end
    return% Defaults to configurator
    
    
%_____ Cancel    
otherwise %tag_cancel and close windows
    %Do not change settings
end%switch


%___ Save updated project in configurator 
h_Reslice=findobj('tag','tag_Reslice');
set(h_Reslice,'UserData',project);

%___ Resume uiwait 
uiresume(h_Reslice)