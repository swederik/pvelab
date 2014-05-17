function project=spmCoregConfig_wrapper(project,TaskIndex,MethodIndex,varargin)
%
%
% Temporaly UserConfig is saved in the 'UserData' field in the fig. sturcture of
%   the configurator window. On exit this is handled back to project w. updated settings
%
% Input:
%   project     : Structure containing all information of actual pipeline
%   TaskIndex   : Index to active task in the project structure
%   MethodIndex : Index to used method in a TaskIndex in the project structure
%
% Output:
%   project     : Return updated project, with new data under ...configurator.user
%____________________________________________
% T. Rask 271003, NRU
% Modified for SPM(: 20120117CS

%________________Check if configurator figure exists ___________________
%(checkIn_wrapper should prevent this)

if ishandle(findobj('tag','tag_optionsFig'))
    msgbox('SPM Coreg config is already running');
    return;
end

%_______________________Check if spm2 exists______________________________

switch exist('spm','file')
    case 0
        msg='ERROR: Can not find SPM. Addpath or download at www.fil.ion.ucl.ac.uk/spm.';
        project=logProject(msg,project,TaskIndex,MethodIndex);
        project.taskDone{TaskIndex}.error{end+1}=msg;
        return;
    case 2
        [v,c]=spm('Ver');
        if(strcmpi(v,'spm2'))
            project=logProject('SpmCoregConfig_wrapper: SPM2 found. Coregistration progress is shown in SPM-windows.',project,TaskIndex,MethodIndex);
            SPM_ver=2;
        elseif(strcmpi(v,'spm5'))
            project=logProject('SpmCoregConfig_wrapper: SPM5 found. Coregistration progress is shown in SPM-windows.',project,TaskIndex,MethodIndex);
            SPM_ver=5;
        elseif(strcmpi(v,'spm8'))
            project=logProject('SpmCoregConfig_wrapper: SPM8 found. Coregistration progress is shown in SPM-windows.',project,TaskIndex,MethodIndex);
            SPM_ver=8;
        else
            msg='ERROR: Wrong SPM version, SPM2/5/8 required. Download SPM at www.fil.ion.ucl.ac.uk/spm.';
            project=logProject(msg,project,TaskIndex,MethodIndex);
            project.taskDone{TaskIndex}.error{end+1}=msg;
            return;
        end
    otherwise
        msg='ERROR: SPM not recognized as .m-file.';
        project=logProject(msg,project,TaskIndex,MethodIndex);
        project.taskDone{TaskIndex}.error{end+1}=msg;
        return;
end

%____________________________Load settings________________________________

if (SPM_ver==2)
    %Check if default value is given. If not set value from spm_defaults.m
    if(isempty(project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.default))
        
        %get spm default values from spm_defaults.m
        global defaults
        spm_defaults;
        
        %Defaults settings exist?
        userConfig=defaults.coreg;
        userConfig.to=1;
        userConfig.flipAnalyze=defaults.analyze.flip;
        
        feval('clear','global','defaults'); %Remove global spm defaults tree
        
        project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.default=userConfig;
    end
    
    %_________ Check if all parameters are defined
    userConfig=project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.default;
    if ~isfield(userConfig,'to')
        userConfig.to=1;
    end
    if ~isfield(userConfig,'flipAnalyze')
        userConfig.flipAnalyze=1;
    end
    if ~isfield(userConfig,'estimate')
        userConfig.estimate=[];
    end
    if ~isfield(userConfig,'write')
        userConfig.write=[];
    end
    if ~isfield(userConfig.write,'interp')
        userConfig.write.interp=1;
    end
    if ~isfield(userConfig.write,'wrap')
        userConfig.write.wrap=[0 0 0];
    end
    if ~isfield(userConfig.write,'mask')
        userConfig.write.mask=0;
    end
    if ~isfield(userConfig.estimate,'cost_fun')
        userConfig.estimate.cost_fun='nmi';
    end
    if ~isfield(userConfig.estimate,'sep')
        userConfig.estimate.sep=[4 2];
    end
    if ~isfield(userConfig.estimate,'tol')
        userConfig.estimate.tol=[0.02 0.02 0.02 0.001 0.001 0.001 0.01 0.01 0.01 0.001 0.001 0.001];
    end
    if ~isfield(userConfig.estimate,'fwhm')
        userConfig.estimate.fwhm=[7 7];
    end
    
    project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.default=userConfig;
    %_____________________________________________
    
    % User defined setting exist?
    if(isempty(project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.user))
        %User settings does not exist in project, use default
        project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.user=userConfig;
    else
        %User settings do exist
        userConfig=project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.user;
    end;
    
    %____________________________Handle GUI____________________________________
    
    %____ Setup and start user-interface of the Configurator
    h_coregconfig=figure('CreateFcn',{@MakeFigure_CreateFcn, project,TaskIndex,MethodIndex,varargin},'Tag','tag_optionsFig');
    
    %Store temporary project in h_coregconfig
    set(h_coregconfig,'UserData',project);
    
    %_____Wait for UIRESUME, continues when user presses 'ok'
    uiwait(h_coregconfig);
    
    %____ Get updatede project temporaly stored in the configurator fig
    project=get(h_coregconfig,'UserData');
    
    %____ Shut down the configurator user-interface
    delete(h_coregconfig);
    
elseif (SPM_ver==5)||(SPM_ver==8)  % Found out that spm5 can be handled as spm8 (therefore a bit confusing in the next part)
    
    if(isempty(project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.default))
        % No user settings have been selected, use defaults set by spm_defaults
	if (SPM_ver==5)
            global defaults;
            spm_defaults;
            % def=spm('defaults','pet');         %setup defaults-tree
            def=defaults;
            tmp.estimate.eoptions=def.coreg.estimate;
        else
            def=spm('defaults','pet');         %setup defaults-tree
            tmp.estimate.eoptions=def.coreg.estimate;
        end
        tmp.to=2; %Always to MR as spm8 coreg to PET does not work

        project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.default=tmp;
        
        %loginfo
        msg='SpmCoregConfig_wrapper: Using SPM5/8 default settings defined in spm(defaults,pet)';
    end
    
    userConfig=project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.default;
    
    %Set user configuration to default if it does not exist
    if(isempty(project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.user))
        %'Default' exist in project: load into 'user' as a default value
        project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.user=userConfig;
        %loginfo
        %project=logproject(('Config: Default value is loaded in user'),project,TaskIndex,MethodIndex);
    end

    %____ Setup and start user-interface of the Example Configurator
    h_coregconfig=figure('CreateFcn',{@MakeFigureSpm8_CreateFcn, project,TaskIndex,MethodIndex,varargin},'Tag','tag_optionsFig');
    
    %Store temporary project in h_Reslice
    set(h_coregconfig,'UserData',project);
    
    %_____Wait for UIRESUME, continues when user presses 'ok'
    uiwait(h_coregconfig)
    
    %____ Get updatede project temporaly stored in the configurator fig
    project=get(h_coregconfig,'UserData');
    
    %____ Shout down the configurator user-interface
    delete(h_coregconfig)

else
    msg='Error: SPM version not recognizable.';
    project=logProject(msg,project,TaskIndex,MethodIndex);
    project.taskDone{TaskIndex}.error{end+1}=msg;
    return;
    
end

%____ Flush graphics to screen
drawnow

%________________________________________________________________________
%_____________________________Functions__________________________________

function MakeFigure_CreateFcn(h_coregconfig, eventdata, project, TaskIndex, MethodIndex, varargin)  %(h,eventdata,project_task,TaskIndex,MethodIndex,varargin)
%
% Create figure and UI controls
%____________________________________________
% T. Rask 271003, NRU

%_____ Get size of mainGUI (the userinterface of the pipeline)
figuresize=get(0,'ScreenSize');

%____Setup the user-interface
%Size of configurator GUI
color=[252/255 252/255 254/255];
windowheight=540;
windowwidth=295;
margen=10;
frame_size=[margen 50 windowwidth-2*margen windowheight-50-margen];                      %do not edit size here [x y width height]

%Setup configurator user-interface w. 'user' value
userConfig=project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.user;

%Specify fields array for creation of popup menu's.
% field   : is current value of field
% possible: shows what values field can hold
% strings : are the discription of all possible fields (this is shown inside the popupmenu)
% text    : is the hint string displayed just above the popupmenu.
%Coregister to:
field{1}   = userConfig.to;
possible{1}= {1 2};
strings{1} = {'PET','MR T1-Weighted'};
text{1}    = 'Coregister to:';
%Cost function
field{2}   = userConfig.estimate.cost_fun;
possible{2}= {'mi' 'ecc' 'nmi' 'ncc'};
strings{2} = {'Mutual Information','Entropy Correlation Coefficient','Normalised Mutual Information','Normalised Cross Correlation'};
text{2}    = 'Cost function:';
%Number of runs
field{3}   = length(userConfig.estimate.sep);
possible{3}= {1 2 3};
strings{3} = {'1','2','3'};
text{3}    = 'Number of runs?';


%setup configurator GUI figure with information given in project
set(h_coregconfig,...
    'units','pixels',...
    'position',[figuresize(3)/2-windowwidth/2 figuresize(4)/2-windowheight/2 windowwidth windowheight],...
    'MenuBar','none',...
    'NumberTitle','off',...
    'Name',project.pipeline.taskSetup{TaskIndex,MethodIndex}.method,...
    'Color',color,...
    'NextPlot','add',...
    'tag','tag_optionsFig',...
    'resize','off',...
    'CloserequestFcn',{@ExitConfig_callback,TaskIndex,MethodIndex,possible,field});

%Create neat black inner frame
uicontrol('style','frame','units','pixels','position',[frame_size],'BackgroundColor',color);

%create popup menu's containing the data just specified in array
for n=1:3
    %__find selected value among possible values (even if it is string or number)
    for m=1:length(possible{n})
        if ischar(field{n})
            if strcmp(field{n},possible{n}{m});
                value{n}=m;
                break
            end
        else
            if field{n}==possible{n}{m}
                value{n}=m;
                break;
            end
        end
    end
    uicontrol('parent',h_coregconfig,...
        'HorizontalAlignment','left',...
        'style','text',...
        'units','pixels',...
        'position',[30 windowheight-45*n 200 20],...
        'String',text{n},...
        'tag',['hinttext_' num2str(n)],...
        'BackgroundColor',color);
    uicontrol('parent',h_coregconfig,...
        'style','popupmenu',...
        'value',value{n},...
        'HorizontalAlignment','left',...
        'units','pixels',...
        'position',[30 windowheight-20-45*n 200 25],...
        'String',strings{n},...
        'Callback',[],...
        'tag',['tag_popup_' num2str(n)]);
end
set(findobj('tag','tag_popup_3'),'Callback',{@nRuns_Callback}); %number of textboxes need to change immediately
runs=get(findobj('tag','tag_popup_3'),'value');

%_________________________Sample point Distance___________________________

uicontrol('parent',h_coregconfig,...
    'HorizontalAlignment','left',...
    'style','text',...
    'units','pixels',...
    'position',[30 windowheight-45*4-5 200 20],...
    'String','Sample point distance [mm]:',...
    'tag',['hinttext_6'],...
    'BackgroundColor',color);

runText={'1st run','2nd run','3rd run'};

for i=1:3
    if (i<=runs), vis='on'; else vis='off'; end;
    uicontrol('parent',h_coregconfig,...
        'HorizontalAlignment','left',...
        'style','text',...
        'units','pixels',...
        'position',[30+(i-1)*90 windowheight-25-45*4 60 20],...
        'string',runText{i},...
        'tag',['tag_DistText_',num2str(i)],...
        'BackgroundColor',color,...
        'Visible',vis);
    
    
    uicontrol('parent',h_coregconfig,...
        'HorizontalAlignment','left',...
        'style','edit',...
        'units','pixels',...
        'position',[30+(i-1)*90 windowheight-40-45*4 50 20],...
        'String','',...
        'tag',['tag_DistEditbox_' num2str(i)],...
        'Visible',vis);
    
    if (i<=runs) %set values of editfields
        set(findobj('tag',['tag_DistEditbox_' num2str(i)]),'string',userConfig.estimate.sep(i));
    end
end


%_________________________Parameter tolerance_____________________________

%create editboxes for tolerance for parameters:
% P(1)  - x translation
% P(2)  - y translation
% P(3)  - z translation
% P(4)  - x rotation about - {pitch} (radians)
% P(5)  - y rotation about - {roll}  (radians)
% P(6)  - z rotation about - {yaw}   (radians)

xyz_names={'X-transf.','Y-transf.:','Z-transf.:','X-rotation:','Y-rotation:','Z-rotation:'};

uicontrol('parent',h_coregconfig,...
    'HorizontalAlignment','left',...
    'style','text',...
    'units','pixels',...
    'position',[30 windowheight-260-15 240 40],...
    'String',['Parameter accuracy:',sprintf('\n'),'(max difference between successive estimates)'],...
    'tag',['hinttext_8'],...
    'BackgroundColor',color);

for i=1:3
    if (i<=runs), vis='on'; else vis='off'; end;
    uicontrol('parent',h_coregconfig,...
        'HorizontalAlignment','left',...
        'style','text',...
        'units','pixels',...
        'position',[30+i*60 windowheight-260-30 60 20],...
        'String',runText{i},...
        'tag',['ubertext_',num2str(i)],...
        'Visible',vis,...
        'BackgroundColor',color);
end

%___create 6 edit boxes for each run
for j=1:6
    uicontrol('parent',h_coregconfig,...
        'HorizontalAlignment','left',...
        'style','text',...
        'units','pixels',...
        'position',[30 windowheight-262-30*(j)-15 60 20],...
        'string',xyz_names{j},...
        'tag',['tag_texteditbox_' num2str(j)],...
        'BackgroundColor',color,...
        'Visible','on');
    for i=1:3
        if (i<=runs), vis='on'; else vis='off'; end;
        uicontrol('parent',h_coregconfig,...
            'HorizontalAlignment','left',...
            'style','edit',...
            'units','pixels',...
            'position',[30+i*60 windowheight-260-30*(j)-15 50 20],...
            'String','',...
            'tag',['tag_editbox_',num2str(i),'_',num2str(j)],...
            'Visible',vis);
        if (i<=runs)
            set(findobj('tag',['tag_editbox_',num2str(i),'_',num2str(j)]),'string',userConfig.estimate.tol((i-1)*6+j));
        end
    end
end
%__________________________________________________________________________


%____ Buttons setup: Apply button, Cancel button and Load Defaults button
%Apply button
uicontrol('parent',h_coregconfig,...
    'HorizontalAlignment','center',...
    'style','pushbutton',...
    'units','pixels',...
    'position',[windowwidth-80 15 55 25],...
    'String','Apply',...
    'Callback',{@ExitConfig_callback,TaskIndex,MethodIndex,possible,field},...
    'tag','tag_apply'...
    );

%Cancel button
uicontrol('parent',h_coregconfig,...
    'HorizontalAlignment','center',...
    'style','pushbutton',...
    'units','pixels',...
    'position',[windowwidth-140 15 55 25],...
    'String','Cancel',...
    'Callback',{@ExitConfig_callback,TaskIndex,MethodIndex,possible,field},...
    'tag','tag_cancel'...
    );

%load defaults button
uicontrol('parent',h_coregconfig,...
    'HorizontalAlignment','center',...
    'style','pushbutton',...
    'units','pixels',...
    'position',[20 15 85 25],...
    'String','Load defaults',...
    'Callback',{@ExitConfig_callback,TaskIndex,MethodIndex,possible,field},...
    'tag','tag_loaddefault'...
    );

return



function project=ExitConfig_callback(h,eventdata,TaskIndex,MethodIndex,possible,field,varargin)
%
% used when options figure is closed, Save new settings and exit configurator
%____________________________________________
% T. Rask 271003, NRU

if(isempty(findobj('tag','mainGUI'))) %if main figure is closed, we just want to exit
    %error('Pipeline figure is missing');
    uiresume(findobj('tag','tag_optionsFig'));
    return
end

% Get project loaded into figure of exampleConfig
h_coregconfig=findobj('tag','tag_optionsFig');
project=get(h_coregconfig,'UserData');

userConfig=project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.user;

%___ Button pressed (either default, apply, cancel or close)
switch(lower(get(h,'tag')))
    
    %_____ Apply settings
    case 'tag_apply'
        %__write message to logbar
        %project=logProject('SPM coreg config saved',project,TaskIndex,MethodIndex);
        
        % Get value in from UIcontrols and Save values in project
        userConfig.to                      = possible{1}{get(findobj('tag','tag_popup_1'),'value')};
        userConfig.estimate.cost_fun       = possible{2}{get(findobj('tag','tag_popup_2'),'value')};
        runs                               = get(findobj('tag','tag_popup_3'),'value');
        
        %read edit fields
        userConfig.estimate=rmfield(userConfig.estimate,'tol');
        userConfig.estimate=rmfield(userConfig.estimate,'sep');
        for i=1:runs
            number=str2num(get(findobj('tag',['tag_DistEditbox_' num2str(i)]),'string'));
            if isempty(number)
                msgbox('Editable fields have to contain numbers.');
                return;
            else
                userConfig.estimate.sep(i)=number;
            end;
            for (j=1:6)
                number=str2num(get(findobj('tag',['tag_editbox_',num2str(i),'_',num2str(j)]),'string'));
                if isempty(number)
                    msgbox('Editable fields have to contain numbers.');
                    return;
                else
                    userConfig.estimate.tol((i-1)*6+j)=number;
                end;
            end
        end
        
        project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.user=userConfig;
        
    case 'tag_loaddefault'
        %get default values
        userConfig=project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.default;
        project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.user=userConfig;
        
        field{1}   = userConfig.to;
        field{2}   = userConfig.estimate.cost_fun;
        field{3}   = length(userConfig.estimate.sep);
        
        %update UI control values
        for n=1:3
            %__find selected value among possible values (even if it is string or number)
            for m=1:length(possible{n})
                if ischar(field{n})
                    if strcmp(field{n},possible{n}{m});
                        value{n}=m;
                        break
                    end
                else
                    if field{n}==possible{n}{m}
                        value{n}=m;
                        break;
                    end
                end
            end
            set(findobj('tag',['tag_popup_' num2str(n)]),'value',value{n});
        end
        
        nRuns_Callback(findobj('tag','tag_popup_3'));
        
        for (i=1:field{3})
            set(findobj('tag',['tag_DistEditbox_' num2str(i)]),'string',userConfig.estimate.sep(i));
            for (j=1:6)
                set(findobj('tag',['tag_editbox_',num2str(i),'_',num2str(j)]),'string',userConfig.estimate.tol((i-1)*6+j));
            end
        end
        
        return% Defaults to configurator are set
        
    otherwise
        %cancel pressed or close pressed = do nothing
        %project=logProject('exit SPM coreg configurator - no changes',project,TaskIndex,MethodIndex);
        uiresume(h_coregconfig);
        
        return
end %switch

%___ Save updated project in configurator.user
set(h_coregconfig,'userdata',project);


%___ Resume uiwait to exit the user-interface of exampleConfig
uiresume(h_coregconfig);
return

%______________________Callback for popup number 5_______________________

function nRuns_Callback(hObject,eventdata)
for (i=1:3)
    if (i<=get(hObject,'value')), vis='on'; else vis='off'; end;
    set(findobj('tag',['ubertext_',num2str(i)]),'visible',vis);
    set(findobj('tag',['tag_DistEditbox_',num2str(i)]),'visible',vis);
    set(findobj('tag',['tag_DistText_',num2str(i)]),'visible',vis);
    for (j=1:6)
        set(findobj('tag',['tag_editbox_',num2str(i),'_',num2str(j)]),'visible',vis);
    end
end
return


function MakeFigureSpm8_CreateFcn(h_coregconfig, eventdata, project, TaskIndex, MethodIndex, varargin)  %(h,eventdata,project_task,TaskIndex,MethodIndex,varargin)
%
% Create figure and UI controls
%____________________________________________

%_____ Get size of mainGUI (the userinterface of the pipeline)
figuresize=get(0,'ScreenSize');

%____Setup the user-interface
%Size of configurator GUI
color=[252/255 252/255 254/255];
windowheight=540;
windowwidth=295;
margen=10;
frame_size=[margen 50 windowwidth-2*margen windowheight-50-margen];                      %do not edit size here [x y width height]

%Setup configurator user-interface w. 'user' value
userConfig=project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.user;

%Specify fields array for creation of popup menu's.
% field   : is current value of field
% possible: shows what values field can hold
% strings : are the discription of all possible fields (this is shown inside the popupmenu)
% text    : is the hint string displayed just above the popupmenu.
%Coregister to:
field{1}   = userConfig.to;
% possible{1}= {1 2};
% strings{1} = {'PET','MR T1-Weighted'};
possible{1}= {2};   %SPM does not work properly to PET
strings{1} = {'MR T1-Weighted'};
text{1}    = 'Coregister to:';
%Cost function
field{2}   = userConfig.estimate.eoptions.cost_fun;
possible{2}= {'mi' 'ecc' 'nmi' 'ncc'};
strings{2} = {'Mutual Information','Entropy Correlation Coefficient','Normalised Mutual Information','Normalised Cross Correlation'};
text{2}    = 'Cost function:';
% Average distance between sampled points (in mm)
field{3}   = userConfig.estimate.eoptions.sep;
possible{3}= {}; % Integer vaiables
strings{3} = {};
text{3}    = 'Sample point distance (in mm)';
% Tolerance when optimizing cost-function
field{4}   = userConfig.estimate.eoptions.tol;
possible{4}= {}; % Integer vaiables
strings{4} = {};
text{4}    = 'Tolerance (distance between successive estimates)';
% Histogram smoothing
field{5}   = userConfig.estimate.eoptions.fwhm;
possible{5}= {}; % Integer vaiables
strings{5} = {};
text{5}    = 'Histogram smoothing (in 256x256 hist)';

%setup configurator GUI figure with information given in project
project_task=sprintf('get(findobj(''Tag'',''tag_optionsFig''),''UserData'')');
% setup configurator GUI figure with information given in project
set(h_coregconfig,...
    'units','pixels',...
    'position',[figuresize(3)/2-windowwidth/2 figuresize(4)/2-windowheight/2 windowwidth windowheight],...
    'MenuBar','none',...
    'NumberTitle','off',...
    'Name',project.pipeline.taskSetup{TaskIndex,MethodIndex}.method,...
    'Color',color,...
    'NextPlot','add',...
    'tag','tag_optionsFig',...
    'resize','off',...
    'CloserequestFcn',{@ExitConfig_callback,TaskIndex,MethodIndex,possible,field});

%Create neat black inner frame
uicontrol('style','frame','units','pixels','position',[frame_size],'BackgroundColor',color);

%create popup menu's containing the data just specified in array
for n=1:5
     if n<=2
        uicontrol('parent',h_coregconfig,...
            'HorizontalAlignment','left',...
            'style','text',...
            'units','pixels',...
            'position',[30 windowheight-45*n 200 20],...
            'String',text{n},...
            'tag',['hinttext_' num2str(n)],...
            'BackgroundColor',color);
        %__find selected value among possible values (even if it is string or number)
        for m=1:length(possible{n})
            if ischar(field{n})
                if strcmp(field{n},possible{n}{m});
                    value{n}=m;
                    break
                end
            else
                if field{n}==possible{n}{m}
                    value{n}=m;
                    break;
                end
            end
        end
        uicontrol('parent',h_coregconfig,...
            'style','popupmenu',...
            'value',value{n},...
            'HorizontalAlignment','left',...
            'units','pixels',...
            'position',[30 windowheight-20-45*n 200 25],...
            'String',strings{n},...
            'Callback',[],...
            'tag',['tag_popup_' num2str(n)]);
    elseif (n==3) % Sample point distance
        uicontrol('parent',h_coregconfig,...
            'HorizontalAlignment','left',...
            'style','text',...
            'units','pixels',...
            'position',[30 windowheight-45*n 200 20],...
            'String',text{n},...
            'tag',['hinttext_' num2str(n)],...
            'BackgroundColor',color);
        counter=1;
        txt{1}='1st run';
        txt{2}='2nd run';
        for j=1:2
            uicontrol('parent',h_coregconfig,...
                'HorizontalAlignment','left',...
                'style','text',...
                'units','pixels',...
                'position',[110+(j-1)*50 windowheight-15-45*n 40 15],...
                'String',txt{j},...
                'tag',['hinttext_' num2str(n)],...
                'BackgroundColor',color);
        end
        for j=1:2
            uicontrol('parent',h_coregconfig,...
                'HorizontalAlignment','left',...
                'style','edit',...
                'units','pixels',...
                'position',[110+(j-1)*50 windowheight-10-45*n-25 40 20],...
                'String',num2str(field{n}(j)),...
                'tag',sprintf('tag_editbox_%i_%i',n,counter),...
                'Visible','on',...
                'Enable','on');
            counter=counter+1;
        end
    elseif (n==4) % Tolerance for cost-functions
        uicontrol('parent',h_coregconfig,...
            'HorizontalAlignment','left',...
            'style','text',...
            'units','pixels',...
            'position',[30 windowheight-20-45*n 200 25],...
            'String',text{n},...
            'tag',['hinttext_' num2str(n)],...
            'BackgroundColor',color);
        txt{1}='1st run';
        txt{2}='2nd run';
        for j=1:2
            uicontrol('parent',h_coregconfig,...
                'HorizontalAlignment','left',...
                'style','text',...
                'units','pixels',...
                'position',[110+(j-1)*50 windowheight-40-45*n 40 15],...
                'String',txt{j},...
                'tag',['hinttext_' num2str(n)],...
                'BackgroundColor',color);
        end
        counter=1;
        txt{1}='X-transf';
        txt{2}='Y-transf';
        txt{3}='Z-transf';
        txt{4}='X-rotation';
        txt{5}='Y-rotation';
        txt{6}='Z-rotation';
        for j=1:6
            uicontrol('parent',h_coregconfig,...
                'HorizontalAlignment','left',...
                'style','text',...
                'units','pixels',...
                'position',[30 windowheight-35-45*n-j*25 60 15],...
                'String',txt{j},...
                'tag',['hinttext_' num2str(n)],...
                'BackgroundColor',color);
            for i=1:2
                k=j+(i-1)*6;
                uicontrol('parent',h_coregconfig,...
                    'HorizontalAlignment','left',...
                    'style','edit',...
                    'units','pixels',...
                    'position',[110+(i-1)*50 windowheight-35-45*n-j*25 40 20],...
                    'String',num2str(field{n}(k)),...
                    'tag',sprintf('tag_editbox_%i_%i',n,counter),...
                    'Visible','on',...
                    'Enable','on');
                counter=counter+1;
            end
        end
    elseif (n==5) % Histogram smoothing
        uicontrol('parent',h_coregconfig,...
            'HorizontalAlignment','left',...
            'style','text',...
            'units','pixels',...
            'position',[30 windowheight-180-45*n 200 20],...
            'String',text{n},...
            'tag',['hinttext_' num2str(n)],...
            'BackgroundColor',color);
        counter=1;
        txt{1}='X';
        txt{2}='Y';
        for j=1:2
            uicontrol('parent',h_coregconfig,...
                'HorizontalAlignment','left',...
                'style','text',...
                'units','pixels',...
                'position',[110+(j-1)*50 windowheight-195-45*n 40 15],...
                'String',txt{j},...
                'tag',['hinttext_' num2str(n)],...
                'BackgroundColor',color);
        end
        for j=1:2
            uicontrol('parent',h_coregconfig,...
                'HorizontalAlignment','left',...
                'style','edit',...
                'units','pixels',...
                'position',[110+(j-1)*50 windowheight-215-45*n 40 20],...
                'String',num2str(field{n}(j)),...
                'tag',sprintf('tag_editbox_%i_%i',n,counter),...
                'Visible','on',...
                'Enable','on');
            counter=counter+1;
        end
    end
end

%____ Buttons setup: Apply button, Cancel button and Load Defaults button
%Apply button
uicontrol('parent',h_coregconfig,...
    'HorizontalAlignment','center',...
    'style','pushbutton',...
    'units','pixels',...
    'position',[windowwidth-80 15 55 25],...
    'String','Apply',...
    'Callback',{@ExitConfigSpm8_callback,project_task,TaskIndex,MethodIndex,possible,field},...
    'tag','tag_apply'...
    );

%Cancel button
uicontrol('parent',h_coregconfig,...
    'HorizontalAlignment','center',...
    'style','pushbutton',...
    'units','pixels',...
    'position',[windowwidth-140 15 55 25],...
    'String','Cancel',...
    'Callback',{@ExitConfigSpm8_callback,project_task,TaskIndex,MethodIndex,possible,field},...
    'tag','tag_cancel'...
    );

%load defaults button
uicontrol('parent',h_coregconfig,...
    'HorizontalAlignment','center',...
    'style','pushbutton',...
    'units','pixels',...
    'position',[20 15 85 25],...
    'String','Load defaults',...
    'Callback',{@ExitConfigSpm8_callback,project_task,TaskIndex,MethodIndex,possible,field},...
    'tag','tag_loaddefault'...
    );

return


function project=ExitConfigSpm8_callback(h,eventdata,project_task,TaskIndex,MethodIndex,possible,field,varargin)
%
% used when options figure is closed, Save new settings and exit configurator
%____________________________________________
% version 20120118CS

if(isempty(findobj('tag','mainGUI'))) %if main figure is closed, we just want to exit
    %error('Pipeline figure is missing');
    uiresume(findobj('tag','tag_optionsFig'));
    return
end

% Get project loaded into figure of exampleConfig
project=get(findobj('Tag','tag_optionsFig'),'UserData');

h_coregconfig=findobj('tag','tag_optionsFig');

userConfig=project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.user;

%___ Button pressed (either default, apply, cancel or close)
switch(lower(get(h,'tag')))
    
    %_____ Apply settings
    case 'tag_apply'
        %__write message to logbar
        %project=logProject('SPM coreg config saved',project,TaskIndex,MethodIndex);     
        userConfig.to                      = possible{1}{get(findobj('tag','tag_popup_1'),'value')};
        userConfig.estimate.eoptions.cost_fun = possible{2}{get(findobj('tag','tag_popup_2'),'value')};
        for i=1:2
            tmp3(i)=str2num(get(findobj('tag',sprintf('tag_editbox_3_%i',i)),'string'));
        end
        userConfig.estimate.eoptions.sep   = tmp3;
        Counter=1;
        for i=1:6
            for j=1:2
                k=i+(j-1)*6;
                tmp4(k)=str2num(get(findobj('tag',sprintf('tag_editbox_4_%i',Counter)),'string'));
                Counter=Counter+1;
            end
        end
        userConfig.estimate.eoptions.tol   = tmp4;
        for i=1:2
            tmp5(i)=round(str2num(get(findobj('tag',sprintf('tag_editbox_5_%i',i)),'string')));
        end
        userConfig.estimate.eoptions.fwhm  = tmp5;
        project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.user=userConfig;

    case 'tag_loaddefault'
        %get default values
        userConfig=project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.default;      
        field{1}   = userConfig.to;
        field{2}   = userConfig.estimate.eoptions.cost_fun;
        field{3}   = userConfig.estimate.eoptions.sep;
        field{4}   = userConfig.estimate.eoptions.tol;
        field{5}   = userConfig.estimate.eoptions.fwhm;
        project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.user=userConfig;
        %update UI control values

        for n=1:5
            if n<=2
                %__find selected value among possible values (even if it is string or number)
                for m=1:length(possible{n})
                    if ischar(field{n})
                        if strcmp(field{n},possible{n}{m});
                            value{n}=m;
                            break
                        end
                    else
                        if field{n}==possible{n}{m}
                            value{n}=m;
                            break;
                        end
                    end
                end
                set(findobj('tag',['tag_popup_' num2str(n)]),'value',value{n});
            elseif (n==3)
                for k=1:2
                    set(findobj('tag',sprintf('tag_editbox_3_%i',k)),'string',field{n}(k));
                end
            elseif (n==4)
                Counter=1;
                for i=1:6
                    for j=1:2
                        k=i+(j-1)*6;
                        set(findobj('tag',sprintf('tag_editbox_4_%i',Counter)),'string',field{n}(k));
                        Counter=Counter+1;
                    end
                end
            elseif (n==5)
                for k=1:2
                    set(findobj('tag',sprintf('tag_editbox_5_%i',k)),'string',field{n}(k));
                end
            end
           
        end
        
        return% Defaults to configurator are set
        
    otherwise
        %cancel pressed or close pressed = do nothing
        %project=logProject('exit SPMcoregistration configurator - no changes',project,TaskIndex,MethodIndex);
        uiresume(h_coregconfig);
        
        return
end %switch

%___ Save updated project in configurator.user
set(h_coregconfig,'userdata',project);


%___ Resume uiwait to exit the user-interface of exampleConfig
uiresume(h_coregconfig);
return
