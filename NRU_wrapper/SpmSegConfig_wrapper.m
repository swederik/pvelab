function project=SpmSegConfig_wrapper(project,TaskIndex,MethodIndex,varargin)
% Example Config_wrapper
%
% Temporaly UserConfig is saved in the 'UserData' field in the fig. sturcture of
%   the configurator window. On exit this is handled back to project w. updated settings
%
% userConfig fields:
%       .example: an integer value 1-10
%
% Input:
%   project     : Structure containing all information of actual pipeline
%   TaskIndex   : Index to active task in the project structure
%   MethodIndex : Index to used method in a TaskIndex in the project structure
%
% Output:
%   project     : Return updated project, with new data under ...configurator.user
%____________________________________________
% M. Twardak 151003, NRU
% SW version: 151003MT
% Modified for SPM8: 20120113 CS

%tjeck if configurator figure exists (chekin_wrapper should prevent this)
if ishandle(findobj('tag','tag_optionsFig'))
    msgbox('SPM Segment config is running');
    return;
end

%tjeck if spm file exists
switch exist('spm','file')
    case 0
        msg='ERROR: Can not find SPM. Addpath or download at www.fil.ion.ucl.ac.uk/spm.';
        %project=logProject(msg,project,TaskIndex,MethodIndex);
        project.taskDone{TaskIndex}.error{end+1}=msg;
        return;
    case 2
        [v,c]=spm('Ver');
        if(strcmpi(v,'spm2'))
            project=logProject('SpmSegConfig_wrapper: SPM2 found. Segmentation progress is shown in SPM-windows.',project,TaskIndex,MethodIndex);
            SPM_ver=2;
        elseif(strcmpi(v,'spm5'))
            project=logProject('SpmSegConfig_wrapper: SPM5 found. Segmentation progress is shown in SPM-windows.',project,TaskIndex,MethodIndex);
            SPM_ver=5;
        elseif(strcmpi(v,'spm8'))
            project=logProject('SpmSegConfig_wrapper: SPM8 found. Segmentation progress is shown in SPM-windows.',project,TaskIndex,MethodIndex);
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

if (SPM_ver==2)
    %Check if default value is given. If not set value from spm_defaults.m
    if(isempty(project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.default))
        
        %get spm default values from spm_defaults.m
        global defaults
        spm_defaults;
        
        userConfig=defaults.segment;
        userConfig.segmentMultiple=1; %option to segment multiple MR-imgs (if loaded)
        userConfig.sNormalize=1; %Spatially normalize to SPM template? Default is 0.
        userConfig.flipAnalyze=defaults.analyze.flip;

        feval('clear','global','defaults'); %Remove global spm defaults tree
        
        project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.default=userConfig;
        %loginfo
        %project=logproject(('Config: Defaults loaded'),project,TaskIndex,MethodIndex);
    end
    
    %_____________Check if all values are set
    userConfig=project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.default;
    if ~isfield(userConfig,'estimate')
        userConfig.estimate=[];
    end
    if ~isfield(userConfig,'write')
        userConfig.write=[];
    end
    if ~isfield(userConfig.estimate,'reg')
        userConfig.estimate.reg=0.01;
    end
    if ~isfield(userConfig.estimate,'cutoff')
        userConfig.estimate.cutoff=30;
    end
    if ~isfield(userConfig.estimate,'samp')
        userConfig.estimate.samp=3;
    end
    if ~isfield(userConfig.estimate,'affreg')
        userConfig.estimate.affreg=[];
    end
    if ~isfield(userConfig.estimate.affreg,'smosrc')
        userConfig.estimate.affreg.smosrc=8;
    end
    if ~isfield(userConfig.estimate.affreg,'regtype')
        userConfig.estimate.affreg.regtype='mni';
    end
    if ~isfield(userConfig.write,'cleanup')
        userConfig.write.cleanup=1;
    end
    if ~isfield(userConfig.write,'wrt_cor')
        userConfig.write.wrt_cor=1;
    end
    if ~isfield(userConfig.estimate,'bb')
        userConfig.estimate.bb=[[-88 88]' [-122 86]' [-60 95]'];
    end
    if ~isfield(userConfig,'segmentMultiple')
        userConfig.segmentMultiple=1;
    end
    if ~isfield(userConfig,'sNormalize')
        userConfig.sNormalize=1;
    end
    if ~isfield(userConfig,'flipAnalyze')
        userConfig.flipAnalyze=1;
    end
    project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.default=userConfig;
    %___________________________________________
    
    
    %Set user configuration to default if it does not exist
    if(isempty(project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.user))
        %'Default' exist in project: load into 'user' as a default value
        userConfig=project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.default;
        project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.user=userConfig;
        %loginfo
        %project=logproject(('Config: Default value is loaded in user'),project,TaskIndex,MethodIndex);
    end
    
    %Make sure there is fields estimate and write
    
    
    %____ Setup and start user-interface of the Example Configurator
    h_segconfig=figure('CreateFcn',{@MakeFigure_CreateFcn, project,TaskIndex,MethodIndex,varargin},'Tag','tag_optionsFig');
    
    %Store temporary project in h_Reslice
    set(h_segconfig,'UserData',project);
    
    %_____Wait for UIRESUME, continues when user presses 'ok'
    uiwait(h_segconfig)
    
    %____ Get updatede project temporaly stored in the configurator fig
    project=get(h_segconfig,'UserData');
    
    %____ Shout down the configurator user-interface
    delete(h_segconfig)

elseif (SPM_ver==5)
    
    if(isempty(project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.default))
        % No user settings have been selected, use defaults set by spm_defaults
        global defaults;
        spm_defaults;
        % def=spm('defaults','pet');         %setup defaults-tree
        def=defaults;
        tmp.opts=def.preproc;
        tmp.opts.msk={''};
        dummy{1}=cleanupcomment(tmp.opts.tpm(1,:));
        dummy{2}=cleanupcomment(tmp.opts.tpm(2,:));
        dummy{3}=cleanupcomment(tmp.opts.tpm(3,:));
        tmp.opts.tpm=dummy;

        tmp.output.GM=[0 0 1];           
        tmp.output.WM=[0 0 1];
        tmp.output.CSF=[0 0 1];          % CSF is needed to remove non brain tissue
        tmp.output.biascor=1;
        tmp.output.cleanup=0;

        project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.default=tmp;
        
        %loginfo
        msg='SpmSegConfig_wrapper: Using SPM5 default settings defined in spm(defaults,pet)';
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
    h_segconfig=figure('CreateFcn',{@MakeFigureSpm5_CreateFcn, project,TaskIndex,MethodIndex,varargin},'Tag','tag_optionsFig');
    
    %Store temporary project in h_Reslice
    set(h_segconfig,'UserData',project);
    
    %_____Wait for UIRESUME, continues when user presses 'ok'
    uiwait(h_segconfig)
    
    %____ Get updatede project temporaly stored in the configurator fig
    project=get(h_segconfig,'UserData');
    
    %____ Shut down the configurator user-interface
    delete(h_segconfig)

elseif (SPM_ver==8)
    
    if(isempty(project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.default))
        % No user settings have been selected, use defaults set by spm_defaults
        def=spm('defaults','pet');         %setup defaults-tree
        tmp.opts=def.preproc;
        tmp.output=tmp.opts.output;
        tmp.opts=rmfield(tmp.opts,'output');
        tmp.opts=rmfield(tmp.opts,'fudge');
        tmp.output.CSF=[0 0 1];            % CSF is needed to remove non brain tissue
        project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.default=tmp;
        
        %loginfo
        msg='SpmSegConfig_wrapper: Using SPM8 default settings defined in spm(defaults,pet)';
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
    h_segconfig=figure('CreateFcn',{@MakeFigureSpm8_CreateFcn, project,TaskIndex,MethodIndex,varargin},'Tag','tag_optionsFig');
    
    %Store temporary project in h_Reslice
    set(h_segconfig,'UserData',project);
    
    %_____Wait for UIRESUME, continues when user presses 'ok'
    uiwait(h_segconfig)
    
    %____ Get updatede project temporaly stored in the configurator fig
    project=get(h_segconfig,'UserData');
    
    %____ Shut down the configurator user-interface
    delete(h_segconfig)

else
    msg='Error: SPM version not recognizable.';
    project=logProject(msg,project,TaskIndex,MethodIndex);
    project.taskDone{TaskIndex}.error{end+1}=msg;
    return;
end
   
%____ Flush graphics to screen
drawnow



function MakeFigure_CreateFcn(h_segconfig, eventdata, project, TaskIndex, MethodIndex, varargin)  %(h,eventdata,project_task,TaskIndex,MethodIndex,varargin)
%
% Create figure and UI controls
%____________________________________________
% M. Twardak 061003, NRU
%SW version: 260803TD

%___Store temporary project in the figure of the exampel configurator
%set(h_segconfig,'UserData',project);

%_____ Get size of mainGUI (the userinterface of the pipeline)
figuresize=get(0,'ScreenSize');

%____Setup the user-interface
%Size of configurator GUI
color=[252/255 252/255 254/255];
windowheight=560;
windowwidth=260;
margen=10;
frame_size=[margen 50 windowwidth-2*margen windowheight-50-margen];                      %do not edit size here [x y width height]

%Setup configurator user-interface w. 'user' value
userConfig=project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.user;


%Specify fields array for creation of popup menu's.
% field   : is current value of field
% possible: shows what values field can hold
% strings : are the discription of all possible fields (this is shown inside the popupmenu)
% text    : is the hint string displayed just above the popupmenu.
%Bias regularisation
field{1}   = userConfig.estimate.reg;
possible{1}= {0 0.00001 0.0001 0.001 0.01 0.1 1 10}; %reg 8 values 5'th is default
strings{1} = {'no regularisation (0)','extremely light regularisation (0.00001)','very light regularisation (0.0001)','light regularisation (0.001)','medium regularisation (0.01)','heavy regularisation (0.1)','very heavy regularisation (1)','extremely heavy regularisation (10)'};
text{1}    = 'Bias regularisation';
%Bias cutoff
field{2}   = userConfig.estimate.cutoff;
possible{2}= {20 25 30 35 40 45 50 60 70 80 90 100 Inf}; %13 values 3'rd is default
strings{2} = {'20mm','25mm','30mm','35mm','40mm','45mm','50mm','60mm','70mm','80mm','90mm','100mm','No correction'};
text{2}    = 'Bias cutoff';
%samp, distance to sample between points
field{3}   = userConfig.estimate.samp;
possible{3}= {1 2 3}; %3 values 3'rd is default
strings{3} = {'1mm','2mm','3mm'};
text{3}    = 'Sample points distance';
%BoundingBox enclosing the region to use for the EM algorithm (the brain in Talairach space)
%userConfig.segment.estimate.bb [x][y][z] values; (code comes later in this file)

%AFFINE registration
%affreg.smosrc, amount of smoothing to use for the source image during affine registration
field{4}   = userConfig.estimate.affreg.smosrc;
possible{4}= {2 4 8 16 32}; %5 values 3'rd is default
strings{4} = {'2mm','4mm','8mm','16mm','32mm'};
text{4}    = 'Smooth source image';
%affreg.regtype
field{5}   = userConfig.estimate.affreg.regtype;
possible{5}= {'mni','rigid','isochoric','isotropic','subj','none'}; %6 values 1'st is default
strings{5} = {'mni - using MNI templates','rigid - constrained to be almost rigid.','isochoric - volume preserving','isotropic - isotropic zoom in all directions','subj - for inter subject registration','none'};
text{5}    = 'Affine registration regularisation';
%affreg.weight
%image caontaining weight map, (we do not use)
%write.cleanup
field{6}   = userConfig.write.cleanup;
possible{6}= {1 0}; %2 values 1'st is default
strings{6} = {'Yes, clean up the partitions','No, dont do cleanup'};
text{6}    = 'Clean up the partitions';
%write.wrt_cor
field{7}   = userConfig.write.wrt_cor;
possible{7}= {1 0}; %2 values 1'st is default
strings{7} = {'Yes, write bias corrected','No, dont write bias corrected'};
text{7}    = 'Write bias corrected image';

%setup configurator GUI figure with information given in project
project_task=sprintf('get(findobj(''Tag'',''tag_optionsFig''),''UserData'')');
set(h_segconfig,...
    'units','pixels',...
    'position',[figuresize(3)/2-windowwidth/2 figuresize(4)/2-windowheight/2 windowwidth windowheight],...
    'MenuBar','none',...
    'NumberTitle','off',...
    'Name',project.pipeline.taskSetup{TaskIndex,MethodIndex}.method,...
    'Color',color,...
    'NextPlot','add',...
    'tag','tag_optionsFig',...
    'resize','off',...
    'CloserequestFcn',{@ExitConfig_callback, project_task,TaskIndex,MethodIndex,possible,field});

uicontrol('style','frame','units','pixels','position',frame_size,'BackgroundColor',color);

%Checkbox - Spatially normalize to SPM template? Default is 0.
uicontrol('parent',h_segconfig,...
    'HorizontalAlignment','left',...
    'style','checkbox',...
    'units','pixels',...
    'position',[30 windowheight-500 200 20],...
    'String','Spatially normalize?',...
    'tag','sNorm',...
    'BackgroundColor',color);
%Set value to user value
set(findobj('Tag','sNorm'),'value',project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.user.sNormalize);


%Checkbox - segment multiple MR-files?
uicontrol('parent',h_segconfig,...
    'HorizontalAlignment','left',...
    'style','checkbox',...
    'units','pixels',...
    'position',[30 windowheight-470 200 20],...
    'String','Segment T2- & PD-weighted?',...
    'tag','segmentAll',...
    'BackgroundColor',color);
%Set value to user value
set(findobj('Tag','segmentAll'),'value',project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.user.segmentMultiple);
%disable checkbox if only 1 MR image is loaded.
noModalities=length(project.pipeline.imageModality);
if (noModalities==2)
    set(findobj('Tag','segmentAll'),'enable','off');
else
    set(findobj('Tag','segmentAll'),'enable','on');
end;

%create editboxes for boundingbox [x][y][z] values
uicontrol('parent',h_segconfig,...
    'HorizontalAlignment','left',...
    'style','text',...
    'units','pixels',...
    'position',[30 windowheight-360 150 20],...
    'String','Boundingbox region',...
    'tag','hinttext_8',...
    'BackgroundColor',color);
%__create 6 edit boxes for the 6 boundingbox values
xyz_names={'X','Y','Z'};
counter=1;
for j=1:3
    uicontrol('parent',h_segconfig,...
        'HorizontalAlignment','left',...
        'style','text',...
        'units','pixels',...
        'position',[30 windowheight-352-30*(j) 15 20],...
        'string',xyz_names{j},...
        'tag',['tag_texteditbox_' num2str(j)],...
        'BackgroundColor',color,...
        'Visible','on');
    for i=1:2
        uicontrol('parent',h_segconfig,...
            'HorizontalAlignment','left',...
            'style','edit',...
            'units','pixels',...
            'position',[-15+i*60 windowheight-350-30*(j) 50 20],...
            'String',num2str(userConfig.estimate.bb(counter)),...
            'tag',['tag_editbox_' num2str(counter)],...
            'Visible','on',...
            'Enable','on');
        counter=counter+1;
    end
end

%create popup menu's containing the data just specified in array
for n=1:7
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
    uicontrol('parent',h_segconfig,...
        'HorizontalAlignment','left',...
        'style','text',...
        'units','pixels',...
        'position',[30 windowheight-45*n 200 20],...
        'String',text{n},...
        'tag',['hinttext_' num2str(n)],...
        'BackgroundColor',color);
    uicontrol('parent',h_segconfig,...
        'style','popupmenu',...
        'value',value{n},...
        'HorizontalAlignment','left',...
        'units','pixels',...
        'position',[30 windowheight-20-45*n 200 25],...
        'String',strings{n},...
        'Callback',[],...
        'tag',['tag_popup_' num2str(n)]);
end


%____ Buttons setup: Apply button, Cancel button and Load Defaults button
%Apply button
uicontrol('parent',h_segconfig,...
    'HorizontalAlignment','center',...
    'style','pushbutton',...
    'units','pixels',...
    'position',[windowwidth-80 15 55 25],...
    'String','Apply',...
    'Callback',{@ExitConfig_callback,project_task,TaskIndex,MethodIndex,possible,field},...
    'tag','tag_apply'...
    );

%Cancel button
uicontrol('parent',h_segconfig,...
    'HorizontalAlignment','center',...
    'style','pushbutton',...
    'units','pixels',...
    'position',[windowwidth-140 15 55 25],...
    'String','Cancel',...
    'Callback',{@ExitConfig_callback,project_task,TaskIndex,MethodIndex,possible,field},...
    'tag','tag_cancel'...
    );

%load defaults button
uicontrol('parent',h_segconfig,...
    'HorizontalAlignment','center',...
    'style','pushbutton',...
    'units','pixels',...
    'position',[20 15 85 25],...
    'String','Load defaults',...
    'Callback',{@ExitConfig_callback,project_task,TaskIndex,MethodIndex,possible,field},...
    'tag','tag_loaddefault'...
    );




function project=ExitConfig_callback(h,eventdata,project_task,TaskIndex,MethodIndex,possible,field,varargin)
%
% used when options figure is closed, Save new settings and exit configurator
%____________________________________________
% M. Twardak 061003, NRU
%SW version: 260803TD

if(isempty(findobj('tag','mainGUI'))) %if main figure is closed, we just want to exit
    %error('Pipeline figure is missing');
    uiresume(findobj('tag','tag_optionsFig'));
    return
end

% Get project loaded into figure of exampleConfig
project=get(findobj('Tag','tag_optionsFig'),'UserData');


h_segconfig=findobj('tag','tag_optionsFig');
userConfig=project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.user;

%___ Button pressed (either default, apply, cancel or close)
switch(lower(get(h,'tag')))
    
    %_____ Apply settings
    case 'tag_apply'
        %__write message to logbar
        %project=logProject('SPM segment config saved',project,TaskIndex,MethodIndex);
        
        % Get value in from UIcontrols and Save values in project
        %         userConfig.estimate.priors = str2mat(...
        %             fullfile(spm('Dir'),'apriori','gray.mnc'),...
        %             fullfile(spm('Dir'),'apriori','white.mnc'),...
        %             fullfile(spm('Dir'),'apriori','csf.mnc'));
        userConfig.estimate.reg            = possible{1}{get(findobj('tag','tag_popup_1'),'value')};
        userConfig.estimate.cutoff         = possible{2}{get(findobj('tag','tag_popup_2'),'value')};
        userConfig.estimate.samp           = possible{3}{get(findobj('tag','tag_popup_3'),'value')};
        userConfig.estimate.affreg.smosrc  = possible{4}{get(findobj('tag','tag_popup_4'),'value')};
        userConfig.estimate.affreg.regtype = possible{5}{get(findobj('tag','tag_popup_5'),'value')}; %string
        userConfig.estimate.affreg.weight  = ''; %we have no weight image, so it is empty
        userConfig.write.cleanup           = possible{6}{get(findobj('tag','tag_popup_6'),'value')};
        userConfig.write.wrt_cor           = possible{7}{get(findobj('tag','tag_popup_7'),'value')};
        for k=1:6
            temp(k) = str2num(get(findobj('tag',['tag_editbox_' num2str(k)]),'string'));
        end
        userConfig.estimate.bb=[[temp(1) temp(2)]' [temp(3) temp(4)]' [temp(5) temp(6)]']; %[[-88 88]' [-122 86]' [-60 95]'
        
        userConfig.segmentMultiple=get(findobj('tag','segmentAll'),'value');
        userConfig.sNormalize=get(findobj('tag','sNorm'),'value');
        project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.user=userConfig;
        
    case 'tag_loaddefault'
        %get default values
        userConfig=project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.default;
        set(findobj('tag','segmentAll'),'value',userConfig.segmentMultiple);
        set(findobj('tag','sNorm'),'value',userConfig.sNormalize);
        field{1}   = userConfig.estimate.reg;
        field{2}   = userConfig.estimate.cutoff;
        field{3}   = userConfig.estimate.samp;
        field{4}   = userConfig.estimate.affreg.smosrc;
        field{5}   = userConfig.estimate.affreg.regtype;
        field{6}   = userConfig.write.cleanup;
        field{7}   = userConfig.write.wrt_cor;
        project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.user=userConfig;
        %update UI control values
        for n=1:7
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
        for k=1:6
            set(findobj('tag',['tag_editbox_' num2str(k)]),'string',num2str(userConfig.estimate.bb(k)));
        end
        
        return% Defaults to configurator are set
        
    otherwise
        %cancel pressed or close pressed = do nothing
        %project=logProject('exit SPMsegment configurator - no changes',project,TaskIndex,MethodIndex);
        uiresume(h_segconfig);
        
        return
end %switch

%___ Save updated project in configurator.user
set(h_segconfig,'userdata',project);


%___ Resume uiwait to exit the user-interface of exampleConfig
uiresume(h_segconfig)
return


function MakeFigureSpm5_CreateFcn(h_segconfig, eventdata, project, TaskIndex, MethodIndex, varargin)  %(h,eventdata,project_task,TaskIndex,MethodIndex,varargin)
%
% Create figure and UI controls
%____________________________________________
% SPM 20120710 CS


%_____ Get size of mainGUI (the userinterface of the pipeline)
figuresize=get(0,'ScreenSize');

%____Setup the user-interface
%Size of configurator GUI
color=[252/255 252/255 254/255];
windowheight=560;
windowwidth=260;
margen=10;
frame_size=[margen 50 windowwidth-2*margen windowheight-50-margen];                      %do not edit size here [x y width height]

%Setup configurator user-interface w. 'user' value
userConfig=project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.user;


%Specify fields array for creation of popup menu's.
% field   : is current value of field
% possible: shows what values field can hold
% strings : are the discription of all possible fields (this is shown inside the popupmenu)
% text    : is the hint string displayed just above the popupmenu.
% Biascor
field{1}   = userConfig.output.biascor;
possible{1}= {1 0}; 
strings{1} = {'Yes, write bias corrected','No, dont write bias corrected'};
text{1}    = 'Write bias corrected image';
% Cleanup
field{2}   = userConfig.output.cleanup;
possible{2}= {1 0}; 
strings{2} = {'Yes, clean up the partitions','No, dont do cleanup'};
text{2}    = 'Clean up the partitions';
% No of Gaussians per class
field{3}   = userConfig.opts.ngaus;
possible{3}= {}; % Integer vaiables
strings{3} = {};
text{3}    = 'Gaussians per class';
% Type of regularization used
field{4}   = userConfig.opts.warpreg;
possible{4}= {0.9 1 1.1 1.2 2}; 
strings{4} = {'0.9','1','1.1','1.2','2'};
text{4}    = 'Warping regularization';
% Cutoff
field{5}   = userConfig.opts.warpco;
possible{5}= {10 15 20 25 30 35 40}; 
strings{5} = {'10','15','20','25','30','35','40'};
text{5}    = 'Warping frequency cutoff';
% Bias regularisation
field{6}   = userConfig.opts.biasreg;
possible{6}= {0 0.00001 0.0001 0.001 0.01 0.1 1 10}; 
strings{6} = {'no regularisation (0)','extremely light regularisation (0.00001)','very light regularisation (0.0001)','light regularisation (0.001)','medium regularisation (0.01)','heavy regularisation (0.1)','very heavy regularisation (1)','extremely heavy regularisation (10)'};
text{6}    = 'Bias regularisation';
% Bias cutoff
field{7}   = userConfig.opts.biasfwhm;
possible{7}= {30 40 50 60 70 80 90 100 110 120 130 140 150 Inf}; 
strings{7} = {'30mm','40mm','50mm','60mm','70mm','80mm','90mm','100mm','110mm','120mm','130mm','140mm','150mm','No correction'};
text{7}    = 'Bias cutoff';
% Type of regularization used
field{8}   = userConfig.opts.regtype;
possible{8}= {'' 'mni' 'eastern' 'subj' 'none'}; % Kind of regularization
strings{8} = {'No affine registration','ICBM space template - European brain','ICBM space template - East Asian brain','Average size brain','No regularization'};
text{8}    = 'Warping regularization';
% samp, distance to sample between points
field{9}   = userConfig.opts.samp;
possible{9}= {1 2 3 4 5}; % Sampling distance
strings{9} = {'1','2','3','4','5'};
text{9}    = 'Sampling distance';

%setup configurator GUI figure with information given in project
project_task=sprintf('get(findobj(''Tag'',''tag_optionsFig''),''UserData'')');
set(h_segconfig,...
    'units','pixels',...
    'position',[figuresize(3)/2-windowwidth/2 figuresize(4)/2-windowheight/2 windowwidth windowheight],...
    'MenuBar','none',...
    'NumberTitle','off',...
    'Name',project.pipeline.taskSetup{TaskIndex,MethodIndex}.method,...
    'Color',color,...
    'NextPlot','add',...
    'tag','tag_optionsFig',...
    'resize','off',...
    'CloserequestFcn',{@ExitConfig_callback, project_task,TaskIndex,MethodIndex,possible,field});

uicontrol('style','frame','units','pixels','position',frame_size,'BackgroundColor',color);

%create popup menu's containing the data just specified in array
for n=1:9
    uicontrol('parent',h_segconfig,...
        'HorizontalAlignment','left',...
        'style','text',...
        'units','pixels',...
        'position',[30 windowheight-45*n 200 20],...
        'String',text{n},...
        'tag',['hinttext_' num2str(n)],...
        'BackgroundColor',color);
    if n~=3
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
        uicontrol('parent',h_segconfig,...
            'style','popupmenu',...
            'value',value{n},...
            'HorizontalAlignment','left',...
            'units','pixels',...
            'position',[30 windowheight-20-45*n 200 25],...
            'String',strings{n},...
            'Callback',[],...
            'tag',['tag_popup_' num2str(n)]);
    else
        counter=1;
        for j=1:4
            switch j
                case 1
                    txt='GM';
                case 2
                    txt='WM';
                case 3
                    txt='CSF';
                case 4
                    txt='BG';
            end
            uicontrol('parent',h_segconfig,...
                'HorizontalAlignment','left',...
                'style','text',...
                'units','pixels',...
                'position',[30+(j-1)*50 windowheight-15-45*n 20 15],...
                'String',txt,...
                'tag',['hinttext_' num2str(n)],...
                'BackgroundColor',color);
            uicontrol('parent',h_segconfig,...
                'HorizontalAlignment','left',...
                'style','edit',...
                'units','pixels',...
                'position',[50+(j-1)*50 windowheight-15-45*n 20 20],...
                'String',num2str(field{n}(j)),...
                'tag',['tag_editbox_' num2str(counter)],...
                'Visible','on',...
                'Enable','on');
            counter=counter+1;
        end
    end
end


%____ Buttons setup: Apply button, Cancel button and Load Defaults button
%Apply button
uicontrol('parent',h_segconfig,...
    'HorizontalAlignment','center',...
    'style','pushbutton',...
    'units','pixels',...
    'position',[windowwidth-80 15 55 25],...
    'String','Apply',...
    'Callback',{@ExitConfigSpm5_callback,project_task,TaskIndex,MethodIndex,possible,field},...
    'tag','tag_apply'...
    );

%Cancel button
uicontrol('parent',h_segconfig,...
    'HorizontalAlignment','center',...
    'style','pushbutton',...
    'units','pixels',...
    'position',[windowwidth-140 15 55 25],...
    'String','Cancel',...
    'Callback',{@ExitConfigSpm5_callback,project_task,TaskIndex,MethodIndex,possible,field},...
    'tag','tag_cancel'...
    );

%load defaults button
uicontrol('parent',h_segconfig,...
    'HorizontalAlignment','center',...
    'style','pushbutton',...
    'units','pixels',...
    'position',[20 15 85 25],...
    'String','Load defaults',...
    'Callback',{@ExitConfigSpm5_callback,project_task,TaskIndex,MethodIndex,possible,field},...
    'tag','tag_loaddefault'...
    );





function project=ExitConfigSpm5_callback(h,eventdata,project_task,TaskIndex,MethodIndex,possible,field,varargin)
%
% used when options figure is closed, Save new settings and exit configurator
%____________________________________________
% version 20120710CS

if(isempty(findobj('tag','mainGUI'))) %if main figure is closed, we just want to exit
    %error('Pipeline figure is missing');
    uiresume(findobj('tag','tag_optionsFig'));
    return
end

% Get project loaded into figure of exampleConfig
project=get(findobj('Tag','tag_optionsFig'),'UserData');
h_segconfig=findobj('tag','tag_optionsFig');
userConfig=project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.user;

%___ Button pressed (either default, apply, cancel or close)
switch(lower(get(h,'tag')))
    
    %_____ Apply settings
    case 'tag_apply'
        %__write message to logbar
        %project=logProject('SPM segment config saved',project,TaskIndex,MethodIndex);     
        for k=1:4
            tmp(k)=round(str2num(get(findobj('tag',['tag_editbox_' num2str(k)]),'string')));
        end
        userConfig.output.biascor          = possible{1}{get(findobj('tag','tag_popup_1'),'value')};
        userConfig.output.cleanup          = possible{2}{get(findobj('tag','tag_popup_2'),'value')};
        userConfig.opts.ngaus=tmp;
        userConfig.opts.warpreg            = possible{4}{get(findobj('tag','tag_popup_4'),'value')};
        userConfig.opts.warpco             = possible{5}{get(findobj('tag','tag_popup_5'),'value')}; 
        userConfig.opts.biasreg            = possible{6}{get(findobj('tag','tag_popup_6'),'value')}; 
        userConfig.opts.biasfwhm           = possible{7}{get(findobj('tag','tag_popup_7'),'value')};
        userConfig.opts.regtype            = possible{8}{get(findobj('tag','tag_popup_8'),'value')};
        userConfig.opts.samp               = possible{9}{get(findobj('tag','tag_popup_9'),'value')};
        project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.user=userConfig;
    case 'tag_loaddefault'
        %get default values
        userConfig=project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.default;      
        field{1}   = userConfig.output.biascor;
        field{2}   = userConfig.output.cleanup;
        field{3}   = userConfig.opts.ngaus;
        field{4}   = userConfig.opts.warpreg;
        field{5}   = userConfig.opts.warpco;
        field{6}   = userConfig.opts.biasreg;
        field{7}   = userConfig.opts.biasfwhm;
        field{8}   = userConfig.opts.regtype;
        field{9}   = userConfig.opts.samp;
        project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.user=userConfig;
        %update UI control values
        for n=1:9
            if n~=3
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
            else
                for k=1:4
                    set(findobj('tag',['tag_editbox_' num2str(k)]),'string',field{n}(k));
                end
                
            end
            
        end
        
        return% Defaults to configurator are set
        
    otherwise
        %cancel pressed or close pressed = do nothing
        %project=logProject('exit SPMsegment configurator - no changes',project,TaskIndex,MethodIndex);
        uiresume(h_segconfig);
        
        return
end %switch

%___ Save updated project in configurator.user
set(h_segconfig,'userdata',project);


%___ Resume uiwait to exit the user-interface of exampleConfig
uiresume(h_segconfig)
return



function MakeFigureSpm8_CreateFcn(h_segconfig, eventdata, project, TaskIndex, MethodIndex, varargin)  %(h,eventdata,project_task,TaskIndex,MethodIndex,varargin)
%
% Create figure and UI controls
%____________________________________________
% SPM 20120113 CS


%_____ Get size of mainGUI (the userinterface of the pipeline)
figuresize=get(0,'ScreenSize');

%____Setup the user-interface
%Size of configurator GUI
color=[252/255 252/255 254/255];
windowheight=560;
windowwidth=260;
margen=10;
frame_size=[margen 50 windowwidth-2*margen windowheight-50-margen];                      %do not edit size here [x y width height]

%Setup configurator user-interface w. 'user' value
userConfig=project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.user;


%Specify fields array for creation of popup menu's.
% field   : is current value of field
% possible: shows what values field can hold
% strings : are the discription of all possible fields (this is shown inside the popupmenu)
% text    : is the hint string displayed just above the popupmenu.
% Biascor
field{1}   = userConfig.output.biascor;
possible{1}= {1 0}; 
strings{1} = {'Yes, write bias corrected','No, dont write bias corrected'};
text{1}    = 'Write bias corrected image';
% Cleanup
field{2}   = userConfig.output.cleanup;
possible{2}= {1 0}; 
strings{2} = {'Yes, clean up the partitions','No, dont do cleanup'};
text{2}    = 'Clean up the partitions';
% No of Gaussians per class
field{3}   = userConfig.opts.ngaus;
possible{3}= {}; % Integer vaiables
strings{3} = {};
text{3}    = 'Gaussians per class';
% Type of regularization used
field{4}   = userConfig.opts.warpreg;
possible{4}= {0.9 1 1.1 1.2 2}; 
strings{4} = {'0.9','1','1.1','1.2','2'};
text{4}    = 'Warping regularization';
% Cutoff
field{5}   = userConfig.opts.warpco;
possible{5}= {10 15 20 25 30 35 40}; 
strings{5} = {'10','15','20','25','30','35','40'};
text{5}    = 'Warping frequency cutoff';
% Bias regularisation
field{6}   = userConfig.opts.biasreg;
possible{6}= {0 0.00001 0.0001 0.001 0.01 0.1 1 10}; 
strings{6} = {'no regularisation (0)','extremely light regularisation (0.00001)','very light regularisation (0.0001)','light regularisation (0.001)','medium regularisation (0.01)','heavy regularisation (0.1)','very heavy regularisation (1)','extremely heavy regularisation (10)'};
text{6}    = 'Bias regularisation';
% Bias cutoff
field{7}   = userConfig.opts.biasfwhm;
possible{7}= {30 40 50 60 70 80 90 100 110 120 130 140 150 Inf}; 
strings{7} = {'30mm','40mm','50mm','60mm','70mm','80mm','90mm','100mm','110mm','120mm','130mm','140mm','150mm','No correction'};
text{7}    = 'Bias cutoff';
% Type of regularization used
field{8}   = userConfig.opts.regtype;
possible{8}= {'' 'mni' 'eastern' 'subj' 'none'}; % Kind of regularization
strings{8} = {'No affine registration','ICBM space template - European brain','ICBM space template - East Asian brain','Average size brain','No regularization'};
text{8}    = 'Warping regularization';
% samp, distance to sample between points
field{9}   = userConfig.opts.samp;
possible{9}= {1 2 3 4 5}; % Sampling distance
strings{9} = {'1','2','3','4','5'};
text{9}    = 'Sampling distance';

%setup configurator GUI figure with information given in project
project_task=sprintf('get(findobj(''Tag'',''tag_optionsFig''),''UserData'')');
set(h_segconfig,...
    'units','pixels',...
    'position',[figuresize(3)/2-windowwidth/2 figuresize(4)/2-windowheight/2 windowwidth windowheight],...
    'MenuBar','none',...
    'NumberTitle','off',...
    'Name',project.pipeline.taskSetup{TaskIndex,MethodIndex}.method,...
    'Color',color,...
    'NextPlot','add',...
    'tag','tag_optionsFig',...
    'resize','off',...
    'CloserequestFcn',{@ExitConfig_callback, project_task,TaskIndex,MethodIndex,possible,field});

uicontrol('style','frame','units','pixels','position',frame_size,'BackgroundColor',color);

%create popup menu's containing the data just specified in array
for n=1:9
    uicontrol('parent',h_segconfig,...
        'HorizontalAlignment','left',...
        'style','text',...
        'units','pixels',...
        'position',[30 windowheight-45*n 200 20],...
        'String',text{n},...
        'tag',['hinttext_' num2str(n)],...
        'BackgroundColor',color);
    if n~=3
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
        uicontrol('parent',h_segconfig,...
            'style','popupmenu',...
            'value',value{n},...
            'HorizontalAlignment','left',...
            'units','pixels',...
            'position',[30 windowheight-20-45*n 200 25],...
            'String',strings{n},...
            'Callback',[],...
            'tag',['tag_popup_' num2str(n)]);
    else
        counter=1;
        for j=1:4
            switch j
                case 1
                    txt='GM';
                case 2
                    txt='WM';
                case 3
                    txt='CSF';
                case 4
                    txt='BG';
            end
            uicontrol('parent',h_segconfig,...
                'HorizontalAlignment','left',...
                'style','text',...
                'units','pixels',...
                'position',[30+(j-1)*50 windowheight-15-45*n 20 15],...
                'String',txt,...
                'tag',['hinttext_' num2str(n)],...
                'BackgroundColor',color);
            uicontrol('parent',h_segconfig,...
                'HorizontalAlignment','left',...
                'style','edit',...
                'units','pixels',...
                'position',[50+(j-1)*50 windowheight-15-45*n 20 20],...
                'String',num2str(field{n}(j)),...
                'tag',['tag_editbox_' num2str(counter)],...
                'Visible','on',...
                'Enable','on');
            counter=counter+1;
        end
    end
end


%____ Buttons setup: Apply button, Cancel button and Load Defaults button
%Apply button
uicontrol('parent',h_segconfig,...
    'HorizontalAlignment','center',...
    'style','pushbutton',...
    'units','pixels',...
    'position',[windowwidth-80 15 55 25],...
    'String','Apply',...
    'Callback',{@ExitConfigSpm8_callback,project_task,TaskIndex,MethodIndex,possible,field},...
    'tag','tag_apply'...
    );

%Cancel button
uicontrol('parent',h_segconfig,...
    'HorizontalAlignment','center',...
    'style','pushbutton',...
    'units','pixels',...
    'position',[windowwidth-140 15 55 25],...
    'String','Cancel',...
    'Callback',{@ExitConfigSpm8_callback,project_task,TaskIndex,MethodIndex,possible,field},...
    'tag','tag_cancel'...
    );

%load defaults button
uicontrol('parent',h_segconfig,...
    'HorizontalAlignment','center',...
    'style','pushbutton',...
    'units','pixels',...
    'position',[20 15 85 25],...
    'String','Load defaults',...
    'Callback',{@ExitConfigSpm8_callback,project_task,TaskIndex,MethodIndex,possible,field},...
    'tag','tag_loaddefault'...
    );





function project=ExitConfigSpm8_callback(h,eventdata,project_task,TaskIndex,MethodIndex,possible,field,varargin)
%
% used when options figure is closed, Save new settings and exit configurator
%____________________________________________
% version 20120117CS

if(isempty(findobj('tag','mainGUI'))) %if main figure is closed, we just want to exit
    %error('Pipeline figure is missing');
    uiresume(findobj('tag','tag_optionsFig'));
    return
end

% Get project loaded into figure of exampleConfig
project=get(findobj('Tag','tag_optionsFig'),'UserData');
h_segconfig=findobj('tag','tag_optionsFig');
userConfig=project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.user;

%___ Button pressed (either default, apply, cancel or close)
switch(lower(get(h,'tag')))
    
    %_____ Apply settings
    case 'tag_apply'
        %__write message to logbar
        %project=logProject('SPM segment config saved',project,TaskIndex,MethodIndex);     
        for k=1:4
            tmp(k)=round(str2num(get(findobj('tag',['tag_editbox_' num2str(k)]),'string')));
        end
        userConfig.output.biascor          = possible{1}{get(findobj('tag','tag_popup_1'),'value')};
        userConfig.output.cleanup          = possible{2}{get(findobj('tag','tag_popup_2'),'value')};
        userConfig.opts.ngaus=tmp;
        userConfig.opts.warpreg            = possible{4}{get(findobj('tag','tag_popup_4'),'value')};
        userConfig.opts.warpco             = possible{5}{get(findobj('tag','tag_popup_5'),'value')}; 
        userConfig.opts.biasreg            = possible{6}{get(findobj('tag','tag_popup_6'),'value')}; 
        userConfig.opts.biasfwhm           = possible{7}{get(findobj('tag','tag_popup_7'),'value')};
        userConfig.opts.regtype            = possible{8}{get(findobj('tag','tag_popup_8'),'value')};
        userConfig.opts.samp               = possible{9}{get(findobj('tag','tag_popup_9'),'value')};
        project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.user=userConfig;
    case 'tag_loaddefault'
        %get default values
        userConfig=project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.default;      
        field{1}   = userConfig.output.biascor;
        field{2}   = userConfig.output.cleanup;
        field{3}   = userConfig.opts.ngaus;
        field{4}   = userConfig.opts.warpreg;
        field{5}   = userConfig.opts.warpco;
        field{6}   = userConfig.opts.biasreg;
        field{7}   = userConfig.opts.biasfwhm;
        field{8}   = userConfig.opts.regtype;
        field{9}   = userConfig.opts.samp;
        project.pipeline.taskSetup{TaskIndex,MethodIndex}.configurator.user=userConfig;
        %update UI control values
        for n=1:9
            if n~=3
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
            else
                for k=1:4
                    set(findobj('tag',['tag_editbox_' num2str(k)]),'string',field{n}(k));
                end
                
            end
            
        end
        
        return% Defaults to configurator are set
        
    otherwise
        %cancel pressed or close pressed = do nothing
        %project=logProject('exit SPMsegment configurator - no changes',project,TaskIndex,MethodIndex);
        uiresume(h_segconfig);
        
        return
end %switch

%___ Save updated project in configurator.user
set(h_segconfig,'userdata',project);


%___ Resume uiwait to exit the user-interface of exampleConfig
uiresume(h_segconfig)
return
