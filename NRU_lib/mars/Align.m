function varargout=Align(varargin);
%
% function varargout=Align(varargin);
%
% Coregistration module for calling alignlinear (Air 5.0);
%
% ADDED files field in userdata - to make CloseFunction possible 120104TR
%
set(gcbf,'pointer','watch');
blueish=[239 250 255]/255;
gray=0.7020*ones(1,3);
if nargin>0
    if ischar(varargin{1})
        switch varargin{1}
            case 'init'
                % Here comes the data...
                files=varargin{2};
                parent=varargin{3};
                ReturnFcn=varargin{4};
                Visualizer=varargin{5};
                if not(isempty(files.STD));
                    [Path,File]=fileparts(files.STD);
                    files.STD=fullfile(Path,File);
                end
                if not(iscell(files.RES));
                    tmp=files.RES;
                    files.RES=cell(1);
                    files.RES{1}=tmp;
                end
                for j=1:length(files.RES)
                    if not(isempty(files.RES{j}));
                        [Path,File]=fileparts(files.RES{j});
                        files.RES{j}=fullfile(Path,File);
                    end
                end
                h=SetupWindow(files,parent,ReturnFcn,Visualizer);
                if nargout==1
                    varargout{1}=h;
                end
            case 'CheckValue'
                Str=get(gcbo,'string');
                OldVal=get(gcbo,'userdata');
                NewVal=str2num(Str);
                if isempty(NewVal)
                    NewVal=OldVal;
                end
                NewStr=num2str(NewVal);
                set(gcbo,'userdata',NewVal);
                set(gcbo,'string',NewStr);
                if nargin>2
                    Align(varargin{3:length(varargin)});
                end
                if not(strcmp(varargin{2},'dummy'))
                    userdat=get(gcbf,'userdata');
                    val=get(gcbo,'userdata');
                    eval(['userdat.' varargin{2} '=val;']);
                    set(gcbf,'userdat',userdat);
                end
            case 'SelectSTD'
                [File Path]=uigetfile('*.hdr','Select STD dataset');
                if not(File==0);
                    dots=strfind(File,'.');
                    if not(isempty(dots))
                        dots=dots(length(dots));
                        File=File(1:dots-1);
                    end
                    File=fullfile(Path,File);
                    set(findobj(gcbf,'tag','STDfilename'),'string',File);
                end
            case 'AddRES'
                cwd=pwd;
                [files,result]=ui_choosefiles(cwd,'*.hdr','Select RES dataset',[]);
                cd(cwd);
                if not(result==-1);
                    for j=1:length(files)
                        dots=strfind(files{j},'.');
                        if not(isempty(dots))
                            dots=dots(length(dots));
                            files{j}=files{j}(1:dots-1);
                        end
                    end
                    OldFiles=get(findobj(gcbf,'tag','RESfilename'),'string');
                    if isempty(OldFiles)
                        NewFiles=files;
                    else
                        if iscell(OldFiles) & length(OldFiles)==1 & ...
                                strcmp(OldFiles,'');
                            NewFiles=files;
                        else
                            if not(iscell(OldFiles))
                                NewFiles{1}=OldFiles;
                                NewFiles(2:length(files)+1)=files;
                            else
                                NewFiles=OldFiles;
                                NewFiles(length(NewFiles)+1:length(NewFiles)+length(files))=files;
                            end
                        end
                    end
                    set(findobj(gcbf,'tag','RESfilename'),'string',NewFiles);
                end
            case 'RemoveRES'
                Current=get(findobj(gcbf,'tag','RESfilename'),'value');
                Names=get(findobj(gcbf,'tag','RESfilename'),'string');
                if length(Names)>1
                    NewNames=cell(length(Names)-1,1);
                    idx=1;
                    for j=1:length(Names)
                        if not(j==Current)
                            NewNames{idx}=Names{j};
                            idx=idx+1;
                        end
                    end
                else
                    NewNames=[];
                end
                set(findobj(gcbf,'tag','RESfilename'),'string',NewNames);
            case 'CheckAlignmentProgram'
                Cmd=get(gcbo,'string');
                OldCmd=get(gcbo,'userdata');
                [stat,where]=unix(['which ' Cmd]);
                userdat=get(gcbf,'userdata');
                if not(stat==0)
                    warndlg(['The program ' Cmd ' is not on your unix path!' ...
                        ' Reverting to ' OldCmd],'Command not found!');
                    set(gcbo,'string',get(gcbo,'userdata'));
                else
                    userdat.AlignmentProgram=Cmd;
                    set(gcbo,'userdata',Cmd);
                    set(gcbf,'userdata',userdat);
                end
            case 'ModalityChange'
                tag=get(gcbo,'tag');
                kids=findobj(gcbf,'type','uicontrol');
                kidstate=get(kids,'enable');
                for j=1:length(kids)
                    if not(strcmp(get(kids(j),'enable'),'off'))
                        set(kids(j),'enable','inactive');
                    end
                end
                if strcmp(tag,'Intra')
                    h=IntraChoice(gcbf);
                    otag=findobj(gcbf,'tag','Inter');
                else
                    h=InterChoice(gcbf);
                    otag=findobj(gcbf,'tag','Intra');
                end
                newstate=get(kids,'enable');
                set(otag,'value',0,'backgroundcolor',blueish)
                set(gcbo,'backgroundcolor',gray,'value',1);
                uiwait(h);
                for j=1:length(kids)
                    if strcmp(newstate{j},'inactive')
                        set(kids(j),'enable',kidstate{j});
                    end
                end
            case 'CostChange'
                tag=get(gcbo,'tag');
                if strcmp(tag,'CostSDRI')
                    otag(1)=findobj(gcbf,'tag','CostLSDI');
                    otag(2)=findobj(gcbf,'tag','CostLSIR');
                elseif strcmp(tag,'CostLSDI')
                    otag(1)=findobj(gcbf,'tag','CostSDRI');
                    otag(2)=findobj(gcbf,'tag','CostLSIR');
                elseif strcmp(tag,'CostLSIR')
                    otag(1)=findobj(gcbf,'tag','CostSDRI');
                    otag(2)=findobj(gcbf,'tag','CostLSDI');
                end
                set(otag,'value',0,'backgroundcolor',blueish)
                set(gcbo,'backgroundcolor',gray,'value',1);
                userdat=get(gcbf,'userdata');
                userdat.CostFunction=get(gcbo,'userdata');
                set(gcbf,'userdata',userdat);
            case 'SelectModel'
                Models={'2DRigid','2DGlobal','2DFixed','2DAffine','2DPerspective'...
                    '3DRigid','3DGlobal','3DFixed','3DAffine','3DPerspective'};
                tag=get(gcbo,'tag');
                idx=1;
                for j=1:length(Models)
                    if not(strcmp(tag,Models{j}))
                        otag(idx)=findobj(gcbf,'tag',Models{j});
                        idx=idx+1;
                    end
                end
                set(otag,'value',0,'backgroundcolor',blueish)
                set(gcbo,'backgroundcolor',gray,'value',1);
                userdat=get(gcbf,'userdata');
                userdat.RegModel=get(gcbo,'userdata');
                set(gcbf,'userdata',userdat);
                
            case 'ScaleChoice'
                Which=varargin{2};
                val=get(gcbo,'value');
                userdat=get(gcbf,'userdata');
                if strcmp(Which,'STD')
                    if val==1
                        set(findobj(gcbf,'tag','STDthresholdPerc'),'enable','on');
                        set(findobj(gcbf,'tag','STDthresholdRaw'),'enable','off');
                        set(gcbo,'string','(%)')
                        userdat.STDThreshold=1;
                    else
                        set(findobj(gcbf,'tag','STDthresholdPerc'),'enable','off');
                        set(findobj(gcbf,'tag','STDthresholdRaw'),'enable','on');
                        set(gcbo,'string','(Raw)')
                        userdat.STDThreshold=0;
                    end
                else
                    if val==1
                        set(findobj(gcbf,'tag','RESthresholdPerc'),'enable','on');
                        set(findobj(gcbf,'tag','RESthresholdRaw'),'enable','off');
                        set(gcbo,'string','(%)')
                        userdat.RESThreshold=1;
                    else
                        set(findobj(gcbf,'tag','RESthresholdPerc'),'enable','off');
                        set(findobj(gcbf,'tag','RESthresholdRaw'),'enable','on');
                        set(gcbo,'string','(Raw)')
                        userdat.RESThreshold=0;
                    end
                end
                set(gcbf,'userdata',userdat);
                
            case 'UpdateSegm'
                % Segmentation window value updates
                userdat=get(gcbf,'userdata');
                fig=userdat.parent;
                Who=varargin{2};
                parentdat=get(fig,'userdata');
                parentdat.Direction=0;
                if strcmp(Who,'STD')
                    val=get(findobj(gcbf,'tag','STDsegm'),'string');
                    set(findobj(fig,'tag','STDpartitions'),'string',val,'userdata',str2num(val));
                    parentdat.STDpartitions=str2num(val);
                else
                    val=get(findobj(gcbf,'tag','RESsegm'),'string');
                    set(findobj(fig,'tag','RESpartitions'),'string',val,'userdata',str2num(val));
                    parentdat.RESpartitions=str2num(val);
                end
                set(fig,'userdata',parentdat);
                
            case 'DirChoice'
                % Choice of fit direction (Direction selection window)
                val=varargin{2};
                userdat=get(gcbf,'userdata');
                fig=userdat.parent;
                userdat=get(fig,'userdata');
                userdat.Direction=val;
                set(findobj(gcbf,'style','radiobutton'),'value',0);
                set(gcbo,'value',1);
                if val==1
                    set(findobj(fig,'tag','STDpartitions'),'string','1','userdata',1);
                    set(findobj(fig,'tag','RESpartitions'),'string','1','userdata',1);
                elseif val==2
                    set(findobj(fig,'tag','STDpartitions'),'string','1','userdata',1);
                    set(findobj(fig,'tag','RESpartitions'),'string','0','userdata',0);
                elseif val==3
                    set(findobj(fig,'tag','STDpartitions'),'string','0','userdata',0);
                    set(findobj(fig,'tag','RESpartitions'),'string','1','userdata',1);
                end
                set(fig,'userdat',userdat);
                delete(gcbf);
                
            case 'SegmChoice'
                % Segmentation choice between 3 modes
                val=varargin{2};
                if val==1
                    set(findobj(gcbf,'tag','RESsegm'),'string','0','userdata',0,'enable','inactive');
                    set(findobj(gcbf,'tag','STDsegm'),'string','256','userdata',256,'enable','on');
                    set(findobj(gcbf,'style','radiobutton'),'value',0);
                    set(gcbo,'value',1);
                elseif val==2
                    set(findobj(gcbf,'tag','RESsegm'),'string','256','userdata',256,'enable','on');
                    set(findobj(gcbf,'tag','STDsegm'),'string','0','userdata',0,'enable','inactive');
                    set(findobj(gcbf,'style','radiobutton'),'value',0);
                    set(gcbo,'value',1);
                else
                    set(findobj(gcbf,'tag','RESsegm'),'string','256','userdata',256,'enable','on');
                    set(findobj(gcbf,'tag','STDsegm'),'string','256','userdata',256,'enable','on');
                    set(findobj(gcbf,'style','radiobutton'),'value',0);
                    set(gcbo,'value',1);
                end
                Align('UpdateSegm','RES');
                Align('UpdateSegm','STD');
                
            case 'AlignNow'
                userdat=get(gcbf,'userdata');
                STD=get(findobj(gcbf,'tag','STDfilename'),'string');
                RES=get(findobj(gcbf,'tag','RESfilename'),'string');
                if not(isempty(STD)) & not(isempty(RES))
                    str=CompileString(gcbf);
                    [stat,message]=unix(str);
                    if not(stat==0);
                        disp([userdat.AlignmentProgram ' terminated in error!']);
                        framecolor=[239 250 255]/255;
                        h=figure('numbertitle','off','menubar','none','units', ...
                            'normalized','position',[0.1 0.1 0.4 0.7],'name','Goofup!');
                        errstr='Errors from the operating system:';
                        errstr=sprintf('%s\n\n%s',errstr,message);
                        errstr=sprintf('%s\n\n%s',errstr,'While runnning the command');
                        errstr=sprintf('%s\n\n%s',errstr,str);
                        uicontrol('parent',h,'units','normalized','position',...
                            [0 0 1 1],'style','text','fontweight','bold',...
                            'fontsize',12,'horizontalalignment','left',...
                            'string',errstr,'backgroundcolor',framecolor);
                        
                    else
                        % Read in data, make visualisation possible etc.
                        if not(iscell(RES))
                            tmp=RES;
                            RES=cell(1);
                            RES{1}=tmp;
                        end
                        userdat.A=cell(length(RES),1);
                        for j=1:length(RES)
                            Airfile=RES{j};
                            if exist([Airfile '.air'])==2
                                A=ReadAir([Airfile '.air']);
                            else
                                A=[];
                            end
                            userdat.A{j}=A;
                        end
                        set(gcbf,'userdata',userdat);
                        set(findobj(gcbf,'tag','InspectButton'),'enable','on');
                    end
                else
                    disp('Please load some files first....');
                end
            case 'SaveCommand'
                STD=get(findobj(gcbf,'tag','STDfilename'),'string');
                RES=get(findobj(gcbf,'tag','RESfilename'),'string');
                if not(isempty(STD)) & not(isempty(RES))
                    Str=CompileString(gcbf);
                    [File Path]=uiputfile('*.com','Select commandfile name');
                    if not(File==0)
                        Str=sprintf('%s\n%s','#!/bin/sh',Str);
                        if isempty(strfind(File,'.'));
                            File=[File '.com'];
                        end
                        [fid,message]=fopen(fullfile(Path,File),'w');
                        if not(fid==-1)
                            fprintf(fid,'%s',Str);
                            fclose(fid);
                            unix(['chmod u+x ' fullfile(Path,File)]);
                        else
                            error(['Problem saving command file:' message]);
                        end
                    else
                        disp('command file save cancelled!');
                    end
                else
                    disp('Please load some files first....');
                end
            case 'Inspect'
                STD=get(findobj(gcbf,'tag','STDfilename'),'string');
                RES=get(findobj(gcbf,'tag','RESfilename'),'string');
                userdat=get(gcbf,'userdata');
                if not(isempty(STD)) & not(isempty(RES))
                    if not(iscell(RES))
                        tmp=RES;
                        RES=cell(1);
                        RES{1}=tmp;
                    end
                    if length(RES)==length(userdat.A)
                        if length(RES)>1
                            [Choice,Ok]=listdlg('PromptString','Reslice file selection',...
                                'SelectionMode','single','ListString',RES);
                            if Ok==1
                                tmp=RES{Choice};
                                RES=cell(1);
                                RES{1}=tmp;
                                A=userdat.A{Choice};
                            else
                                disp('Visualisation cancelled');
                                return
                            end
                        else
                            A=userdat.A{1};
                        end
                    else
                        disp(['You seem to have added / removed Reslice datasets' ...
                            ' since last alignment. Rerun before' ...
                            ' visualising.']);
                        return
                    end
                    [tmp,Airfile]=fileparts(RES{1});
                    if exist([Airfile '.air'])==2
                        DataStruct.A=A;
                        [DataStruct.imgPET,DataStruct.hdrPET]=LoadAnalyze(RES{1},'single');
                        DataStruct.imgPET=reshape(DataStruct.imgPET,DataStruct.hdrPET.dim');
                        [DataStruct.imgMR,DataStruct.hdrMR]=LoadAnalyze(STD,'single');
                        DataStruct.imgMR=reshape(DataStruct.imgMR,DataStruct.hdrMR.dim');
                        feval(userdat.Visualizer,'LoadData',DataStruct);
                    else
                        disp(['I can not find the Air file ' Airfile '. Have you done the registration?']);
                        return
                    end
                else
                    disp('Please load some files first....');
                end
            case 'Close'
                % Check if we have been called in 'batch' mode?
                userdat=get(gcbf,'userdata');
                
                if isfield(userdat,'BatchMode');
                    if isfield(userdat,'A')
                        feval(userdat.ReturnFcn,'ReturningData',userdat.parent,userdat.A);
                    else
                        feval(userdat.ReturnFcn,'ReturningData',userdat.parent,cell(1,1))
                    end
                end
                delete(gcbf);
            otherwise
                error(['Input parameter ' varargin{1} ' does not make sense to me!']);
        end
    else
        error('First parameter must be a ''task'' string');
    end
else
    % This must be non-modular execution:
    files.STD='';
    files.RES='';
    parent=[];
    Align('init',files,parent,'','nruinspect');
    %error('I need input parameters!');
end
set(gcbf,'pointer','arrow')

function h=SetupWindow(files,parent,ReturnFcn,Visualizer);
delth=0.05;
deltv=0.05;
fw=1-2*delth;
fh=(1-4*deltv)/3;
bdh=0.01;
bdv=0.01;
bw=(fw-7*bdh)/6;
bh=(fh-5*bdv)/4;
framecolor=[239 250 255]/255;
butcol=0.7020*ones(1,3);
userdat.files=files; %ADDED by TR120104
userdat.parent=parent;
userdat.Direction=1;
userdat.AlignmentProgram='alignlinear';
userdat.STDRawThreshold=7000;
userdat.STDPercThreshold=10;
userdat.STDThreshold=0;
userdat.STDSmoothX=6;
userdat.STDSmoothY=6;
userdat.STDSmoothZ=6;
userdat.STDpartitions=1;
userdat.RESRawThreshold=7000;
userdat.RESPercThreshold=10;
userdat.RESThreshold=0;
userdat.RESSmoothX=6;
userdat.RESSmoothY=6;
userdat.RESSmoothZ=6;
userdat.RESpartitions=1;
userdat.FileSuffix='.air';
userdat.InitialSampling=81;
userdat.FinalSampling=1;
userdat.DecrementSampling=3;
userdat.CostFunction=1;
userdat.ConvThreshold=1e-5;
userdat.IterationsTotal=25;
userdat.IterationsImprove=5;
userdat.RegModel=6;
userdat.Visualizer=Visualizer;
userdat.ReturnFcn=ReturnFcn;
if not(isempty(ReturnFcn))
    userdat.BatchMode=1;
end

h=figure('units','normalized','name','AIR 5.0 Alignment Tool (Matlab version)',...
    'numbertitle','off','position',[0.2 0.3 0.6 0.6],'menubar',...
    'none','userdat',userdat,'closerequestfcn','Align(''Close'')');

% Frame for common buttons:
uicontrol('units','normalized','style','frame','position',...
    [0 0.55 0.375 0.45],'backgroundcolor',framecolor);
uicontrol('units','normalized','style','frame','position',...
    [0.375 0.55 0.375 0.45],'backgroundcolor',framecolor);
uicontrol('units','normalized','style','frame','position',...
    [0.75 0.55 0.25 0.45],'backgroundcolor',framecolor);

uicontrol('units','normalized','style','frame','position',...
    [0 0.3 0.375 0.25],'backgroundcolor',framecolor);
uicontrol('units','normalized','style','frame','position',...
    [0.375 0.3 0.375 0.25],'backgroundcolor',framecolor);
uicontrol('units','normalized','style','frame','position',...
    [0.75 0.05 0.25 0.5],'backgroundcolor',framecolor);

uicontrol('units','normalized','style','frame','position',...
    [0 0.05 0.375 0.25],'backgroundcolor',framecolor);
uicontrol('units','normalized','style','frame','position',...
    [0.375 0.05 0.375/2 0.25],'backgroundcolor',framecolor);
uicontrol('units','normalized','style','frame','position',...
    [1.5*0.375 0.05 0.375/2 0.25],'backgroundcolor',framecolor);
uicontrol('units','normalized','style','frame','position',...
    [0 0 1 0.05],'backgroundcolor',framecolor);

% "Alignment program" frame:
% Label:
dw=0.01;
dh=0.01;
bh=0.03;
bw=(0.375-3*dw)/2;
uicontrol('units','normalized','style','text','string',...
    'Alignment Program:','fontweight','bold','position',...
    [dw 1-dh-bh bw bh],'horizontalalignment','left', ...
    'backgroundcolor',framecolor);
% Program "box"
uicontrol('units','normalized','style','edit','string',...
    'alignlinear','position',...
    [2*dw+bw 1-dh-bh bw bh] ,'horizontalalignment','left','userdata','alignlinear',...
    'callback','Align(''CheckAlignmentProgram'')','tag','AlignProgram');

% STD label:
uicontrol('units','normalized','style','text','string',...
    'Standard File:','fontweight','bold','position',...
    [dw 1-4*dh-4*bh bw bh],'horizontalalignment','left', ...
    'backgroundcolor',framecolor);

% STD selector:
uicontrol('units','normalized','style','pushbutton','string',...
    'Select...','position',...
    [dw 1-5*dh-5*bh bw/3 bh],'callback','Align(''SelectSTD'')',...
    'tag','SelectSTD');

% STD filename:
uicontrol('units','normalized','style','edit','string',...
    files.STD,'position',...
    [2*dw+bw/3 1-5*dh-5*bh 5*bw/3 bh],'tag','STDfilename','enable','inactive');

% Treshold label:
uicontrol('units','normalized','style','text','string',...
    'threshold:','fontweight','bold','position',...
    [dw 1-8*dh-8*bh bw/2 bh],'horizontalalignment','left', ...
    'backgroundcolor',framecolor);

% Treshold switch:
uicontrol('units','normalized','style','togglebutton','string',...
    '(Raw)','fontweight','bold','position',...
    [dw+bw/2 1-8*dh-8*bh bw/2 bh],...
    'backgroundcolor',framecolor,'CallBack','Align(''ScaleChoice'',''STD'')',...
    'tag','STDscale');

% Treshold box1:
uicontrol('units','normalized','style','edit','string',...
    '7000','position',...
    [2*dw+bw 1-8*dh-8*bh bw/2 bh],'horizontalalignment','left',...
    'userdata',7000,'callback','Align(''CheckValue'',''STDRawThreshold'')','tag','STDthresholdRaw');

% Treshold box2:
uicontrol('units','normalized','style','edit','string',...
    '10','position',...
    [2*dw+1.5*bw 1-8*dh-8*bh bw/2 bh],'horizontalalignment','left',...
    'userdata',10,'callback','Align(''CheckValue'',''STDPercThreshold'')','tag','STDthresholdPerc',...
    'enable','off');

% Partition label:
uicontrol('units','normalized','style','text','string',...
    'partitions:','fontweight','bold','position',...
    [dw 1-9*dh-9*bh bw bh],'horizontalalignment','left', ...
    'backgroundcolor',framecolor);

% Partition box:
uicontrol('units','normalized','style','edit','string',...
    '1','position',...
    [2*dw+bw 1-9*dh-9*bh bw bh],'horizontalalignment','left',...
    'userdata',1,'callback','Align(''CheckValue'',''STDpartitions'')','tag','STDpartitions','enable','inactive');

% Smoothing label(s):
uicontrol('units','normalized','style','text','string',...
    'smoothing (mm):','fontweight','bold','position',...
    [dw 1-10*dh-10*bh bw bh],'horizontalalignment','left', ...
    'backgroundcolor',framecolor);
uicontrol('units','normalized','style','text','string',...
    'x:','fontweight','bold','position',...
    [2*dw+bw 1-10*dh-10*bh bw/3 bh],'backgroundcolor',framecolor);
uicontrol('units','normalized','style','text','string',...
    'y:','fontweight','bold','position',...
    [2*dw+bw+bw/3 1-10*dh-10*bh bw/3 bh],'backgroundcolor',framecolor);
uicontrol('units','normalized','style','text','string',...
    'z:','fontweight','bold','position',...
    [2*dw+bw+2*bw/3 1-10*dh-10*bh bw/3 bh],'backgroundcolor',framecolor);


% Smoothing boxes:
uicontrol('units','normalized','style','edit','string',...
    '','position',...
    [2*dw+bw 1-11*dh-11*bh bw/3 bh],...
    'string','6.0','userdata',6.0,'callback','Align(''CheckValue'',''STDSmoothX'')','tag','STDsmoothx');
uicontrol('units','normalized','style','edit','string',...
    '','position',...
    [2*dw+bw+bw/3 1-11*dh-11*bh bw/3 bh],...
    'string','6.0','userdata',6.0,'callback','Align(''CheckValue'',''STDSmoothY'')','tag','STDsmoothy');
uicontrol('units','normalized','style','edit','string',...
    '','position',...
    [2*dw+bw+2*bw/3 1-11*dh-11*bh bw/3 bh],...
    'string','6.0','userdata',6.0,'callback','Align(''CheckValue'',''STDSmoothZ'')','tag','STDsmoothz');


% RES frame:
woffset=0.375;

% Label:
uicontrol('units','normalized','style','text','string',...
    'File(s) to Align','fontweight','bold','position',...
    [woffset+2*dw+bw 1-dh-bh bw bh],'backgroundcolor',framecolor);
% Add button:
uicontrol('units','normalized','style','pushbutton','string',...
    'Add...','fontweight','bold','position',...
    [woffset+dw 1-2*dh-2*bh bw bh],'callback','Align(''AddRES'')','tag','AddRES');

% Remove button:
uicontrol('units','normalized','style','pushbutton','string',...
    'Remove','fontweight','bold','position',...
    [woffset+dw 1-3*dh-3*bh bw bh],'callback','Align(''RemoveRES'')','tag','RemoveRES');

% Filename list:
uicontrol('units','normalized','style','listbox','string',...
    files.RES,'position',[woffset+2*dw+bw 1-7*dh-7*bh bw 6*bh+5*dh],'tag','RESfilename');


% Treshold label:
uicontrol('units','normalized','style','text','string',...
    'threshold:','fontweight','bold','position',...
    [woffset+dw 1-8*dh-8*bh bw bh],'horizontalalignment','left', ...
    'backgroundcolor',framecolor);

% Treshold switch:
uicontrol('units','normalized','style','togglebutton','string',...
    '(Raw)','fontweight','bold','position',...
    [woffset+dw+bw/2 1-8*dh-8*bh bw/2 bh],...
    'backgroundcolor',framecolor,'CallBack','Align(''ScaleChoice'',''RES'')',...
    'tag','RESscale');

% Treshold box1:
uicontrol('units','normalized','style','edit','string',...
    '7000','position',...
    [woffset+2*dw+bw 1-8*dh-8*bh bw/2 bh],'horizontalalignment','left',...
    'userdata',7000,'callback','Align(''CheckValue'',''RESRawThreshold'')','tag','RESthresholdRaw');

% Treshold box2:
uicontrol('units','normalized','style','edit','string',...
    '10','position',...
    [woffset+2*dw+1.5*bw 1-8*dh-8*bh bw/2 bh],'horizontalalignment','left',...
    'userdata',10,'callback','Align(''CheckValue'',''RESPercThreshold'')','tag','RESthresholdPerc',...
    'enable','off');

% Partition label:
uicontrol('units','normalized','style','text','string',...
    'partitions:','fontweight','bold','position',...
    [woffset+dw 1-9*dh-9*bh bw bh],'horizontalalignment','left', ...
    'backgroundcolor',framecolor);

% Partition box:
uicontrol('units','normalized','style','edit','string',...
    '1','position',...
    [woffset+2*dw+bw 1-9*dh-9*bh bw bh],'horizontalalignment','left',...
    'userdata',1,'callback','Align(''CheckValue'',''RESpartitions'')','tag','RESpartitions','enable','inactive');

% Smoothing label(s):
uicontrol('units','normalized','style','text','string',...
    'smoothing (mm):','fontweight','bold','position',...
    [woffset+dw 1-10*dh-10*bh bw bh],'horizontalalignment','left', ...
    'backgroundcolor',framecolor);
uicontrol('units','normalized','style','text','string',...
    'x:','fontweight','bold','position',...
    [woffset+2*dw+bw 1-10*dh-10*bh bw/3 bh],'backgroundcolor',framecolor);
uicontrol('units','normalized','style','text','string',...
    'y:','fontweight','bold','position',...
    [woffset+2*dw+bw+bw/3 1-10*dh-10*bh bw/3 bh],'backgroundcolor',framecolor);
uicontrol('units','normalized','style','text','string',...
    'z:','fontweight','bold','position',...
    [woffset+2*dw+bw+2*bw/3 1-10*dh-10*bh bw/3 bh],'backgroundcolor',framecolor);


% Smoothing boxes:
uicontrol('units','normalized','style','edit','string',...
    '','position',...
    [woffset+2*dw+bw 1-11*dh-11*bh bw/3 bh],...
    'string','6.0','userdata',6.0,'callback','Align(''CheckValue'',''RESSmoothX'')','tag','RESsmoothx');
uicontrol('units','normalized','style','edit','string',...
    '','position',...
    [woffset+2*dw+bw+bw/3 1-11*dh-11*bh bw/3 bh],...
    'string','6.0','userdata',6.0,'callback','Align(''CheckValue'',''RESSmoothY'')','tag','RESsmoothy');
uicontrol('units','normalized','style','edit','string',...
    '','position',...
    [woffset+2*dw+bw+2*bw/3 1-11*dh-11*bh bw/3 bh],...
    'string','6.0','userdata',6.0,'callback','Align(''CheckValue'',''RESSmoothZ'')','tag','RESsmoothz');

% Ouptput file frame:
woffset=0.75;
bw=(0.25-3*dw)/2;

% Label:
uicontrol('units','normalized','style','text','string',...
    'Output File(s)','fontweight','bold','position',...
    [woffset+dw 1-dh-bh 2*bw+dw bh],'backgroundcolor',framecolor);

% Suffix label:
uicontrol('units','normalized','style','text','string',...
    '.air file suffix:','fontweight','bold','position',...
    [woffset+dw 1-2*dh-2*bh bw bh],'backgroundcolor',framecolor);

% Suffix box:
uicontrol('units','normalized','style','edit','string',...
    '.air','position',[woffset+2*dw+bw 1-2*dh-2*bh bw bh],...
    'HorizontalAlignment','left','tag','Suffix');

% Align button:
uicontrol('units','normalized','style','edit','string',...
    '.air','position',...
    [woffset+2*dw+bw 1-2*dh-2*bh bw bh]);


% Save cmd button:
uicontrol('units','normalized','style','pushbutton','string',...
    'Align Now','position',...
    [woffset+dw 1-5*dh-5*bh 2*bw+dw 3*bh+2*dh],'callback','Align(''AlignNow'')');

uicontrol('units','normalized','style','pushbutton','string',...
    'Save Command File...','position',...
    [woffset+dw 1-8*dh-8*bh 2*bw+dw 3*bh+2*dh],'callback','Align(''SaveCommand'')');

uicontrol('units','normalized','style','pushbutton','string',...
    'Inspect result','position',...
    [woffset+dw 1-11*dh-11*bh 2*bw+dw 3*bh+2*dh], ...
    'callback','Align(''Inspect'')','tag','InspectButton','enable','off');




% Modality frame:
woffset=0;
bw=(0.375-3*dw)/2;
% Modality label:
uicontrol('units','normalized','style','text','string',...
    'Modality','fontweight','bold','position',...
    [woffset+dw 0.55-dh-bh 2*bw+dw bh],'backgroundcolor',framecolor);


% Intra togglebutton
uicontrol('units','normalized','style','togglebutton','string',...
    'Intramodality (e.g. PET-PET)','fontweight','bold','position',...
    [woffset+dw 0.55-4*dh-4*bh 2*bw+dw bh],'backgroundcolor',butcol,...
    'horizontalalignment','left','tag','Intra','value',1,...
    'CallBack','Align(''ModalityChange'')');


% Inter togglebutton
uicontrol('units','normalized','style','togglebutton','string',...
    'Intermodality (e.g. MRI-PET)','fontweight','bold','position',...
    [woffset+dw 0.55-5*dh-5*bh 2*bw+dw bh],'backgroundcolor',framecolor,...
    'horizontalalignment','left','tag','Inter','value',0,...
    'CallBack','Align(''ModalityChange'')');

% Sampling frame:
woffset=0.375;
% Sampling label:
uicontrol('units','normalized','style','text','string',...
    'Sampling','fontweight','bold','position',...
    [woffset+dw 0.55-dh-bh 2*bw+dw bh],'backgroundcolor',framecolor);


% initial label
uicontrol('units','normalized','style','text','string',...
    'Initial','fontweight','bold','position',...
    [woffset+dw 0.55-4*dh-4*bh bw/2 bh],'backgroundcolor',framecolor,...
    'horizontalalignment','left');

% initial box
uicontrol('units','normalized','style','edit','string',...
    '81','position',...
    [woffset+dw+bw/2 0.55-4*dh-4*bh bw/2 bh],'userdata',81,'callback','Align(''CheckValue'',''InitialSampling'')',...
    'tag','SamplingInitial');

% final label
uicontrol('units','normalized','style','text','string',...
    'Final','fontweight','bold','position',...
    [woffset+2*dw+bw 0.55-4*dh-4*bh bw/2 bh],'backgroundcolor',framecolor,...
    'horizontalalignment','left');

% final box
uicontrol('units','normalized','style','edit','string',...
    '1','position',...
    [woffset+2*dw+bw+bw/2 0.55-4*dh-4*bh bw/2 bh],'userdata',1,'callback','Align(''CheckValue'',''FinalSampling'')',...
    'tag','SamplingFinal');

% decrement label
uicontrol('units','normalized','style','text','string',...
    'Decrement by factors of:','fontweight','bold','position',...
    [woffset+dw 0.55-5*dh-5*bh bw bh],'backgroundcolor',framecolor,...
    'horizontalalignment','left');

% decrement box
uicontrol('units','normalized','style','edit','string',...
    '3','position',...
    [woffset+2*dw+bw+bw/2 0.55-5*dh-5*bh bw/2 bh],'userdata',3,'callback','Align(''CheckValue'',''DecrementSampling'')',...
    'tag','SamplingDecrement');

% Model frame:
woffset=0.75;
bw1=(0.25-2*dw)/4;
bw2=0.25-bw1-2*dw;
% 2D models:
uicontrol('units','normalized','style','togglebutton','string',...
    'Rigid Body','fontweight','bold','position',...
    [woffset+dw+bw1 0.55-2*dh-2*bh bw2 bh],'backgroundcolor',framecolor,...
    'horizontalalignment','left','callback','Align(''SelectModel'')','tag','2DRigid','userdata',23);
uicontrol('units','normalized','style','togglebutton','string',...
    'Global Rescaling','fontweight','bold','position',...
    [woffset+dw+bw1 0.55-3*dh-3*bh bw2 bh],'backgroundcolor',framecolor,...
    'horizontalalignment','left','callback','Align(''SelectModel'')','tag','2DGlobal','userdata',24);
uicontrol('units','normalized','style','togglebutton','string',...
    'Fixed Area','fontweight','bold','position',...
    [woffset+dw+bw1 0.55-4*dh-4*bh bw2 bh],'backgroundcolor',framecolor,...
    'horizontalalignment','left','callback','Align(''SelectModel'')','tag','2DFixed','userdata',25);
uicontrol('units','normalized','style','text','string',...
    '2D','fontweight','bold','position',...
    [woffset+dw 0.55-4*dh-4*bh bw1 bh],'backgroundcolor',framecolor);
uicontrol('units','normalized','style','togglebutton','string',...
    'Affine','fontweight','bold','position',...
    [woffset+dw+bw1 0.55-5*dh-5*bh bw2 bh],'backgroundcolor',framecolor,...
    'horizontalalignment','left','callback','Align(''SelectModel'')','tag','2DAffine','userdata',26);
uicontrol('units','normalized','style','togglebutton','string',...
    'Perspective','fontweight','bold','position',...
    [woffset+dw+bw1 0.55-6*dh-6*bh bw2 bh],'backgroundcolor',framecolor,...
    'horizontalalignment','left','callback','Align(''SelectModel'')','tag','2DPerspective','userdata',28);

% 3D models:
uicontrol('units','normalized','style','togglebutton','string',...
    'Rigid Body','fontweight','bold','position',...
    [woffset+dw+bw1 0.55-8*dh-8*bh bw2 bh],'backgroundcolor',butcol,...
    'horizontalalignment','left','value',1,'callback','Align(''SelectModel'')','tag','3DRigid','userdata',6);
uicontrol('units','normalized','style','togglebutton','string',...
    'Global Rescaling','fontweight','bold','position',...
    [woffset+dw+bw1 0.55-9*dh-9*bh bw2 bh],'backgroundcolor',framecolor,...
    'horizontalalignment','left','callback','Align(''SelectModel'')','tag','3DGlobal','userdata',7);
uicontrol('units','normalized','style','togglebutton','string',...
    'Fixed Area','fontweight','bold','position',...
    [woffset+dw+bw1 0.55-10*dh-10*bh bw2 bh],'backgroundcolor',framecolor,...
    'horizontalalignment','left','callback','Align(''SelectModel'')','tag','3DFixed','userdata',9);
uicontrol('units','normalized','style','text','string',...
    '3D','fontweight','bold','position',...
    [woffset+dw 0.55-10*dh-10*bh bw1 bh],'backgroundcolor',framecolor);
uicontrol('units','normalized','style','togglebutton','string',...
    'Affine','fontweight','bold','position',...
    [woffset+dw+bw1 0.55-11*dh-11*bh bw2 bh],'backgroundcolor',framecolor,...
    'horizontalalignment','left','callback','Align(''SelectModel'')','tag','3DAffine','userdata',12);
uicontrol('units','normalized','style','togglebutton','string',...
    'Perspective','fontweight','bold','position',...
    [woffset+dw+bw1 0.55-12*dh-12*bh bw2 bh],'backgroundcolor',framecolor,...
    'horizontalalignment','left','callback','Align(''SelectModel'')','tag','3DPerspective','userdata',15);


% Cost function frame:
woffset=0;
bw=(0.375-3*dw)/2;

% Cost label:
uicontrol('units','normalized','style','text','string',...
    'Cost Function','fontweight','bold','position',...
    [woffset+dw 0.3-dh-bh 2*bw+dw bh],'backgroundcolor',framecolor);

% Cost switches:
uicontrol('units','normalized','style','togglebutton','string',...
    'Standard Deviation of Ratio Image','fontweight','bold','position',...
    [woffset+dw 0.3-3*dh-3*bh 2*bw+dw bh],'backgroundcolor',butcol,...
    'Horizontalalignment','left','value',1,'tag','CostSDRI','callback','Align(''CostChange'')','userdata',1);
uicontrol('units','normalized','style','togglebutton','string',...
    'Least Squares of Difference Image','fontweight','bold','position',...
    [woffset+dw 0.3-4*dh-4*bh 2*bw+dw bh],'backgroundcolor',framecolor,...
    'Horizontalalignment','left','tag','CostLSDI','callback','Align(''CostChange'')','userdata',2);
uicontrol('units','normalized','style','togglebutton','string',...
    'Least Squares with Intensity Rescaling','fontweight','bold','position',...
    [woffset+dw 0.3-5*dh-5*bh 2*bw+dw bh],'backgroundcolor',framecolor,...
    'Horizontalalignment','left','tag','CostLSIR','callback','Align(''CostChange'')','userdata',3);

% Convergence frame
% Convergence label:
woffset=0.375;
bw=(0.375/2-3*dw)/2;
uicontrol('units','normalized','style','text','string',...
    'Convergence Threshold','fontweight','bold','position',...
    [woffset+dw 0.3-dh-bh 2*bw+dw bh],'backgroundcolor',framecolor);

uicontrol('units','normalized','style','edit','string',...
    '.00001','position',...
    [woffset+dw 0.3-3*dh-3*bh 2*bw+dw bh],'userdata','0.0001','callback','Align(''CheckValue'',''ConvThreshold'')',...
    'tag','ConvThreshold');

% Iteration frame
% Iteration  label:
woffset=1.5*0.375;
bw=(0.375/2-3*dw)/2;
uicontrol('units','normalized','style','text','string',...
    'Iterations (pr. samp.)','fontweight','bold','position',...
    [woffset+dw 0.3-dh-bh 2*bw+dw bh],'backgroundcolor',framecolor);

uicontrol('units','normalized','style','text','string',...
    'Total','fontweight','bold','position',...
    [woffset+dw 0.3-3*dh-3*bh bw bh],'backgroundcolor',framecolor,'Horizontalalignment','left');

uicontrol('units','normalized','style','edit','string',...
    '25','position',...
    [woffset+2*dw+1.5*bw 0.3-3*dh-3*bh bw/2 bh],'Horizontalalignment','left',...
    'userdata',25,'callback','Align(''CheckValue'',''IterationsTotal'')','tag','IterationsTotal');

uicontrol('units','normalized','style','text','string',...
    'Without improvement','fontweight','bold','position',...
    [woffset+dw 0.3-5*dh-5*bh 1.5*bw 2*bh+dh],'backgroundcolor',framecolor,'Horizontalalignment','left');

uicontrol('units','normalized','style','edit','string',...
    '5','position',...
    [woffset+2*dw+1.5*bw 0.3-4*dh-4*bh bw/2 bh],'Horizontalalignment','left',...
    'userdata',5,'callback','Align(''CheckValue'',''IterationsImprove'')','tag','IterationsImprovement');


% Program flags frame:
woffset=0;
bw1=(1-3*dw)/4;
bw2=3*bw1;
% Label:
uicontrol('units','normalized','style','text','string',...
    'Additional program flags:','fontweight','bold','position',...
    [woffset+dw dh bw1 bh],'backgroundcolor',framecolor,...
    'Horizontalalignment','left');
uicontrol('units','normalized','style','edit','string',...
    '','position',...
    [woffset+2*dw+bw1 dh bw2 bh],...
    'Horizontalalignment','left','tag','ExtraFlags');



function Str=CompileString(fig)
% Compile the unix commandline string to call alignment program
% with
Str='';
STDfile=get(findobj(fig,'tag','STDfilename'),'string');
RESfile=get(findobj(fig,'tag','RESfilename'),'string');
if not(iscell(RESfile))
    tmp=RESfile;
    RESfile=cell(1);
    RESfile{1}=tmp;
end
ExtraFlags=get(findobj(fig,'tag','ExtraFlags'),'string');
userdat=get(gcbf,'userdata');
if not(userdat.STDThreshold==0)
    % We'll have to read in the dataset to determine the
    % STD threshold
    disp(['Loading in ' STDfile ' to determine thresholds... Have patience...']);
    img=ReadAnalyzeImg(STDfile,'raw');
    Min=double(min(img));
    Max=double(max(img));
    userdat.STDRawThreshold=round(Min+userdat.STDPercThreshold*(Max-Min)/100);
end
for j=1:length(RESfile)
    RESfilej=RESfile{j};
    if not(userdat.RESThreshold==0)
        % We'll have to read in the dataset to determine the
        % RES threshold
        disp(['Loading in ' RESfilej ' to determine thresholds... Have patience...']);
        img=ReadAnalyzeImg(RESfilej,'raw');
        Min=double(min(img));
        Max=double(max(img));
        userdat.RESRawThreshold=round(Min+userdat.RESPercThreshold*(Max-Min)/100);
    end
    clear img;
    % Command to run:
    str=[userdat.AlignmentProgram ' ' ExtraFlags];
    % Standard file / Reslice file / Air file (in pwd):
    Airfile=RESfilej;
    str=[str ' ' STDfile ' ' RESfilej ' ' Airfile userdat.FileSuffix];
    % Registration model number:
    str=[str ' -m ' num2str(userdat.RegModel)];
    % Thresholds:
    str=[str ' -t1 ' num2str(userdat.STDRawThreshold) ...
        ' -t2 ' num2str(userdat.RESRawThreshold)];
    % Smoothing parameters, STD:
    str=[str ' -b1 ' num2str(userdat.STDSmoothX) ' ' ...
        num2str(userdat.STDSmoothY) ' ' ...
        num2str(userdat.STDSmoothZ)];
    % Smoothing parameters, RES:
    str=[str ' -b1 ' num2str(userdat.RESSmoothX) ' ' ...
        num2str(userdat.RESSmoothY) ' ' ...
        num2str(userdat.RESSmoothZ)];
    % Segmentation parameters:
    str=[str ' -p1 ' num2str(userdat.STDpartitions) ...
        ' -p2 ' num2str(userdat.RESpartitions)];
    % The following options to alignlinear are not available
    % through the user interface
    % -e? -f -g -w -fs -gs -ws -a -q -v -z
    
    % Sampling stuff
    str=[str ' -s ' num2str(userdat.InitialSampling) ...
        ' ' num2str(userdat.FinalSampling) ...
        ' ' num2str(userdat.DecrementSampling)];
    % Convergence threshold:
    str=[str ' -c ' num2str(userdat.ConvThreshold)];
    % Iterations:
    str=[str ' -r ' num2str(userdat.IterationsTotal) ...
        ' -h ' num2str(userdat.IterationsImprove)];
    % Cost function
    str=[str ' -x ' num2str(userdat.CostFunction)];
    Str=sprintf('%s%s\n',Str,str);
end

function fig=InterChoice(parent)
userdat.parent=parent;
figcol=[239 250 255]/255;
butcol=0.7020*ones(1,3);
parentdat=get(parent,'userdata');
RESpartitions=parentdat.RESpartitions;
STDpartitions=parentdat.STDpartitions;
if RESpartitions==1 & STDpartitions==1;
    parentdat.Direction=0;
    RESpartitions=256;
    STDpartitions=0;
    
end
if RESpartitions==0
    state=1;
elseif STDpartitions==0
    state=2;
else
    state=3;
end
parentdat.RESpartitions=RESpartitions;
parentdat.STDpartitions=STDpartitions;
fig=figure('units','normalized','position',[0.1 0.6 0.4 0.25],...
    'numbertitle','off','menubar','none','name',...
    'Segmentation Selection','color',figcol,'userdata',userdat);
uicontrol('units','normalized','style','text','position',[0 0.8 1 0.2],'string',...
    ['Segmentation for intermodality registration is based' ...
    ' solely on image intensity partitioning.'],...
    'backgroundcolor',figcol,'fontweight','bold','FontSize',12,...
    'horizontalalignment','left');
uicontrol('units','normalized','style','text','position',[0 0.6 1 0.2],'string',...
    ['MRI files are best suited for intensity based segmentation '...
    'but may nonetheless require prior editing to remove '...
    'confounding structures such as scalp and skull.'],...
    'backgroundcolor',figcol,'fontweight','bold','FontSize',12,...
    'horizontalalignment','left');
uicontrol('units','normalized','style','text','position',[0 0.5 1 0.1],'string',...
    'Up to 256 partitions are allowed.',...
    'backgroundcolor',figcol,'fontweight','bold','FontSize',12,...
    'horizontalalignment','left');
uicontrol('units','normalized','style','radiobutton','position',[0.1 0.45 0.4 0.1],'string',...
    'Segment standard file',...
    'backgroundcolor',figcol,'fontweight','bold','FontSize',12,...
    'horizontalalignment','left','tag','Radio1','CallBack','Align(''SegmChoice'',1)');
uicontrol('units','normalized','style','radiobutton','position',[0.1 0.35 0.4 0.1],'string',...
    'Segment reslice file',...
    'backgroundcolor',figcol,'fontweight','bold','FontSize',12,...
    'horizontalalignment','left','tag','Radio2','CallBack','Align(''SegmChoice'',2)');
uicontrol('units','normalized','style','radiobutton','position',[0.1 0.25 0.4 0.1],'string',...
    'Segment both files',...
    'backgroundcolor',figcol,'fontweight','bold','FontSize',12,...
    'horizontalalignment','left','tag','Radio3','CallBack','Align(''SegmChoice'',3)');
uicontrol('units','normalized','style','text','position',[0 0.1 0.3 0.1],'string',...
    'Standard file partitons:',...
    'backgroundcolor',figcol,'fontweight','bold','FontSize',12,...
    'horizontalalignment','left');
uicontrol('units','normalized','style','text','position',[0 0 0.3 0.1],'string',...
    'Reslice file partitons:',...
    'backgroundcolor',figcol,'fontweight','bold','FontSize',12,...
    'horizontalalignment','left');
uicontrol('units','normalized','style','edit','position',[0.3 0.1 0.1 0.1],'string',...
    num2str(STDpartitions),'FontSize',12,...
    'horizontalalignment','left','userdata',STDpartitions,'tag','STDsegm','Callback','Align(''CheckValue'',''dummy'',''UpdateSegm'',''STD'');');
uicontrol('units','normalized','style','edit','position',[0.3 0 0.1 0.1],'string',...
    num2str(RESpartitions),'FontSize',12,...
    'horizontalalignment','left','userdata',RESpartitions,'tag','RESsegm','Callback','Align(''CheckValue'',''dummy'',''UpdateSegm'',''RES'');');
% 'Done' button:
uicontrol('units','normalized','style','pushbutton','position',[0.7 0.3 0.2 0.15],'string',...
    'Done','FontSize',12,'Callback','close(gcbf)','FontWeight','bold');
set(findobj(fig,'tag',['Radio' num2str(state)]),'value',1);
if state==1
    set(findobj(fig,'tag','RESsegm'),'enable','inactive');
elseif state==2
    set(findobj(fig,'tag','STDsegm'),'enable','inactive');
end
set(findobj(parent,'tag','STDpartitions'),'string',get(findobj(fig,'tag','STDsegm'),'string'));
set(findobj(parent,'tag','RESpartitions'),'string',get(findobj(fig,'tag','RESsegm'),'string'));
set(findobj(parent,'tag','CostLSDI'),'enable','off','value',0,'backgroundcolor',figcol);
set(findobj(parent,'tag','CostLSIR'),'enable','off','value',0,'backgroundcolor',figcol);
if parentdat.CostFunction>1
    parentdat.CostFunction=1;
    set(findobj(parent,'tag','CostSDRI'),'enable','on','value',1,'backgroundcolor',butcol);
    h=warndlg(['Your cost function has been reset to "Standard' ...
        ' Deviation of Ratio Image" because intermodality' ...
        ' registration using other cost functions is not' ...
        ' avaliable'],'Warning','modal');
    uiwait(h);
end
set(parent,'userdata',parentdat);



function fig=IntraChoice(parent)
userdat.parent=parent;
figcol=[239 250 255]/255;
fig=figure('units','normalized','position',[0.1 0.7 0.4 0.15],...
    'numbertitle','off','menubar','none','name',...
    'Direction Selection','color',figcol,'userdata',userdat);
uicontrol('units','normalized','style','text','position',[0 0.8 1 0.2],'string',...
    ['Bidirectional fits are generally recommended.'],...
    'backgroundcolor',figcol,'fontweight','bold','FontSize',12,...
    'horizontalalignment','left');
uicontrol('units','normalized','style','text','position',[0 0.6 1 0.2],'string',...
    ['However, if you have edited the standard file to remove areas of pathology '...
    'that you think will interfere with registration, choose "Forward fit".'],...
    'backgroundcolor',figcol,'fontweight','bold','FontSize',12,...
    'horizontalalignment','left');
uicontrol('units','normalized','style','text','position',[0 0.4 1 0.2],'string',...
    'Likewise, if you have edited the reslice files to remove pathology, choose "Reverse fit".',...
    'backgroundcolor',figcol,'fontweight','bold','FontSize',12,...
    'horizontalalignment','left');
uicontrol('units','normalized','style','radiobutton','position',[0.3 0.3 0.4 0.1],'string',...
    'Bidirectional fit',...
    'backgroundcolor',figcol,'fontweight','bold','FontSize',12,...
    'horizontalalignment','left','value',1,'tag','Radio1','CallBack','Align(''DirChoice'',1)');
uicontrol('units','normalized','style','radiobutton','position',[0.3 0.2 0.4 0.1],'string',...
    'Forward fit',...
    'backgroundcolor',figcol,'fontweight','bold','FontSize',12,...
    'horizontalalignment','left','tag','Radio2','CallBack','Align(''DirChoice'',2)');
uicontrol('units','normalized','style','radiobutton','position',[0.3 0.1 0.4 0.1],'string',...
    'Reverse fit',...
    'backgroundcolor',figcol,'fontweight','bold','FontSize',12,...
    'horizontalalignment','left','tag','Radio3','CallBack','Align(''DirChoice'',3)');
set(findobj(parent,'tag','STDpartitions'),'string','1','userdata',1);
set(findobj(parent,'tag','RESpartitions'),'string','1','userdata',1);
set(findobj(parent,'tag','CostLSDI'),'enable','on');
set(findobj(parent,'tag','CostLSIR'),'enable','on');

