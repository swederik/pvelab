function varargout=Coreg(varargin)
% Interactive Image Overlay (IIO) a manual method for co-registration (6-DOF)
% a high resolution MR scan and a low resolution PET/SPECT brain scan.
%
% Note: Before exiting, IIO call a user defined Returnfunction where the co-registration matrix
%       can be retrived.
%
% Different calls of the Coreg function:
%
%       1) FIG_HANDLE=COREG; Initialize GUI and return handle
%
%       2) COREG('BATCH',FIG_HANDLE,FILENAME,PARENT_HANDLE,RETURN_FUCN); setup and return handel to initialized browse2d GUI
%               - FIG_HANDLE: handel to initialized GUI ...
%                             OR an empty handle, FIG_HANDLE=[], a new GUI is then created.
%
%               - FILENAME: structure containing a high resolution MR scan and one or more low resolutions PET/SPECT
%                           given in a cell array. Both images given in the Analyze format.
%                           If structure is empty files shall be selected by the user.
%                     example of structure:
%                            FILENAME.STD: Name and path for high resolution MR scan
%                            FILENAME.RES{}: Name and path of one or more low resolution PET/SEPCT scans
%                            FILENAME.A: If exist, a given co-registration matrix is used as initiated co-registration
%                            FILENAME.AIR: If filename exist, the co-registration matrix is saved in air format
%
%               - PARENT_HANDLE: Figure handle to parent/main figure so it can be found when returning fra Coreg.
%                      example :
%                            PARENT_HANDLE=h_mainfig
%
%               - RETURN_FUCN: Name of function where the co-registration matrix can be retrieved and saved before exiting
%                              the Coreg.
%                      example:
%                           feval('saveMatrix','ReturningData',PARENT_HANDLE,Aall);
%                           where - ReturningData: Parameter telling that co-registration matrix is returned by Coreg
%                                 - Aall contain co-registration matrix
%
% Call special functions:
%   - LoadAnalyze.m
%   - SaveAir.m
%   - ReadAnalyzeHdr.m
%   - ReadAnalyzeImg.m
%   - CheckKey_Coreg.m
%   - cmapsel.m
%   - ReturnA.m
%   - isobj.m
%   - voxa2cuba.m
%   - tala2voxa.m
%   - diffA.m
%
% PW, NRU 2001
%____________________________________________________________________
% Updates:
% - Improve the contrast of the image on the screen, 280103TD, NRU
% - If handle do not exist in 'Batch' mode then create one, 070203TD, NRU
% - Add lower() of varargin{1} when do a 'Batch' check to make it more flexsible, 070203TD, NRU
% - Add 'files' to the struct.UserData, to store information on files used for the co-registration, 110203TD, NRU
% - Add the possibility to save the co-registration matrix in a given air file+path IF a airfile name is given as input, 119293TD, NRU
% - Error corrected: SaveAir do not read A matrix as cell array!010803TD
% - Included keys info window. 071209, PJ

global ENABLE_HACKS

if isempty(varargin)
    % Set up the window
    h=SetupWindow;
    if nargout==1
        varargout{1}=h;
    end
else
    if strcmpi(varargin{1},'batch') % Batch mode, called from 'register'!!! lower(), by TD070203
        fig=varargin{2};
        %_____________________________________________________
        % If fig handle do not exist then create one, 070203TD
        if(isempty(fig))
            fig=SetupWindow;  % Set up the window
        end
        %_____________________________________________________
        files=varargin{3};
        parent=varargin{4};
        userdat=get(fig,'userdata');
        userdat.ReturnFcn=varargin{5};
        userdat.parent=parent;
        userdat.files=files; % Save information on used files, 110203TD
        set(fig,'closerequestfcn','Coreg(''ExitSave'')','userdata',userdat);
        Load('standard',files.STD);
        s=1;
        n=1;
        if iscell(files.RES)
            if length(files.RES)>1
                [s,v] = listdlg('PromptString','Select RES file:',...
                    'SelectionMode','single',...
                    'ListString',files.RES);
                resfile=files.RES{s};
                n=length(files.RES);
            else
                resfile=files.RES{1};
            end
        else
            resfile=files.RES;
        end
        userdat=get(fig,'userdata');
        userdat.ResNumber=s;
        userdat.ResMax=n;
        set(fig,'userdata',userdat);
        Load('reslice',resfile);
        if not(all(all(files.A{s}==diag([1 1 1 1]))))
            Choice=questdlg('Apply transformation parameters from main program?','Apply parameters?');
            if strcmp(Choice,'Yes')
                Coreg('ReturnA',files.A{s});
            end
        end
        %Coreg('SetName',fig,files.STD,files.RES{1});
        Coreg('SetName',fig,files.STD,resfile);%Must more general, 170303TD

    elseif strcmp(varargin{1},'SetName'); % Set window title according to loaded files
        fig=varargin{2};
        [tmp,STD]=fileparts(varargin{3});
        [tmp,RES]=fileparts(varargin{4});
        set(fig,'name',[get(fig,'name') ' |  ' STD '  |  ' RES]);

    elseif strcmp(varargin{1},'ExitSave') % Exit callback for the batch mode
        fig=gcf;
        userdat=get(fig,'userdata');
        A=CalculateA;
        Aall=cell(userdat.ResMax,1);
        Aall{userdat.ResNumber}=A;

        %______________________________________________________________________________
        % Save registration matrix in air-format, 110203TD
        % If a air filename is given
        if(isfield(userdat.files,'AIR'))
            Struct.hdrO=ReadAnalyzeHdr(userdat.files.STD); %And now with STD as output and RES as input 251103TR
            Struct.hdrI=ReadAnalyzeHdr(userdat.files.RES{1});
            if(isempty(userdat.A))%No co-registration!!
                userdat.A=eye(4,4);
            end
            %REMOVED 010803TD: Struct.A=userdat.A;
            Struct.A=A;%Added 010803TD, so SaveAir do work!
            Struct.descr='Saved from IIO';
            message=SaveAir(userdat.files.AIR,Struct);
        end
        %______________________________________________________________________________

        feval(userdat.ReturnFcn,'ReturningData',userdat.parent,Aall);
        set(fig,'closerequestfcn','closereq');
        delete(fig);
        fig2 = findobj('type','figure','name','Keys');
        delete(fig2);

    elseif strcmp(varargin{1},'ReturnA')
        % A movement window is returning a transformation matrix
        fig=findobj('tag','CoregOnline');
        userdat=get(fig,'userdata');
        A=varargin{2};
        if nargin>2
            userdat.TransStep=varargin{3};
            userdat.AngStep=varargin{4};
        end
        if not(isempty(userdat.A))
            if iscell(userdat.A)
                userdat.A{length(userdat.A)+1}=A;
            else
                tmpA=userdat.A;
                userdat.A=cell(2,1);
                userdat.A{1}=tmpA;
                userdat.A{2}=A;
            end
        else
            userdat.A=A;
        end
        set(fig,'userdata',userdat);
        UpdateCuts;
    else
        fig=findobj('tag','CoregOnline');
        userdat=get(fig,'userdata');
        % Set Watch
        set(findobj('tag','CoregOnline'),'pointer','watch');

        switch varargin{1}
            case 'SetAlpha' % Set transparancy
                % Update alpha transparancy value
                userdat=get(gcbf,'userdata');
                userdat.Alpha=get(gcbo,'value');
                if ENABLE_HACKS==1
                    if userdat.Alpha==1
                        userdat.Alpha=1-eps;
                    end
                end
                set(gcbf,'userdata',userdat);
                UpdateCuts;

            case 'AlignCM' % Align Centres of mass
                AlignCM;

            case 'ThresValue' % Adjust threshold value
                val=str2num(get(gcbo,'string'));
                if not(isempty(val))
                    val=max(userdat.resliceMINg,val);
                    val=min(userdat.resliceMAXg,val);
                    userdat.threshold=val;
                    set(gcbo,'string',num2str(val));
                    set(fig,'userdata',userdat);
                    UpdateCuts
                end

            case 'Update' % Update views
                UpdateCuts

            case 'StdMin' % Set STD min value
                val=str2num(get(gcbo,'string'));
                val=max(userdat.standardMINg,val);
                val=min(userdat.standardMAX,val);
                userdat.standardMIN=val;
                set(gcbo,'string',num2str(val));
                set(fig,'userdata',userdat);
                UpdateCuts;

            case 'StdMax' % Set STD max value
                val=str2num(get(gcbo,'string'));
                val=max(userdat.standardMIN,val);
                val=min(userdat.standardMAXg,val);
                userdat.standardMAX=val;
                set(gcbo,'string',num2str(val));
                set(fig,'userdata',userdat);
                UpdateCuts;

            case 'ResMin' % Set RES min value
                val=str2num(get(gcbo,'string'));
                val=max(userdat.resliceMINg,val);
                val=min(userdat.resliceMAX,val);
                userdat.resliceMIN=val;
                set(gcbo,'string',num2str(val));
                set(fig,'userdata',userdat);
                UpdateCuts;

            case 'ResMax' % Set RES max value
                val=str2num(get(gcbo,'string'));
                val=max(userdat.resliceMIN,val);
                val=min(userdat.resliceMAXg,val);
                userdat.resliceMAX=val;
                set(gcbo,'string',num2str(val));
                set(fig,'userdata',userdat);
                UpdateCuts;

            case 'StdCMAP' % STD colormap
                [tmp,userdat.standardCMAP]=cmapsel('',userdat.standardCMAP);
                set(fig,'userdata',userdat);
                UpdateCuts;

            case 'ResCMAP' % RES colormap
                [tmp,userdat.resliceCMAP]=cmapsel('',userdat.resliceCMAP);
                set(fig,'userdata',userdat);
                UpdateCuts;

            case 'ResColor' % RES threshold linecolor
                userdat.threscolor=uisetcolor(userdat.threscolor,'Set threshold linecolor');
                set(fig,'userdata',userdat);
                UpdateCuts;

            case 'XColor' % Crosshair linecolor
                userdat.xcolor=uisetcolor(userdat.xcolor,'Set X linecolor');
                set(fig,'userdata',userdat);
                UpdateCuts;

            case 'ButtonClicked' % General callback
                if nargin==2
                    ButtonClick(varargin{2});
                elseif nargin==3
                    ButtonClick(varargin{2},varargin{3});
                end

            case 'UndoAll' % Undo all transformations
                userdat.A=diag([1 1 1 1]);
                userdat.centre=[];
                set(findobj('tag','CoregOnline'),'userdata',userdat);
                UpdateCuts;

            case 'Undo' % Undo last transformation
                if iscell(userdat.A)
                    lA=length(userdat.A);
                    A=cell(lA-1,1);
                    for j=1:lA-1
                        A{j}=userdat.A{j};
                    end
                else
                    A=diag([1 1 1 1]);
                end
                userdat.A=A;
                userdat.centre=[];
                set(findobj('tag','CoregOnline'),'userdata',userdat);
                UpdateCuts;

            case 'AirfileLoad' % Load an .air file
                disp('Load Airfile')
                LoadAir(varargin{2});

        end
    end
end
set(findobj('tag','CoregOnline'),'pointer','arrow'); % Set pointer back to 'arrow'

function fig=SetupWindow % Set up the window:
fig=figure('numbertitle','off','tag','CoregOnline','units','normalized',...
    'position',[0.05 0.05 0.9 0.9],'name','IIO - Interactive Image Overlay ');


% Heights / Widths of buttons and axes:
bw=0.05;
bh=0.025;
ax1=axes('parent',fig,'position',[0.2 0.5 0.8/3 0.5]);
ax2=axes('parent',fig,'position',[0.2 0 0.8/3 0.5]);
ay1=axes('parent',fig,'position',[0.2+0.8/3 0.5 0.8/3 0.5]);
ay2=axes('parent',fig,'position',[0.2+0.8/3 0 0.8/3 0.5]);
az1=axes('parent',fig,'position',[0.2+2*0.8/3 0.5 0.8/3 0.5]);
az2=axes('parent',fig,'position',[0.2+2*0.8/3 0 0.8/3 0.5]);

% Buttons:
uicontrol('style','pushbutton','parent',fig,'string','CM Alignment','units',...
    'normalized','position',[0 1-bh 2*bw bh],'Callback','Coreg(''AlignCM'')');

uicontrol('style','text','parent',fig,'string','Colormaps:','units',...
    'normalized','position',[0 1-3*bh 2*bw bh],'fontweight','bold');

uicontrol('style','text','parent',fig,'string','Std. Min','units',...
    'normalized','position',[0 1-5*bh bw bh]);

uicontrol('style','edit','parent',fig,'string',num2str(0),'units',...
    'normalized','position',[bw 1-5*bh bw bh],'Callback', ...
    'Coreg(''StdMin'')','tag','standardMin');

uicontrol('style','text','parent',fig,'string','Std. Max','units',...
    'normalized','position',[0 1-6*bh bw bh]);

uicontrol('style','edit','parent',fig,'string',num2str(0),'units',...
    'normalized','position',[bw 1-6*bh bw bh],'Callback', ...
    'Coreg(''StdMax'')','tag','standardMax');

uicontrol('style','pushbutton','parent',fig,'string','Standard CMAP','units',...
    'normalized','position',[0 1-7*bh 2*bw bh],'Callback', ...
    'Coreg(''StdCMAP'')','tag','StdCMAP');

uicontrol('style','text','parent',fig,'string','Res. Min','units',...
    'normalized','position',[0 1-9*bh bw bh]);

uicontrol('style','edit','parent',fig,'string',num2str(0),'units',...
    'normalized','position',[bw 1-9*bh bw bh],'Callback', ...
    'Coreg(''ResMin'')','tag','resliceMin');

uicontrol('style','text','parent',fig,'string','Res. Max','units',...
    'normalized','position',[0 1-10*bh bw bh]);

uicontrol('style','edit','parent',fig,'string',num2str(0),'units',...
    'normalized','position',[bw 1-10*bh bw bh],'Callback', ...
    'Coreg(''ResMax'')','tag','resliceMax');

uicontrol('style','pushbutton','parent',fig,'string','Reslice CMAP','units',...
    'normalized','position',[0 1-11*bh 2*bw bh],'Callback', ...
    'Coreg(''ResCMAP'')','tag','ResCMAP');

uicontrol('style','text','parent',fig,'string','Threshold','units',...
    'normalized','position',[0 1-14*bh 2*bw bh],'fontweight','bold');

uicontrol('style','text','parent',fig,'string','Res.thres.','units',...
    'normalized','position',[0 1-15*bh bw bh]);

uicontrol('style','edit','parent',fig,'string',[],'units',...
    'normalized','position',[bw 1-15*bh bw bh],'Callback', ...
    'Coreg(''ThresValue'')','tag','ThresholdBox');
uicontrol('style','pushbutton','parent',fig,'string','Thres. Color','units',...
    'normalized','position',[0 1-16*bh 2*bw bh],'Callback', ...
    'Coreg(''ResColor'')','tag','ResColor');

uicontrol('style','pushbutton','parent',fig,'string','Cross Color','units',...
    'normalized','position',[0 1-17*bh 2*bw bh],'Callback', ...
    'Coreg(''XColor'')','tag','CrossColor');

uicontrol('style','text','parent',fig,'string','Transparancy','units',...
    'normalized','position',[0 1-19*bh 2*bw bh],'fontweight','bold');

uicontrol('style','slider','parent',fig,'units',...
    'normalized','position',[0 1-20*bh 2*bw bh],'Callback', ...
    'Coreg(''SetAlpha'')','tag','AlphaSlider','value',0.5);

uicontrol('style','text','parent',fig,'string','Airfile Load:','units',...
    'normalized','position',[0 1-23*bh 2*bw bh],'fontweight','bold');

uicontrol('style','pushbutton','parent',fig,'string','Res->Std','units',...
    'normalized','position',[0 1-24*bh 2*bw bh],'Callback', ...
    'Coreg(''AirfileLoad'',1)','tag','Mode');

uicontrol('style','pushbutton','parent',fig,'string','Std->Res','units',...
    'normalized','position',[0 1-25*bh 2*bw bh],'Callback', ...
    'Coreg(''AirfileLoad'',2)','tag','Mode');

uicontrol('style','text','parent',fig,'string','Undo','units',...
    'normalized','position',[0 2*bh 2*bw bh],'fontweight','bold');

uicontrol('style','pushbutton','parent',fig,...
    'string','Undo last transform','Callback','Coreg(''Undo'')',...
    'units','normalized','position',[0 bh 2*bw bh]);

uicontrol('style','pushbutton','parent',fig,...
    'string','Undo all Transforms','Callback','Coreg(''UndoAll'')',...
    'units','normalized','position',[0 0 2*bw bh]);


% Various data needed later on:
% Axes handles:
userdat.stdaxes=[ax1 ay1 az1];
userdat.resaxes=[ax2 ay2 az2];
% Colormaps / colors:
userdat.resliceCMAP=hot(64);
userdat.standardCMAP=gray(64);
userdat.threscolor=[0 1 0];
userdat.xcolor=[1 1 1];
% Initial transformation (identity)
userdat.A=diag([1 1 1 1]);
% uicontrol width/height
userdat.bw=bw;
userdat.bh=bh;
% Crossing point:
userdat.centre=[];
% Transparancy set to "half"
userdat.Alpha=0.5;
% Startup translation / rotation stepsizes
userdat.TransStep=1;
userdat.AngStep=pi/48;
set(fig,'userdata',userdat);

function Load(varargin)
% General purpose load routine, 1st parameter is 'standard'/'reslice'

% Load Standard dataset first!
userdat=get(findobj('tag','CoregOnline'),'userdata');
if nargin==1
    LoadType=varargin{1};
    if not(isfield(userdat,'standardIMG')) && strcmp(LoadType,'reslice')
        warning('Start by loading a STANDARD image, please!')
        return
    end
    [File,Path]=uigetfile('*.img',['Select ' LoadType ' dataset']);
else
    LoadType=varargin{1};
    LoadFile=varargin{2};
    [Path,File,Ext]=fileparts(LoadFile);
    Path=[Path '/'];
    File=[File Ext];
end
if not(File==0)
    if isempty(Path)
        Path=[pwd '/'];
    end
    File=NoExt([Path File]);
    if exist([File '.img'])==2 && exist([File '.hdr'])==2
        disp(['Loading ' File]);
        % First remove all old data...
        eval(['userdat.' LoadType 'IMG=[];']);
        eval(['userdat.' LoadType 'HDR=[];']);
        eval(['userdat.' LoadType 'X=[];']);
        eval(['userdat.' LoadType 'Y=[];']);
        eval(['userdat.' LoadType 'Z=[];']);
        eval(['userdat.' LoadType 'XAX=[];']);
        eval(['userdat.' LoadType 'YAX=[];']);
        eval(['userdat.' LoadType 'ZAX=[];']);
        eval(['userdat.' LoadType 'MIN=[];']);
        eval(['userdat.' LoadType 'MAX=[];']);
        eval(['userdat.' LoadType 'MINg=[];']);
        eval(['userdat.' LoadType 'MAXg=[];']);
        set(findobj('tag','CoregOnline'),'userdata',userdat);
        [img,hdr]=LoadAnalyze(File,'single');
        pause(0.2);
        img=reshape(img,hdr.dim(1:3)');
        img=permute(img,[2 1 3]);
        if all(hdr.origin)==0
            hdr.origin=hdr.origin+1;
        end
        if hdr.scale==0
            hdr.scale=1;
        end

        %_______________________________________________________________

        [Min,Max]=findLim(img);

        %DISABLE 280103TD Min=double(min(img(:)));
        %DISABLE 280103TD Max=double(max(img(:)));
        %_______________________________________________________________

        xax=hdr.siz(1)*([1:hdr.dim(1)]-hdr.origin(1));
        yax=hdr.siz(2)*([1:hdr.dim(2)]-hdr.origin(2));
        zax=hdr.siz(3)*([1:hdr.dim(3)]-hdr.origin(3));
        [X,Y,Z]=meshgrid(xax,yax,zax);
        eval(['userdat.' LoadType 'IMG=img;']);
        eval(['userdat.' LoadType 'HDR=hdr;']);
        eval(['userdat.' LoadType 'X=X;']);
        eval(['userdat.' LoadType 'Y=Y;']);
        eval(['userdat.' LoadType 'Z=Z;']);
        eval(['userdat.' LoadType 'XAX=xax;']);
        eval(['userdat.' LoadType 'YAX=yax;']);
        eval(['userdat.' LoadType 'ZAX=zax;']);
        eval(['userdat.' LoadType 'MIN=Min;']);
        eval(['userdat.' LoadType 'MAX=Max;']);
        eval(['userdat.' LoadType 'MINg=Min;']);
        eval(['userdat.' LoadType 'MAXg=Max;']);
        if not(isfield(userdat,[LoadType 'CMAP']));
            eval(['userdat.' LoadType 'CMAP=gray(64);']);
        end
        minbox=findobj('parent',findobj('tag','CoregOnline'),'style','edit','tag',[LoadType 'Min']);
        maxbox=findobj('parent',findobj('tag','CoregOnline'),'style','edit','tag',[LoadType 'Max']);

        set(minbox,'string',num2str(Min))
        set(maxbox,'string',num2str(Max))
        userdat.CurrentPoint=[mean(xax),mean(yax),mean(zax)];
        userdat.A=diag([1 1 1 1]);
        if strcmp('reslice',LoadType);
            % PET dataset must be in doubles....
            img=double(img);
            userdat.resliceIMG=img;
            userdat.threshold=mean([max(img(:)) median(img(:))]);
            set(findobj('callback','Coreg(''ThresValue'')'),'string',num2str(userdat.threshold));
        end
        set(findobj('tag','CoregOnline'),'userdata',userdat)
        UpdateCuts
    else
        error(['.hdr or .img of ' File ' not present!']);
    end
else
    disp('File Load Cancelled');
end


function filename1=NoExt(filename)
% Remove extension if any
dots=strfind(filename,'.');
if not(isempty(dots))
    dots=dots(length(dots-1));
    filename1=filename(1:dots-1);
else
    filename1=filename;
end

function UpdateCuts
% Update the viewports

userdat=get(findobj('tag','CoregOnline'),'userdata');

% Calculate the indexes:
% Any data present?
if isfield(userdat,'standardIMG');
    [tmp,xidx]=min(abs(userdat.standardXAX-userdat.CurrentPoint(1)));
    [tmp,yidx]=min(abs(userdat.standardYAX-userdat.CurrentPoint(2)));
    [tmp,zidx]=min(abs(userdat.standardZAX-userdat.CurrentPoint(3)));

    % Calculate position of the axes:
    bh=userdat.bh;
    bw=userdat.bw;
    totwidth=1-2*bw-2*bh;
    totheight=0.5;
    % Which axes is the longest?
    lx=max(userdat.standardXAX)-min(userdat.standardXAX);
    ly=max(userdat.standardYAX)-min(userdat.standardYAX);
    lz=max(userdat.standardZAX)-min(userdat.standardZAX);
    % Horiz. longest:
    lh=max(lx,ly);
    % Vert. longest:
    lv=max(ly,lz);
    pos=cell(2,3);
    w1=(totwidth/3)*(ly/lh);
    w2=(totwidth/3)*(lx/lh);
    w3=(totwidth/3)*(lx/lh);
    h1=totheight*lz/lv;
    h2=totheight*lz/lv;
    h3=totheight*ly/lv;
    Cy1=0.5*(0.5-h1);
    Cy2=0.5*(0.5-h2);
    Cy3=0.5*(0.5-h3);

    pos{1,1}=[1-totwidth 0.5+Cy1 w1 h1];
    pos{1,2}=[1-w3-w2-(0.5*(totwidth-(w1+w2+w3))) 0.5+Cy2 w2 h2];
    pos{1,3}=[1-w3 0.5+Cy3 w3 h3];
    pos{2,1}=pos{1,1};
    pos{2,1}(2)=Cy1;
    pos{2,2}=pos{1,2};
    pos{2,2}(2)=Cy2;
    pos{2,3}=pos{1,3};
    pos{2,3}(2)=Cy3;
    for j=1:3
        set(userdat.stdaxes(j),'position',pos{1,j});
        set(userdat.resaxes(j),'position',pos{2,j});
    end

    %X-view, standard image
    axes(userdat.stdaxes(1));
    slice=CalcRGB(squeeze(userdat.standardIMG(:,xidx,:))',userdat.standardMIN,userdat.standardMAX,userdat.standardCMAP);
    img=image(userdat.standardYAX,userdat.standardZAX,slice);
    axis image
    set(userdat.stdaxes(1),'ydir','normal','xtick',[],'ytick',[]);
    set(img,'buttondownfcn','Coreg(''ButtonClicked'',''X'')');
    hold on
    xx=get(userdat.stdaxes(1),'Xlim');
    yy=get(userdat.stdaxes(1),'Ylim');
    plot(xx,[userdat.CurrentPoint(3) userdat.CurrentPoint(3)],'color',userdat.xcolor,'buttondownfcn','Coreg(''ButtonClicked'',''X'')');
    plot([userdat.CurrentPoint(2) userdat.CurrentPoint(2)],yy,'color',userdat.xcolor,'buttondownfcn','Coreg(''ButtonClicked'',''X'')');
    hold off

    %Y-view, standard image
    axes(userdat.stdaxes(2));
    slice=CalcRGB(squeeze(userdat.standardIMG(yidx,:,:))',userdat.standardMIN,userdat.standardMAX,userdat.standardCMAP);
    img=image(userdat.standardXAX,userdat.standardZAX,slice);
    axis image
    set(userdat.stdaxes(2),'ydir','normal','xtick',[],'ytick',[]);
    set(img,'buttondownfcn','Coreg(''ButtonClicked'',''Y'')');
    hold on
    xx=get(userdat.stdaxes(2),'Xlim');
    yy=get(userdat.stdaxes(2),'Ylim');
    plot(xx,[userdat.CurrentPoint(3) userdat.CurrentPoint(3)],'color',userdat.xcolor,'buttondownfcn','Coreg(''ButtonClicked'',''Y'')');
    plot([userdat.CurrentPoint(1) userdat.CurrentPoint(1)],yy,'color',userdat.xcolor,'buttondownfcn','Coreg(''ButtonClicked'',''Y'')');
    hold off

    %Z-view, standard image
    axes(userdat.stdaxes(3));
    slice=CalcRGB(squeeze(userdat.standardIMG(:,:,zidx)),userdat.standardMIN,userdat.standardMAX,userdat.standardCMAP);
    img=image(userdat.standardXAX,userdat.standardYAX,slice);
    axis image
    set(userdat.stdaxes(3),'ydir','normal','xtick',[],'ytick',[]);
    set(img,'buttondownfcn','Coreg(''ButtonClicked'',''Z'')');
    hold on
    xx=get(userdat.stdaxes(3),'Xlim');
    yy=get(userdat.stdaxes(3),'Ylim');
    plot(xx,[userdat.CurrentPoint(2) userdat.CurrentPoint(2)],'color',userdat.xcolor,'buttondownfcn','Coreg(''ButtonClicked'',''Z'')');
    plot([userdat.CurrentPoint(1) userdat.CurrentPoint(1)],yy,'color',userdat.xcolor,'buttondownfcn','Coreg(''ButtonClicked'',''Z'')');
    hold off
end

% Both reslice and standard images loaded?
if isfield(userdat,'resliceIMG') && isfield(userdat,'standardIMG');
    % Check for translation matrices:
    x=userdat.resliceX;
    y=userdat.resliceY;
    z=userdat.resliceZ;

    %X-view, reslice image
    axes(userdat.resaxes(1));
    xskive=squeeze(userdat.standardX(:,xidx,:));
    yskive=squeeze(userdat.standardY(:,xidx,:));
    zskive=squeeze(userdat.standardZ(:,xidx,:));
    sx=size(xskive);
    sy=size(yskive);
    sz=size(zskive);
    xskive=reshape(xskive,1,prod(sx));
    yskive=reshape(yskive,1,prod(sy));
    zskive=reshape(zskive,1,prod(sz));
    synts=[xskive;yskive;zskive;1+0*zskive];
    if not(isempty(userdat.A))
        if iscell(userdat.A)
            lA=length(userdat.A);
            for j=0:length(userdat.A)-1
                synts=inv(userdat.A{lA-j})*synts;
            end
        else
            synts=inv(userdat.A)*synts;
        end
    end
    xskive=synts(1,:);
    yskive=synts(2,:);
    zskive=synts(3,:);
    xskive=reshape(xskive,sx);
    yskive=reshape(yskive,sy);
    zskive=reshape(zskive,sz);
    slice=interp3(x,y,z,userdat.resliceIMG,xskive,yskive,zskive)';
    sliceRGB=CalcRGB(slice,userdat.resliceMIN,userdat.resliceMAX,userdat.resliceCMAP);
    img=image(userdat.standardYAX,userdat.standardZAX,sliceRGB);
    axis image
    set(userdat.resaxes(1),'ydir','normal','xtick',[],'ytick',[]);
    set(img,'buttondownfcn','Coreg(''ButtonClicked'',''X'',''PET'')');
    if isfield(userdat,'threshold')
        axes(userdat.stdaxes(1));
        if not(all(all(isnan(slice))))
            hold on
            h=image(userdat.standardYAX,userdat.standardZAX,sliceRGB, ...
                'buttondownfcn','Coreg(''ButtonClicked'',''X'')', ...
                'tag','overlay');
            alpha(h,userdat.Alpha);
            [c,h]=contour(userdat.standardYAX,userdat.standardZAX,slice, ...
                [userdat.threshold userdat.threshold]);
            set(h,'edgecolor',userdat.threscolor,'buttondownfcn','Coreg(''ButtonClicked'',''X'')')
            hold off
            axes(userdat.resaxes(1));
            hold on
            [c,h]=contour(userdat.standardYAX,userdat.standardZAX,slice, ...
                [userdat.threshold userdat.threshold]);
            set(h,'edgecolor',userdat.threscolor,'buttondownfcn','Coreg(''ButtonClicked'',''X'',''PET'')')
            hold off
        end
    end
    axes(userdat.resaxes(1));
    hold on
    xx=get(userdat.resaxes(1),'Xlim');
    yy=get(userdat.resaxes(1),'Ylim');
    plot(xx,[userdat.CurrentPoint(3) userdat.CurrentPoint(3)],'color',userdat.xcolor,'buttondownfcn','Coreg(''ButtonClicked'',''X'',''PET'')');
    plot([userdat.CurrentPoint(2) userdat.CurrentPoint(2)],yy,'color',userdat.xcolor,'buttondownfcn','Coreg(''ButtonClicked'',''X'',''PET'')');
    hold off

    %Y-view, reslice image
    axes(userdat.resaxes(2));
    xskive=squeeze(userdat.standardX(yidx,:,:));
    yskive=squeeze(userdat.standardY(yidx,:,:));
    zskive=squeeze(userdat.standardZ(yidx,:,:));
    sx=size(xskive);
    sy=size(yskive);
    sz=size(zskive);
    xskive=reshape(xskive,1,prod(sx));
    yskive=reshape(yskive,1,prod(sy));
    zskive=reshape(zskive,1,prod(sz));
    synts=[xskive;yskive;zskive;1+0*zskive];
    if not(isempty(userdat.A))
        if iscell(userdat.A)
            lA=length(userdat.A);
            for j=0:length(userdat.A)-1
                synts=inv(userdat.A{lA-j})*synts;
            end
        else
            synts=inv(userdat.A)*synts;
        end
    end
    xskive=synts(1,:);
    yskive=synts(2,:);
    zskive=synts(3,:);
    xskive=reshape(xskive,sx);
    yskive=reshape(yskive,sy);
    zskive=reshape(zskive,sz);
    slice=interp3(x,y,z,userdat.resliceIMG,xskive,yskive,zskive)';
    sliceRGB=CalcRGB(slice,userdat.resliceMIN,userdat.resliceMAX,userdat.resliceCMAP);
    img=image(userdat.standardXAX,userdat.standardZAX,sliceRGB);
    axis image
    set(userdat.resaxes(2),'ydir','normal','xtick',[],'ytick',[]);
    set(img,'buttondownfcn','Coreg(''ButtonClicked'',''Y'',''PET'')');
    if isfield(userdat,'threshold')
        axes(userdat.stdaxes(2));
        if not(all(all(isnan(slice))))
            hold on
            h=image(userdat.standardXAX,userdat.standardZAX,sliceRGB, ...
                'buttondownfcn','Coreg(''ButtonClicked'',''Y'')', ...
                'tag','overlay');
            alpha(h,userdat.Alpha);
            [c,h]=contour(userdat.standardXAX,userdat.standardZAX,slice, ...
                [userdat.threshold userdat.threshold]);
            set(h,'edgecolor',userdat.threscolor,'buttondownfcn','Coreg(''ButtonClicked'',''Y'')')
            hold off
            axes(userdat.resaxes(2));
            hold on
            [c,h]=contour(userdat.standardXAX,userdat.standardZAX,slice, ...
                [userdat.threshold userdat.threshold]);
            set(h,'edgecolor',userdat.threscolor,'buttondownfcn','Coreg(''ButtonClicked'',''Y'',''PET'')')
            hold off
        end
    end
    axes(userdat.resaxes(2))
    hold on
    xx=get(userdat.resaxes(2),'Xlim');
    yy=get(userdat.resaxes(2),'Ylim');
    plot(xx,[userdat.CurrentPoint(3) userdat.CurrentPoint(3)],'color',userdat.xcolor,'buttondownfcn','Coreg(''ButtonClicked'',''Y'',''PET'')');
    plot([userdat.CurrentPoint(1) userdat.CurrentPoint(1)],yy,'color',userdat.xcolor,'buttondownfcn','Coreg(''ButtonClicked'',''Y'',''PET'')');
    hold off

    %Z-view, reslice image
    axes(userdat.resaxes(3));
    xskive=squeeze(userdat.standardX(:,:,zidx));
    yskive=squeeze(userdat.standardY(:,:,zidx));
    zskive=squeeze(userdat.standardZ(:,:,zidx));
    sx=size(xskive);
    sy=size(yskive);
    sz=size(zskive);
    xskive=reshape(xskive,1,prod(sx));
    yskive=reshape(yskive,1,prod(sy));
    zskive=reshape(zskive,1,prod(sz));
    synts=[xskive;yskive;zskive;1+0*zskive];
    if not(isempty(userdat.A))
        if iscell(userdat.A)
            lA=length(userdat.A);
            for j=0:length(userdat.A)-1
                synts=inv(userdat.A{lA-j})*synts;
            end
        else
            synts=inv(userdat.A)*synts;
        end
    end
    xskive=synts(1,:);
    yskive=synts(2,:);
    zskive=synts(3,:);
    xskive=reshape(xskive,sx);
    yskive=reshape(yskive,sy);
    zskive=reshape(zskive,sz);
    slice=interp3(x,y,z,userdat.resliceIMG,xskive,yskive,zskive);
    sliceRGB=CalcRGB(slice,userdat.resliceMIN,userdat.resliceMAX,userdat.resliceCMAP);
    img=image(userdat.standardXAX,userdat.standardYAX,sliceRGB);
    axis image
    set(userdat.resaxes(3),'ydir','normal','xtick',[],'ytick',[]);
    set(img,'buttondownfcn','Coreg(''ButtonClicked'',''Z'',''PET'')');
    if isfield(userdat,'threshold')
        axes(userdat.stdaxes(3));
        if not(all(all(isnan(slice))))
            hold on
            h=image(userdat.standardXAX,userdat.standardYAX,sliceRGB, ...
                'buttondownfcn','Coreg(''ButtonClicked'',''Z'')', ...
                'tag','overlay');
            alpha(h,userdat.Alpha);
            [c,h]=contour(userdat.standardXAX,userdat.standardYAX,slice, ...
                [userdat.threshold userdat.threshold]);
            set(h,'edgecolor',userdat.threscolor,'buttondownfcn','Coreg(''ButtonClicked'',''Z'')')
            hold off
            axes(userdat.resaxes(3));
            hold on
            [c,h]=contour(userdat.standardXAX,userdat.standardYAX,slice, ...
                [userdat.threshold userdat.threshold]);
            set(h,'edgecolor',userdat.threscolor,'buttondownfcn','Coreg(''ButtonClicked'',''Z'',''PET'')')
            hold off
        end
    end
    axes(userdat.resaxes(3));
    hold on
    xx=get(userdat.resaxes(3),'Xlim');
    yy=get(userdat.resaxes(3),'Ylim');
    plot(xx,[userdat.CurrentPoint(2) userdat.CurrentPoint(2)],'color',userdat.xcolor,'buttondownfcn','Coreg(''ButtonClicked'',''Z'',''PET'')');
    plot([userdat.CurrentPoint(1) userdat.CurrentPoint(1)],yy,'color',userdat.xcolor,'buttondownfcn','Coreg(''ButtonClicked'',''Z'',''PET'')');
    hold off
end


function slice=CalcRGB(slice,Min,Max,CMAP)
% Return RGB version of slice, values from CMAP, between Min and Max

slice=double(slice);
slice(isnan(slice))=Min;
slice(slice<Min)=Min;
slice(slice>Max)=Max;
lc=size(CMAP);
lc=lc(1);
slice=1+round((lc-1)*(slice-Min)/(Max-Min));
R=CMAP(:,1);
G=CMAP(:,2);
B=CMAP(:,3);
slice=cat(3,R(slice),G(slice),B(slice));


function ButtonClick(varargin)
% General callback for transformation start
global ENABLE_HACKS
where=varargin{1};
fig=findobj('tag','CoregOnline');
userdat=get(fig,'userdata');

if nargin==2;
    curax=get(gcbo,'parent');
    point=get(curax,'currentpoint');
    if strcmp(where,'X')
        userdat.CurrentPoint(2)=point(1,1);
        userdat.CurrentPoint(3)=point(1,2);
    elseif strcmp(where,'Y')
        userdat.CurrentPoint(1)=point(1,1);
        userdat.CurrentPoint(3)=point(1,2);
    else
        userdat.CurrentPoint(1)=point(1,1);
        userdat.CurrentPoint(2)=point(1,2);
    end
    set(fig,'userdata',userdat)
    UpdateCuts;
else
    disp('Starting transformation');
    curax=get(gcbo,'parent');
    userdat.OldPoint=get(curax,'currentpoint');
    userdat.Transform=1;
    dd=version;
    userdat.Faces=[];
    userdat.Vertices=[];
    if (dd<'7')
        userdat.Faces=get(findobj('parent',curax,'type','patch'),'faces');
        userdat.Vertices=get(findobj('parent',curax,'type','patch'),'vertices');
    else
        userdat.Vertices=get(findobj(get(curax,'children'),'type','patch'),'vertices');
        userdat.Faces=get(findobj(get(curax,'children'),'type','patch'),'faces');
    end
    curax=get(gcbo,'parent');
    hfig=figure('units','normalized','position',[0.025 0.0 0.8 0.95]);
    %h=hfig;
    %set(h,'renderer','opengl')
    himg=findobj('parent',curax,'type','image','tag','');
    img=get(himg,'cdata');
    xd=get(himg,'xdata');
    yd=get(himg,'ydata');
    imagesc(xd,yd,img,'buttondownfcn','CrossMove');
    himg=findobj('parent',curax,'type','image','tag','overlay');
    img=get(himg,'cdata');
    xd=get(himg,'xdata');
    yd=get(himg,'ydata');
    % Create meshes for overlay pcolor surface:
    dx=xd(2)-xd(1);
    dy=yd(2)-yd(1);
    xm=xd(1)-dx/2:dx:xd(length(xd))+dx/2;
    ym=yd(1)-dy/2:dy:yd(length(yd))+dy/2;
    [xm,ym]=meshgrid(xm,ym);
    hold on;
    h=pcolor(xm,ym,0*xm);
    set(h,'tag','cursor','edgecolor','none','cdata',img,'buttondownfcn','CrossMove');
    alpha(h,userdat.Alpha);
    set(gca,'ydir','normal');
    axis image
    if ENABLE_HACKS==1
        % Adjust for Matlab R12 inconvenience
        imgsiz=size(img);
        imgsiz(2)=imgsiz(2)+1;
        img1=zeros(imgsiz);
        img1(:,1:size(img,2),:)=img;
        img1(:,imgsiz(2),:)=img(:,size(img,2),:);
        xm=xd(1)-3*dx/2:dx:xd(length(xd))+dx/2;
        ym=yd(1)-dy/2:dy:yd(length(yd))+dy/2;
        [xm,ym]=meshgrid(xm,ym);
        set(h,'xdata',xm,'ydata',ym,'zdata',0*xm,'cdata',img1);
    end
    userdat.xx=xm;
    userdat.yy=ym;
    ud.TransStep=userdat.TransStep;
    ud.AngStep=userdat.AngStep;%pi/24;
    hold on
    if not(iscell(userdat.Faces))
        tmpCell=cell(1);
        tmpCell{1}=userdat.Faces;
        userdat.Faces=tmpCell;
        tmpCell{1}=userdat.Vertices;
        userdat.Vertices=tmpCell;
    end
    for j=1:length(userdat.Vertices)
        obj=patch('faces',userdat.Faces{j},'vertices',userdat.Vertices{j},'edgecolor',userdat.threscolor,...
            'tag','cursor','facecolor','none','userdata',ud,'linewidth',2,'buttondownfcn','CrossMove');
    end
    if strcmp(where,'X')
        view=[2 3 1];
    elseif strcmp(where,'Y')
        view=[1 3 2];
    elseif strcmp(where,'Z')
        view=[1 2 3];
    end
    ud.centre=userdat.OldPoint(1,1:2);
    ud.A=diag([1 1 1 1]);
    ud.parent=gcbf;
    ud.alpha=userdat.Alpha;
    hold on
    xl=get(gca,'xlim');
    yl=get(gca,'ylim');
    h=plot(xl,[ud.centre(2) ud.centre(2)],'g:','linewidth',2);
    set(h,'color',userdat.threscolor,'tag','Cross','buttondownfcn','CrossMove')
    h=plot([ud.centre(1) ud.centre(1)],yl,'g:','linewidth',2);
    set(h,'color',userdat.threscolor,'tag','Cross','buttondownfcn','CrossMove')
    set(hfig,'keypressfcn',['CheckKey_Coreg(findobj(''tag'',''cursor''),[' num2str(view) '])'],'userdata',ud,...
        'closerequestfcn','ReturnA')
    title(['Transl. ' num2str(userdat.TransStep) ' mm. Rot. \pi/' num2str(pi/userdat.AngStep) ]);
    
    delete(findobj('type','figure','Name','Keys'));
    figure('units','normalized',...
        'position',[0.83 0.005 0.1175 0.97],...
        'SelectionHighlight','off',...
        'name','Keys',...
        'tag','coreghelp',...
        'menubar','none',...
        'numbertitle','off');
    uicontrol('style','text',...
        'units','normalized',...
        'position',[0.05 0.8 .2 0.05],...,
        'fontweight','bold',...
        'fontsize',16,...
        'String','Key:');
    uicontrol('style','text',...
        'units','normalized',...
        'position',[0.3 0.8 .65 0.05],...,
        'fontweight','bold',...
        'fontsize',16,...
        'String','Action:');
    
    uicontrol('style','text',...
        'units','normalized',...
        'position',[0.05 0.75 .2 0.05],...,
        'fontweight','bold',...
        'fontsize',13,...
        'String','left');
    uicontrol('style','text',...
        'units','normalized',...
        'position',[0.3 0.75 .65 0.05],...,
        'fontweight','bold',...
        'fontsize',12,...
        'String','Move left');
    
    uicontrol('style','text',...
        'units','normalized',...
        'position',[0.05 0.7 .2 0.05],...,
        'fontweight','bold',...
        'fontsize',13,...
        'String','right');
    uicontrol('style','text',...
        'units','normalized',...
        'position',[0.3 0.7 .65 0.05],...,
        'fontweight','bold',...
        'fontsize',12,...
        'String','Move right');
    
    uicontrol('style','text',...
        'units','normalized',...
        'position',[0.05 0.65 .2 0.05],...,
        'fontweight','bold',...
        'fontsize',13,...
        'String','up');
    uicontrol('style','text',...
        'units','normalized',...
        'position',[0.3 0.65 .65 0.05],...,
        'fontweight','bold',...
        'fontsize',12,...
        'String','Move up');
    
    uicontrol('style','text',...
        'units','normalized',...
        'position',[0.05 0.6 .2 0.05],...,
        'fontweight','bold',...
        'fontsize',13,...
        'String','down');
    uicontrol('style','text',...
        'units','normalized',...
        'position',[0.3 0.6 .65 0.05],...,
        'fontweight','bold',...
        'fontsize',12,...
        'String','Move down');
    
    uicontrol('style','text',...
        'units','normalized',...
        'position',[0.05 0.55 .2 0.05],...,
        'fontweight','bold',...
        'fontsize',18,...
        'String',',');
    uicontrol('style','text',...
        'units','normalized',...
        'position',[0.3 0.55 .65 0.05],...,
        'fontweight','bold',...
        'fontsize',12,...
        'String','Rotate counterclockwise');
    
    uicontrol('style','text',...
        'units','normalized',...
        'position',[0.05 0.5 .2 0.05],...,
        'fontweight','bold',...
        'fontsize',18,...
        'String','.');
    uicontrol('style','text',...
        'units','normalized',...
        'position',[0.3 0.5 .65 0.05],...,
        'fontweight','bold',...
        'fontsize',12,...
        'String','Rotate clockwise');
    
    uicontrol('style','text',...
        'units','normalized',...
        'position',[0.05 0.45 .2 0.05],...,
        'fontweight','bold',...
        'fontsize',18,...
        'String','+');
    uicontrol('style','text',...
        'units','normalized',...
        'position',[0.3 0.45 .65 0.05],...,
        'fontweight','bold',...
        'fontsize',12,...
        'String','Increase movement step');
    
    uicontrol('style','text',...
        'units','normalized',...
        'position',[0.05 0.4 .2 0.05],...,
        'fontweight','bold',...
        'fontsize',18,...
        'String','-');
    uicontrol('style','text',...
        'units','normalized',...
        'position',[0.3 0.4 .65 0.05],...,
        'fontweight','bold',...
        'fontsize',12,...
        'String','Decrease movement step');
    
    uicontrol('style','text',...
        'units','normalized',...
        'position',[0.05 0.35 .2 0.05],...,
        'fontweight','bold',...
        'fontsize',18,...
        'String','*');
    uicontrol('style','text',...
        'units','normalized',...
        'position',[0.3 0.35 .65 0.05],...,
        'fontweight','bold',...
        'fontsize',12,...
        'String','Increase rotation step');
    
    uicontrol('style','text',...
        'units','normalized',...
        'position',[0.05 0.3 .2 0.05],...,
        'fontweight','bold',...
        'fontsize',18,...
        'String','/');
    uicontrol('style','text',...
        'units','normalized',...
        'position',[0.3 0.3 .65 0.05],...,
        'fontweight','bold',...
        'fontsize',12,...
        'String','Decrease rotation step');
    
    uicontrol('style','text',...
        'units','normalized',...
        'position',[0.05 0.25 .2 0.05],...,
        'fontweight','bold',...
        'fontsize',14,...
        'String','a');
    uicontrol('style','text',...
        'units','normalized',...
        'position',[0.3 0.25 .65 0.05],...,
        'fontweight','bold',...
        'fontsize',12,...
        'String','Increase transparency');
    
    uicontrol('style','text',...
        'units','normalized',...
        'position',[0.05 0.2 .2 0.05],...,
        'fontweight','bold',...
        'fontsize',14,...
        'String','s');
    uicontrol('style','text',...
        'units','normalized',...
        'position',[0.3 0.2 .65 0.05],...,
        'fontweight','bold',...
        'fontsize',12,...
        'String','Decrease transparency');
    
    uicontrol('style','text',...
        'units','normalized',...
        'position',[0.05 0.15 .2 0.05],...,
        'fontweight','bold',...
        'fontsize',14,...
        'String','x');
    uicontrol('style','text',...
        'units','normalized',...
        'position',[0.3 0.15 .65 0.05],...,
        'fontweight','bold',...
        'fontsize',12,...
        'String','Close window');
    
    figure(hfig)
end



function A=CalculateA
% Return total transformation matrix
userdat=get(findobj('tag','CoregOnline'),'userdata');
A=diag([1 1 1 1]);
if not(isempty(userdat.A))
    if iscell(userdat.A)
        for j=1:length(userdat.A)
            A=userdat.A{j}*A;
        end
    else
        A=userdat.A;
    end
else
    A=[];
end

function LoadAir(direction)
% Load an AIR [Woods] reslice file

% Direction==1 : reslice file to standard file
% Direction==2 : standard file to reslice file

userdat=get(findobj('tag','CoregOnline'),'userdata');
if isfield(userdat,'standardIMG') && ...
        isfield(userdat,'resliceIMG');
    % Get the A-matrix:
    if not(isempty(userdat.A))
        Answer=questdlg('Clear current transformations?');
        if not(strcmp(Answer,'Yes'))
            disp('Load cancelled')
            return
        end
    end
    userdat.A=diag([1 1 1 1]);
    if direction==2
        Getfile='standard';
        Putfile='reslice';
        hdri=userdat.standardHDR;
        hdro=userdat.resliceHDR;
    else
        Getfile='reslice';
        Putfile='standard';
        hdro=userdat.standardHDR;
        hdri=userdat.resliceHDR;
    end
    [File Path]=uigetfile('*.air',['Select airfile for transformation of ' Getfile ]);
    if not(File==0)
        userdat.A=ReadAir([Path File]);
        if direction==2
            userdat.A=inv(userdat.A);
        end
        set(findobj('tag','CoregOnline'),'userdata',userdat);
        UpdateCuts;
    else
        disp('Load cancelled');
    end
else
    disp('Both standard and reslice dataset must be loaded!');
end

function AlignCM
% Align the two centres of mass

userdat=get(findobj('tag','CoregOnline'),'userdata');
xyzstd=[userdat.standardX(:)';userdat.standardY(:)';userdat.standardZ(:)'];
xyzres=[userdat.resliceX(:)';userdat.resliceY(:)';userdat.resliceZ(:)'];
imgstd=double(userdat.standardIMG(:));
imgres=userdat.resliceIMG(:);
xyzstd(1,:)=xyzstd(1,:)*imgstd/sum(imgstd);
xyzstd(2,:)=xyzstd(2,:)*imgstd/sum(imgstd);
xyzstd(3,:)=xyzstd(3,:)*imgstd/sum(imgstd);
xyzstd=sum(xyzstd,2)/length(imgstd);
xyzres(1,:)=xyzres(1,:)*imgres/sum(imgres);
xyzres(2,:)=xyzres(2,:)*imgres/sum(imgres);
xyzres(3,:)=xyzres(3,:)*imgres/sum(imgres);
xyzres=sum(xyzres,2)/length(imgres);
A=diag([1 1 1 1]);
A(1:3,4)=xyzstd-xyzres;
userdat.A=A;
userdat.centre=[];
set(gcbf,'userdata',userdat);
UpdateCuts;