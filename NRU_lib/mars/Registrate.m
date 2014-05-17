function varargout=Registrate(varargin)
%
% Interactive Point Selection (IPS) a manual method for co-registration (6-DOF) a high resolution
% MR scan and a low resolution PET/SPECT brain scan. User mark a least 3  different sets of corresponding
% points in the MR and the PET/SPECT scan. A co-registration matrix is found based on the point sets.
% Extra features: Save/load point sets. Reslicing and visualisation
%
% Note: Before exiting, IPS call a user defined Returnfunction where the co-registration matrix
%       can be retrived.
%
% Different calls of the Registrate function:
%
%       1) FIG_HANDLE=REGISTRATE; Initialize GUI and return handle
%
%       2) REGISTRATE('BATCH',FIG_HANDLE,FILENAME,PARENT_HANDLE,RETURN_FUCN,VISULIZER);
%               - 'BATCH': Start command
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
%               - PARENT_HANDLE: Figure handle to parent/main figure so it can be found when returning fra Registrate.
%                      example :
%                            PARENT_HANDLE=h_mainfig
%
%               - RETURN_FUCN: Name of function where the co-registration matrix can be retrieved and saved before exiting
%                              the Registrate.
%                      example:
%                           feval('saveMatrix','ReturningData',PARENT_HANDLE,Aall);
%                           where - ReturningData: Parameter telling that co-registration matrix is returned by Registrate
%                                 - Aall contain co-registration matrix
%
%               - VISUALIZER: Inspection method to be used: 'browse3d', 'browse2d' or 'nruinspect'
%                      default: 'nruinspect'
%
% Call special functions:
%   - LoadAnalyze.m
%   - SaveAir.m
%   - ReadAnalyzeHdr.m
%   - ReadAnalyzeImg.m
%   - Slice3.m
%   - CheckKey_Coreg.m
%   - CoarseAlign.m
%   - isobj.m
%   - CrossMove.m
%   - voxa2cuba.m
%   - tala2voxa.m
%   - diffA.m
%
% PW, NRU, sep. 2001 (Re-implementation of CMM's registrate program as module in 'register')
%______________________________________________________________________________________________
% Updates:
% - Improve the contrast of the image on the screen, 280103TD, NRU
% - If fig_handle do not exist in 'Batch' mode then create one, 100203TD, NRU
% - Add lower() of varargin{1} when do a 'Batch' check to make it more flexsible, 100203TD, NRU
% - Add 'files' to the struct.UserData, to store information on files used for the co-registration, 110203TD, NRU
% - Add the possibility to save the co-registration matrix in a given air file+path IF a airfile name is given as input, 119293TD, NRU
% - Insert lines from file RegistrateWrapper.m in mars-program to ensure that BATCH-mode to work proberly,170303TS, NRU
% - Error corrected: Get updated coreg data (A) placed in PointListWindowm 010803TD, NRU


if nargin==0
    % Called in stand alone mode.
    Struct.STD=[];
    Struct.RES=[];
    Struct.State='StandAlone';
    h=Registrate('do_coreg',Struct);
    if nargout==1
        varargout{1}=h;
    end
else
    % Set 'watch' pointer on relevant windows
    Mainfig=findobj('tag','Registrate');
    for j=1:length(Mainfig)
        set(Mainfig(j),'pointer','watch');
        ud=get(Mainfig(j),'userdata');
        if isfield(ud,'STDfig')
            set(ud.STDfig,'pointer','watch');
        end
        if isfield(ud,'STDfig')
            set(ud.RESfig,'pointer','watch');
        end
        if isfield(ud,'PointListWin')
            set(ud.PointListWin,'pointer','watch');
        end
    end
    task=varargin{1}; % 1st parameter is always 'what to do'
    if ischar(task)
        switch lower(task)%lower(), 100203TD
            case lower('Batch') % Batch mode %lower(), 100203TD
                fig=varargin{2};
                files=varargin{3};
                parent=varargin{4};
                ReturnFcn=varargin{5};
                visualizer=varargin{6};
                
                if(isempty(fig))% Fig is not initialized, do it!, 100203TD
                    fig=Registrate;
                end
                
                userdat=get(fig,'userdata');
                userdat.State='Module';
                userdat.parent=parent;
                userdat.VisualCallBack=visualizer;
                userdat.ReturnFcn=ReturnFcn;
                userdat.saved=1;
                userdat.files=files; % Save information on used files, 110203TD
                set(fig,'userdata',userdat);
                Registrate('ReplaceVolume','STD',fig,files.STD);
                
                %_______  Same as in Coreg.m (IIO) ______________________
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
                %____________________________________________________
                
                Registrate('ReplaceVolume','RES',fig,resfile);%170303TD
                %Registrate('ReplaceVolume','RES',fig,files.RES{1});
                
                %             %______ Below insered from file RegistrateWrapper.m in mars-program
                %             userdat=get(fig,'userdata');%Insert by 170302TD
                %             userdat.ResNumber=1;%Insert by 170302TD
                %             userdat.ResMax=1;%Insert by 170302TD
                %             set(fig,'userdata',userdat);%Insert by 170302TD
                %             %______ END:Below insered from file RegistrateWrapper.m in mars-program
                
                if not(all(all(files.A{1}==diag([1 1 1 1]))))
                    Answer=questdlg('Apply given rotation parameters to RES visualisation?','Apply parms?');
                    if strcmp('Yes',Answer)
                        Registrate('AdjustRes',fig,files.A{1});
                    else
                        disp('No parameters applied');
                    end
                end
                
                
            case lower('AdjustRes') % Coarse visualisation applied from main program,%lower(), 100203TD
                fig=varargin{2};
                A=varargin{3};
                A(1:3,4)=[0 0 0]';
                userdat=get(fig,'userdata');
                Slice3('CoarseAlign',userdat.RESfig,A);
                FigDat=get(userdat.RESfig,'userdata');
                Slice3('UpdatePoint',userdat.RESfig,FigDat.Realcoords-1);
                
            case lower('init') %lower(), 100203TD
                % Tell the main program what we need:
                Struct.HaveLoadRoutine='no';
                Struct.DataFormat='any';
                Struct.Output='math';
                Struct.Dynamic='no';
                varargout{1}=Struct;
                
            case lower('do_coreg') % Batch mode - data provided from main program,%lower(), 100203TD
                % Do coregistration using data provided by main program
                Mainfig=SetupWindows;
                Struct=varargin{2};
                STD=Struct.STD;
                RES=Struct.RES;
                STDfig=SetData(STD,'STD',Mainfig(1));
                RESfig=SetData(RES,'RES',Mainfig(1));
                userdat=get(Mainfig(1),'userdata');
                userdat.State=Struct.State;
                if isfield(Struct,'ReturnCallBack');
                    userdat.ReturnCallBack=Struct.ReturnCallBack;
                    userdat.ReturnHandle=Struct.ReturnHandle;
                    userdat.VisualCallBack=Struct.VisualCallBack;
                else
                    userdat.ReturnCallBack=['disp(''No ReturnCallBack - in StandAlone Mode);'];
                    userdat.ReturnHandle=[];
                    userdat.VisualCallBack='nruinspect';
                end
                set(Mainfig(1),'userdata',userdat);
                if nargout==1
                    varargout{1}=Mainfig(1);
                end
                
            case lower('InputCoords') % A 3-pane window callback,%lower(), 100203TD
                Fig=varargin{3};
                % Slice3 is returning a coordinate set
                % Are we called from a real window?
                if isobj(Fig)
                    userdat=get(Fig,'userdata');
                    if isfield(userdat,'Parent');
                        Mainfig=userdat.Parent;
                        userdatMain=get(Mainfig,'userdata');
                        PointList=userdatMain.PointListWin;
                        if not(Fig==PointList)
                            userdatList=get(PointList,'userdata');
                            if not(isempty(userdatList.Current))
                                userdat=get(Fig,'userdata');
                                InputPoint(PointList,varargin{2},userdat.Realcoords);
                            end
                        end
                    end
                end
                
            case lower('ReplaceVolume') %lower(), 100203TD
                % Replace STD or RES volume dataset
                if nargin==2
                    userdat=get(gcbf,'userdata');
                    Fig=gcbf;
                else
                    userdat=get(varargin{3},'userdata');
                    Fig=varargin{3};
                end
                if strcmp(varargin{2},'RES')
                    RepNam='reslice';
                    RepFig=userdat.RESfig;
                elseif strcmp(varargin{2},'STD')
                    RepNam='standard';
                    RepFig=userdat.STDfig;
                else
                    error(['I can not replace a dataset of type ' varargin{2}]);
                end
                if not(isempty(RepFig))
                    answer=questdlg(['Do you want to replace your current ' RepNam ' dataset?']);
                else
                    answer='Yes';
                end
                if strcmp(answer,'Yes')
                    if nargin==2
                        [Struct.img,Struct.hdr]=LoadAnalyze('single');
                    else
                        [Struct.img,Struct.hdr]=LoadAnalyze(varargin{4},'single');
                    end
                    if not(isempty(Struct.img))
                        fig=SetData(Struct,varargin{2},Fig);
                        delete(RepFig);
                    else
                        disp([RepNam ' load cancelled']);
                    end
                else
                    disp([RepNam ' load cancelled']);
                end
                
            case lower('ClearPoint')%lower(), 100203TD
                % Clear STD/RES point from point list
                if nargin==1
                    % Called from object
                    tag=get(gcbo,'tag');
                    num=str2num(tag(7:length(tag)));
                    ClearPoint(gcbf,num);
                else
                    % Clear them all
                    ClearPoint(gcbf,'all');
                end
                
            case lower('SetCurrent')%lower(), 100203TD
                % Set/deselect current point in pointlist
                val=get(gcbo,'value');
                if val==0
                    SetCurrent(gcbf,[]);
                else
                    tag=get(gcbo,'tag');
                    num=str2num(tag(6:length(tag)));
                    SetCurrent(gcbf,num);
                end
                
            case lower('UndoCurrent')%lower(), 100203TD
                % Undo last selection of chosen point
                UndoCurrent(gcbf,varargin{2});
                
            case lower('AddPoint')%lower(), 100203TD
                % Add uicontrols to PointList window:
                if nargin>1
                    userdat=get(varargin{2},'userdata');
                else
                    userdat=get(gcbf,'userdata');
                end
                AddPoint(userdat.PointListWin);
                userdat1=get(userdat.PointListWin,'userdata');
                SetCurrent(userdat.PointListWin,userdat1.NumPoints);
                
            case lower('EstimateError') % Estimate error on each point,%lower(), 100203TD
                userdat=get(gcbf,'userdata');
                rigid=get(findobj(userdat.Parent,'tag','RigidState'),'value');
                [A,Xstd,Xres,Description]=CalculateA(gcbf,rigid);
                userdat.A=A;
                userdat.STDpointsT=cell(userdat.NumPoints,1);
                userdat.RESpointsT=cell(userdat.NumPoints,1);
                userdat.Errs=NaN*ones(userdat.NumPoints,1);
                if not(isempty(A))
                    for j=1:userdat.NumPoints
                        xyzSTD=userdat.STDpoints{j};
                        xyzRES=userdat.RESpoints{j};
                        if not(isempty(xyzSTD)) & not(isempty(xyzRES))
                            xyzSTD=[reshape(xyzSTD{length(xyzSTD)},3,1);1];
                            xyzRES=[reshape(xyzRES{length(xyzRES)},3,1);1];
                            userdat.STDpointsT{j}=inv(A)*xyzSTD;
                            userdat.RESpointsT{j}=A*xyzRES;
                            userdat.STDpointsT{j}=userdat.STDpointsT{j}(1:3);
                            userdat.RESpointsT{j}=userdat.RESpointsT{j}(1:3);
                            userdat.Errs(j)=sqrt(sum((xyzRES(1:3)-userdat.STDpointsT{j}).^2));
                        else
                            userdat.Errs(j)=NaN;
                        end
                    end
                end
                set(gcbf,'userdata',userdat);
                UpdateList(gcbf,'all','on');
                
            case lower('Visualise')%lower(), 100203TD
                % Calculate transformation matrix and visualise overlay
                % Rigid (6 parameter) registration?
                rigid=get(findobj(gcbf,'tag','RigidState'),'value');
                userdat=get(gcbf,'userdata');
                [A,Xstd,Xres,Description]=CalculateA(userdat.PointListWin,rigid);
                if not(isempty(A))
                    % If any 'visualisation' windows are there, close them:
                    delete(findobj('type','figure','tag','IPS_closeme'))
                    % Present "cost" list
                    PointList=userdat.PointListWin;
                    ListData=get(PointList,'userdata');
                    h=Popup(Description,A,Xstd,Xres);
                    set(h,'tag','IPS_closeme');
                    % Temporary visualisation metod:
                    STDdat=get(userdat.STDfig,'userdata');
                    RESdat=get(userdat.RESfig,'userdata');
                    imgPET=RESdat.img;
                    hdrPET=RESdat.hdr;
                    imgMR=STDdat.img;
                    hdrMR=STDdat.hdr;
                    DataStruct.scales.STD=[STDdat.Min STDdat.Max];
                    DataStruct.scales.RES=[RESdat.Min RESdat.Max];
                    clear STDdat;
                    clear RESdat;
                    DataStruct.imgPET=reshape(imgPET,hdrPET.dim(1:3)');
                    DataStruct.hdrPET=hdrPET;
                    DataStruct.imgMR=reshape(imgMR,hdrMR.dim(1:3)');
                    DataStruct.hdrMR=hdrMR;
                    DataStruct.A=A;
                    DataStruct.tag='IPS_closeme';
                    clear imgMR;
                    clear imgPET;
                    UpdateList(PointList,'all','off');
                    feval(userdat.VisualCallBack,'LoadData',DataStruct);
                else
                    disp('Warning: Calculation of transformation matrix failed!')
                end
                
            case lower('RemovePoint')%lower(), 100203TD
                % Remove a point from the list
                tag=get(gcbo,'tag');
                num=str2num(tag(5:length(tag)));
                RemovePoint(gcbf,num);
                
            case lower('SavePoints')%lower(), 100203TD
                % Save point definitions
                [File Path]=uiputfile('*.mat','Select filename');
                if not(File==0)
                    userdat=get(gcbf,'userdata');
                    PointList=userdat.PointListWin;
                    ListData=get(PointList,'userdata');
                    Description=cell(1,ListData.NumPoints);
                    for j=1:length(Description)
                        Description{j}=get(findobj(PointList,'tag',['desc_' num2str(j)]),'string');
                        RESpoints{j}=ListData.RESpoints{j}{length(ListData.RESpoints{j})};
                        STDpoints{j}=ListData.STDpoints{j}{length(ListData.STDpoints{j})};
                    end
                    RESdat=get(ListData.RESfig,'userdata');
                    STDdat=get(ListData.STDfig,'userdata');
                    if not(isempty(RESdat))
                        REShdr=RESdat.hdr;
                        clear RESdat;
                    else
                        REShdr.name='undefined!';
                        disp('Warning: No reslice dataset is loaded - saved filename undefined!');
                    end
                    if not(isempty(STDdat))
                        STDhdr=STDdat.hdr;
                        clear STDdat;
                    else
                        STDhdr.name='undefined!';
                        disp('Warning: No standard dataset is loaded - saved filename undefined!');
                    end
                    filetype='RegistratePointList';
                    save([Path File],'RESpoints','STDpoints','STDhdr','REShdr','Description','filetype');
                    userdat.saved=1;
                    set(gcbf,'userdata',userdat);
                else
                    disp('File save cancelled');
                end
                
            case lower('LoadPoints')%lower(), 100203TD
                % Load point definitons
                userdat=get(gcbf,'userdata');
                PointList=userdat.PointListWin;
                [File Path]=uigetfile('*.mat','Select point definition file');
                if not(File==0)
                    PointStruct=load([Path File]);
                    if isfield(PointStruct,'tmp');
                        Choices={'STD pointset','RES pointset'};
                        [Choice,Ok]=listdlg('PromptString',['Old registrate' ...
                            ' format - select RES/STD '],'SelectionMode', ...
                            'single','ListString',Choices);
                        if Ok==0
                            disp('Load cancelled');
                            return
                        end
                        [File Path]=uigetfile('*.mat','Select another point definition file');
                        if File==0
                            disp('Load cancelled');
                            return
                        end
                        PointStruct1=load([Path File]);
                        if Choice==1
                            for j=1:length(PointStruct1.tmp.ud)
                                PointStruct.RESpoints{j}=PointStruct1.tmp.ud{j}.val';
                                PointStruct.STDpoints{j}=PointStruct.tmp.ud{j}.val';
                                PointStruct.Description{j}=PointStruct.tmp.ud{j}.str;
                            end
                        else
                            for j=1:length(PointStruct1.tmp.ud)
                                PointStruct.RESpoints{j}=PointStruct.tmp.ud{j}.val';
                                PointStruct.STDpoints{j}=PointStruct1.tmp.ud{j}.val';
                                PointStruct.Description{j}=PointStruct.tmp.ud{j}.str;
                            end
                        end
                        PointStruct=rmfield(PointStruct,'tmp');
                        AddPoints(PointList,PointStruct);
                        userdat.saved=1;
                        set(gcbf,'userdata',userdat);
                    elseif isfield(PointStruct,'filetype') & ...
                            strcmp(PointStruct.filetype,'RegistratePointList') % New format
                        AddPoints(PointList,PointStruct);
                    else
                        error(['Selected file ' Path File ' is not a point definition file!'])
                    end
                else
                    disp('Load cancelled');
                end
                
            case lower('Reslice') % Reslice image(s),%lower(), 100203TD
                userdat=get(gcbf,'userdata');
                if isempty(userdat.STDfig) | isempty(userdat.RESfig)
                    error('Both standard and reslice image must be loaded prior to reslicing!')
                else
                    rigid=get(findobj(gcbf,'tag','RigidState'),'value');
                    [A,Xstd,Xres,Description]=CalculateA(userdat.PointListWin,rigid);
                    if not(isempty(A))
                        RESdat=get(userdat.RESfig,'userdata');
                        STDdat=get(userdat.STDfig,'userdata');
                        Choices={RESdat.hdr.name,STDdat.hdr.name};
                        [Choice,Ok]=listdlg('PromptString','Select input image',...
                            'SelectionMode','single','ListString',Choices);
                        if not(Ok==0)
                            if Choice==1
                                Struct.hdrI=RESdat.hdr;
                                Struct.hdrO=STDdat.hdr;
                                Struct.A=A;
                            else
                                Struct.hdrI=STDdat.hdr;
                                Struct.hdrO=RESdat.hdr;
                                Struct.A=inv(A);
                            end
                            [File Path]=uiputfile('*.img','Select output filename');
                            if not(File==0)
                                [tmp File]=fileparts(File);
                                Struct.hdrO.name=File;
                                Struct.hdrO.path=Path;
                                Struct.hdrO.descr='Created using Registrate';
                                Struct.hdrO.pre=Struct.hdrI.pre;
                                Struct.hdrO.lim=Struct.hdrI.lim;
                                Struct.hdrO.scale=Struct.hdrI.scale;
                                Struct.hdrO.offset=Struct.hdrI.offset;
                                Struct.hdrO=EditHdr('Input',Struct.hdrO,'Lock','Default');
                                message=ResliceWarp(Struct);
                                disp(message);
                            else
                                disp('Write cancelled')
                            end
                        else
                            disp('Write cancelled')
                        end
                    else
                        disp('Warning: Calculation of transformation matrix failed!')
                    end
                end
                
            case lower('End') % Close window, %lower(), 100203TD
                % What kind of window is trying to close us?
                fig=gcbf;
                if not(strcmp(get(gcbf,'tag'),'Registrate'))
                    userdat=get(fig,'userdata');
                    fig=userdat.Parent;
                end
                userdat=get(fig,'userdata');
                %______________________________________________________________________________
                % Save registration matrix in air-format, 110203TD
                % If a air filename is given
                %Add isfield(userdat,'files') 010803TD
                if(isfield(userdat,'files') & isfield(userdat.files,'AIR'))
                    Struct.hdrO=ReadAnalyzeHdr(userdat.files.STD);
                    Struct.hdrI=ReadAnalyzeHdr(userdat.files.RES{1});
                    
                    %Get A matrix saved in PointList window, 010803TD
                    userdatPointList=get(userdat.PointListWin,'userdata');%010803TD
                    userdat.A=userdatPointList.A;%010803TD
                    
                    if(isempty(userdat.A))%No co-registration!!
                        userdat.A=eye(4,4);
                    end
                    Struct.A=userdat.A;
                    Struct.descr='Saved from IPS';
                    message=SaveAir(userdat.files.AIR,Struct);
                end
                %______________________________________________________________________________
                
                % How were we started?
                if strcmp(userdat.State,'StandAlone')
                    % Politely ask if we want to end
                    answer=questdlg('Do you want to end Registrate?');
                    if strcmp(answer,'Yes')
                        % Save data?
                        answer=questdlg('Do you want to save your data?');
                        if strcmp(answer,'Yes');
                            Registrate('SavePoints');
                            answer=questdlg('Do you want to reslice an image?');
                            if strcmp(answer,'Yes');
                                Registrate('Reslice');
                            end
                        end
                        delete(userdat.RESfig);
                        delete(userdat.STDfig);
                        delete(userdat.PointListWin);
                        delete(fig);
                        delete(findobj('type','figure','tag','IPS_closeme'));
                    else
                        disp('Close cancelled')
                    end
                elseif strcmp(userdat.State,'Module')
                    % Get the transformation parms
                    rigid=get(findobj(fig,'tag','RigidState'),'value');
                    [A,Xstd,Xres,Description]= CalculateA(userdat.PointListWin,rigid,'exit');
                    if isempty(A)
                        A=diag([1 1 1 1]);
                    else
                        if userdat.saved==0
                            answer=questdlg('You are adviced to save your point definitions before exiting. Save them now?');
                            if strcmp(answer,'Yes')
                                Registrate('SavePoints');
                            end
                        end
                    end
                    Aall=cell(userdat.ResMax,1);
                    Aall{userdat.ResNumber}=A;
                    feval(userdat.ReturnFcn,'ReturningData',userdat.parent,Aall);
                    delete(userdat.RESfig);
                    delete(userdat.STDfig);
                    delete(userdat.PointListWin);
                    delete(fig)
                    delete(findobj('type','figure','tag','IPS_closeme'));
                else
                    error(['The given program state ' userdat.State ' is unknown!']);
                end
                
            otherwise
                error(['Task ' task ' not understood!']);
        end
        for j=1:length(Mainfig)
            if isobj(Mainfig(j))
                set(Mainfig(j),'pointer','arrow');
                ud=get(Mainfig(j),'userdata');
                if isfield(ud,'STDfig')
                    set(ud.STDfig,'pointer','arrow');
                end
                if isfield(ud,'STDfig')
                    set(ud.RESfig,'pointer','arrow');
                end
                if isfield(ud,'PointListWin')
                    set(ud.PointListWin,'pointer','arrow');
                end
            end
        end
    else
        error('First parameter must be a string!')
    end
end


function fig=Popup(Description,A,Xstd,Xres)
%
% Function to pop up registration "cost"
%
N=2+length(Description);
h=1/N;
fig=figure('numbertitle','off','name','Registration Cost','units','normalized',...
    'position',[0.025 0.95-N*0.025 0.5 N*0.025],'menubar','none');
ax=axes('position',[0 0 1 1]);
axis off
text(0.1,1-h/2,'\bf Point Description','horizontalalignment','center','verticalalignment','top')
text(0.3,1-h/2,'\Delta x','horizontalalignment','center','verticalalignment','top')
text(0.5,1-h/2,'\Delta y','horizontalalignment','center','verticalalignment','top')
text(0.7,1-h/2,'\Delta z','horizontalalignment','center','verticalalignment','top')
text(0.9,1-h/2,'(\Sigma \Delta x_i^2)^�','horizontalalignment','center','verticalalignment','top')
text(0.1,h/2,'\bf Average','horizontalalignment','center','verticalalignment','top')
col1=[0.7 0.7 0.7];
col2=[0.6 0.6 0.6];
Dif=zeros(N-2,4);
for j=1:N-2
    if mod(j,2)==0
        col=col2;
    else
        col=col1;
    end
    uicontrol('parent',fig,'units','normalized','style','edit','position',[0 1-(j+1)*h 0.2 h],...
        'backgroundcolor',col,'String',Description{j},'enable','inactive');
    xyzres=A*Xres(:,j);
    xyzres=xyzres(1:3)';
    xyzstd=Xstd(1:3,j)';
    Dif(j,1:3)=xyzstd-xyzres;
    Dif(j,4)=sqrt(sum(Dif(j,1:3).^2));
    uicontrol('parent',fig,'units','normalized','style','edit','position',[0.2 1-(j+1)*h 0.2 h],...
        'backgroundcolor',col,'String',num2str(Dif(j,1)),'enable','inactive');
    uicontrol('parent',fig,'units','normalized','style','edit','position',[0.4 1-(j+1)*h 0.2 h],...
        'backgroundcolor',col,'String',num2str(Dif(j,2)),'enable','inactive');
    uicontrol('parent',fig,'units','normalized','style','edit','position',[0.6 1-(j+1)*h 0.2 h],...
        'backgroundcolor',col,'String',num2str(Dif(j,3)),'enable','inactive');
    uicontrol('parent',fig,'units','normalized','style','edit','position',[0.8 1-(j+1)*h 0.2 h],...
        'backgroundcolor',col,'String',num2str(Dif(j,4)),'enable','inactive');
end
col=get(fig,'color');
uicontrol('parent',fig,'units','normalized','style','edit','position',[0.2 0 0.2 h],...
    'backgroundcolor',col,'String',num2str(mean(Dif(:,1))),'enable','inactive','fontweight','bold');
uicontrol('parent',fig,'units','normalized','style','edit','position',[0.4 0 0.2 h],...
    'backgroundcolor',col,'String',num2str(mean(Dif(:,2))),'enable','inactive','fontweight','bold');
uicontrol('parent',fig,'units','normalized','style','edit','position',[0.6 0 0.2 h],...
    'backgroundcolor',col,'String',num2str(mean(Dif(:,3))),'enable','inactive','fontweight','bold');
uicontrol('parent',fig,'units','normalized','style','edit','position',[0.8 0 0.2 h],...
    'backgroundcolor',col,'String',num2str(mean(Dif(:,4))),'enable','inactive','fontweight','bold');

function fig=SetData(Struct,Type,Mainfig)
%
% Does a call to Slice3 according to 'Type' - 'RES' / 'STD'
%
if not(isempty(Struct))
    if strcmp(Type,'RES')
        Struct.cmap=hot(64);
        Struct.title=[Struct.hdr.name ' - reslice'];
        Struct.EndCallBack='Registrate(''InputCoords'',''RES'',[])';
    else
        Struct.cmap=gray(64);
        Struct.title=[Struct.hdr.name ' - standard'];
        Struct.EndCallBack='Registrate(''InputCoords'',''STD'',[])';
    end
    Struct.ThresState=0;
    Struct.AlignMode=0;
    Struct.Transform=diag([1 1 1 1]);
    Struct.Threshold=0.5;
    x=mean(Struct.hdr.siz(1)*([1:Struct.hdr.dim(1)]-Struct.hdr.origin(1)));
    y=mean(Struct.hdr.siz(2)*([1:Struct.hdr.dim(2)]-Struct.hdr.origin(2)));
    z=mean(Struct.hdr.siz(3)*([1:Struct.hdr.dim(3)]-Struct.hdr.origin(3)));
    Struct.img=reshape(Struct.img,Struct.hdr.dim(1:3)');
    Struct.coords=[x y z];
    Struct.Slaves=[];
    
    %_______________________________________________________________
    
    [Struct.Min,Struct.Max]=findLim(Struct.img);
    
    % DISABLE 280103TD Struct.Min=double(min(img(:)));
    % DISABLE 280103TD Struct.Max=double(max(img(:)));
    %_______________________________________________________________
    
    
    
    Struct.Zoom=0;
    Struct.Parent=Mainfig(1);
    fig=Slice3('Startup',Struct);
    userdat=get(fig,'userdata');
    Ecb=userdat.EndCallBack;
    Ecb=Ecb(1:length(Ecb)-3);
    userdat.EndCallBack=[Ecb num2str(fig) ')'];
    set(fig,'closerequestfcn','Registrate(''End'')','userdata',userdat);
else
    fig=[];
end
userdat=get(Mainfig,'userdata');
eval(['userdat.' Type 'fig=fig;']);
set(Mainfig,'userdata',userdat);
ListWin=userdat.PointListWin;
userdat=get(ListWin,'userdata');
eval(['userdat.' Type 'fig=fig;']);
set(ListWin,'userdata',userdat);

function AddPoints(fig,PointStruct)
% Fill in point definitions into pointlist
userdat=get(fig,'userdata');
if userdat.NumPoints>0
    answer=questdlg('Erase currently defined points?');
    if not(strcmp(answer,'Yes'))
        disp('Load cancelled');
        return
    end
    userdat.A=[];
    set(fig,'userdata',userdat);
    SetCurrent(fig,[]);
    js=fliplr(1:userdat.NumPoints);
    for j=1:length(js)
        RemovePoint(fig,'all');
    end
end
if isfield(PointStruct,'STDhdr')
    STDdat=get(userdat.STDfig,'userdata');
    RESdat=get(userdat.RESfig,'userdata');
    if not(isempty(STDdat))
        STDhdr=STDdat.hdr;
        clear STDdat;
        [tmp1 name1]=fileparts(STDhdr.name);
        [tmp2 name2]=fileparts(PointStruct.STDhdr.name);
        if not(strcmp(name1,name2))
            disp('Warning: STD header names do not match!');
        end
    end
    if not(isempty(RESdat))
        REShdr=RESdat.hdr;
        clear RESdat;
        [tmp1 name1]=fileparts(REShdr.name);
        [tmp2 name2]=fileparts(PointStruct.REShdr.name);
        if not(strcmp(name1,name2))
            disp('Warning: RES header names do not match!');
        end
    end
end
for j=1:length(PointStruct.RESpoints)
    AddPoint(fig);
    PutData(fig,j,PointStruct.Description{j},PointStruct.STDpoints{j},PointStruct.RESpoints{j});
end

function PutData(fig,num,Description,STDpoints,RESpoints)
% Put data in PointList Window
userdat=get(fig,'userdata');
set(findobj(fig,'tag',['desc_' num2str(num)]),'string',Description);
STDpointsCell{1}=STDpoints;
RESpointsCell{1}=RESpoints;
userdat.STDpoints{num}=STDpointsCell;
userdat.RESpoints{num}=RESpointsCell;
userdat.Errs(num)=NaN;
set(fig,'userdata',userdat);
UpdateList(fig,num);

function [A,Xstd,Xres,Description]=CalculateA(PointListWin,rigid,flag)
% Calculate transformation matrix
if nargin==2
    flag='';
end
userdat=get(PointListWin,'userdata');
A=[];
Xstd=[];
Xres=[];
Count=1;
for j=1:userdat.NumPoints
    RESpointj=userdat.RESpoints{j};
    STDpointj=userdat.STDpoints{j};
    if not(isempty(RESpointj)) & not(isempty(STDpointj))
        RESpointj=reshape(RESpointj{length(RESpointj)},[3 1]);
        STDpointj=reshape(STDpointj{length(STDpointj)},[3 1]);
        Xres=[Xres RESpointj];
        Xstd=[Xstd STDpointj];
        Description{Count}=get(findobj(PointListWin,'tag',['desc_' num2str(j)]),'string');
        Count=Count+1;
    end
end
siz=size(Xres);
if rigid==1
    MinPoints=3;
else
    MinPoints=4;
end
if siz(2)<MinPoints
    A=[];
    Xstd=[];
    Xres=[];
    Description=[];
else
    if rigid==1
        [A,V]=rigtrans(Xres,Xstd);
        Xres=[Xres; ones(1,siz(2))];
        Xstd=[Xstd; ones(1,siz(2))];
    else
        Xres=[Xres; ones(1,siz(2))];
        Xstd=[Xstd; ones(1,siz(2))];
        if rank(inv(Xres*Xres')) == 4
            A=Xstd*Xres'*inv(Xres*Xres');
        else
            A=[];
        end
    end
end

function fig=SetupWindows
% Function to set up the windows

fig=figure('units','normalized','position',...
    [0.7  0.7 0.3 0.2],...
    'numbertitle','off',...
    'tag','RegistrateMainWin',...
    'Resize','On',...
    'tag','Registrate',...
    'CloseRequestFcn','Registrate(''End'')',...
    'menubar','none','name','IPS - Interactive Point Selection');


vertSize = .2;
vertDiff = 0.05;
vertOffset = 0.01;
diff = 0.02;

hortSize = .99;
hortsDiff = .05;
hortOffset = .001;


transcolor = [.7 .7 .7];

figure(fig);
%
% Add point
%
uicontrol('style','pushbutton',...
    'units','normalized',...
    'parent',fig,...
    'backgroundcolor',[.2 .8 .2],...
    'callback','Registrate(''AddPoint'')',...
    'position',[0 0 1 0.2],...
    'string','Add Point');

%
% Load or save point, load volume
%
loadcolor = [.7 .7 .7];
uicontrol('style','pushbutton',...
    'units','normalized',...
    'backgroundcolor',loadcolor,...
    'parent',fig,...
    'callback','Registrate(''ReplaceVolume'',''RES'')',...
    'position',[0.5 0.6 0.5 0.2],...
    'string','Load Spect/PET Volume');


uicontrol('style','pushbutton',...
    'units','normalized',...
    'backgroundcolor',loadcolor,...
    'parent',fig,...
    'callback','Registrate(''SavePoints'')',...
    'position',[0 0.2 1 0.2],...
    'string','Save Point definition');

uicontrol('style','pushbutton',...
    'units','normalized',...
    'backgroundcolor',loadcolor,...
    'parent',fig,...
    'callback','Registrate(''LoadPoints'')',...
    'position',[0 0.4 1 0.2],...
    'string','Load Point definition');


uicontrol('style','pushbutton',...
    'units','normalized',...
    'backgroundcolor',loadcolor,...
    'parent',fig,...
    'callback','Registrate(''ReplaceVolume'',''STD'')',...
    'position',[0 0.6 0.5 0.2],...
    'string','Load Template Volume');

uicontrol('style','pushbutton',...
    'units','normalized',...
    'backgroundcolor',loadcolor,...
    'parent',fig,...
    'callback','Registrate(''Visualise'')',...
    'position',[0 0.8 1/3 0.2],...
    'string','Visualise registration');

uicontrol('style','pushbutton',...
    'units','normalized',...
    'backgroundcolor',loadcolor,...
    'parent',fig,...
    'callback','Registrate(''Reslice'')',...
    'position',[1/3 0.8 1/3 0.2],...
    'string','Reslice Image');


uicontrol('style','togglebutton',...
    'units','normalized',...
    'backgroundcolor',loadcolor,...
    'parent',fig,...
    'position',[2/3 0.8 1/3 0.2],...
    'string','Rigid transformation','tag','RigidState',...
    'value',1);

ud.A = [];
set(fig,'userdata',ud);

% Set up point-list interface
fig(2)=figure('numbertitle','off','menubar','none','name','Point List','units', ...
    'normalized','position',[0.05 0.8 0.75 0.02],'CloseRequestFcn','Registrate(''End'')','tag','PointList');

% Standard / Reslice / Error labels
uicontrol('style','text','string','Standard','units','normalized','position',...
    [0.3 0 2*0.2/3 1],'backgroundcolor','blue','foregroundcolor','white',...
    'fontweight','bold','tag','STDlabel');
uicontrol('style','text','string','Reslice','units','normalized','position',...
    [0.7 0 2*0.2/3 1],'backgroundcolor','blue','foregroundcolor','white',...
    'fontweight','bold','tag','RESlabel');

uicontrol('style','pushbutton','string','Est. Error','units','normalized','position',...
    [1-0.2/3 0 0.2/3 1],'backgroundcolor','red','foregroundcolor','white',...
    'fontweight','bold','tag','ERRlabel','callback','Registrate(''EstimateError'')');

% Undo buttons
uicontrol('parent',fig(2),'style','pushbutton','string','Undo',...
    'units','normalized','position',[0.3+2*0.2/3 0 0.2/3 1],...
    'tag','undo_STD',...
    'callback','Registrate(''UndoCurrent'',''STD'')');

uicontrol('parent',fig(2),'style','pushbutton','string','Undo',...
    'units','normalized','position',[0.7+2*0.2/3 0 0.2/3 1],...
    'tag','undo_RES',...
    'callback','Registrate(''UndoCurrent'',''RES'')');

userdat.NumPoints=0;
userdat.Parent=fig(1);
userdat.Current=[];
userdat.A=[];
set(fig(2),'userdata',userdat);
ud.PointListWin=fig(2);
ud.saved=0;
set(fig(1),'userdata',ud);

function AddPoint(h)
%
% Add uicontrol entries for a new pointset
%

userdat = get(h,'userdata');
OldPos=get(h,'position');
NewPos=OldPos;
NewPos(4)=(userdat.NumPoints+2)*OldPos(4)/(userdat.NumPoints+1);
NewPos(2)=OldPos(2)-(NewPos(4)-OldPos(4));

userdat.NumPoints=userdat.NumPoints+1;
userdat.RESpoints{userdat.NumPoints}=[];
userdat.STDpoints{userdat.NumPoints}=[];
userdat.Errs(userdat.NumPoints)=NaN;
NewHeight=1/(userdat.NumPoints+1);
OldHeight=1/(userdat.NumPoints);
uiconts=findobj('parent',h,'type','uicontrol');
for j=1:length(uiconts)
    pos=get(uiconts(j),'position');
    if pos(2)==0
        pos(2)=NewHeight;
    else
        pos(2)=(1+pos(2)/OldHeight)*NewHeight;
    end
    pos(4)=NewHeight;
    set(uiconts(j),'position',pos);
end
set(h,'position',NewPos,'userdata',userdat);
% Status indicator (green when point is selected)
uicontrol('parent',h,'style','frame','string','',...
    'units','normalized','position',[0 0 1 NewHeight],...
    'tag',['stat_' num2str(userdat.NumPoints)]);
% Editable point description string
uicontrol('parent',h,'style','edit','string','Write a desription',...
    'units','normalized','position',[0 0 0.2 NewHeight],...
    'tag',['desc_' num2str(userdat.NumPoints)],...
    'CallBack','Registrate(''SetCurrent'')');
% Editable x/y/z value for point in Standard space
uicontrol('parent',h,'style','edit','string','',...
    'units','normalized','position',[0.3 0 0.2/3 NewHeight],...
    'tag',['stdx_' num2str(userdat.NumPoints)],'backgroundcolor',...
    'blue','foregroundcolor','white','enable','inactive');
uicontrol('parent',h,'style','edit','string','',...
    'units','normalized','position',[0.3+0.2/3 0 0.2/3 NewHeight],...
    'tag',['stdy_' num2str(userdat.NumPoints)],'backgroundcolor',...
    'blue','foregroundcolor','white','enable','inactive');
uicontrol('parent',h,'style','edit','string','',...
    'units','normalized','position',[0.3+2*0.2/3 0 0.2/3 NewHeight],...
    'tag',['stdz_' num2str(userdat.NumPoints)],'backgroundcolor',...
    'blue','foregroundcolor','white','enable','inactive');
% Point controls Remove/Edit/Clear
uicontrol('parent',h,'style','pushbutton','string','Remove',...
    'units','normalized','position',[0.5 0 0.2/3 NewHeight],...
    'tag',['rem_' num2str(userdat.NumPoints)],...
    'CallBack','Registrate(''RemovePoint'')');
uicontrol('parent',h,'style','togglebutton','string','Edit',...
    'units','normalized','position',[0.5+0.2/3 0 0.2/3 NewHeight],...
    'tag',['edit_' num2str(userdat.NumPoints)],...
    'callback','Registrate(''SetCurrent'')');
uicontrol('parent',h,'style','pushbutton','string','Clear',...
    'units','normalized','position',[0.5+2*0.2/3 0 0.2/3 NewHeight],...
    'tag',['clear_' num2str(userdat.NumPoints)],...
    'CallBack','Registrate(''ClearPoint'')');

% Editable x/y/z value for point in Reslice space
uicontrol('parent',h,'style','edit','string','',...
    'units','normalized','position',[0.7 0 0.2/3 NewHeight],...
    'tag',['resx_' num2str(userdat.NumPoints)],'backgroundcolor',...
    'blue','foregroundcolor','white','enable','inactive');
uicontrol('parent',h,'style','edit','string','',...
    'units','normalized','position',[0.7+0.2/3 0 0.2/3 NewHeight],...
    'tag',['resy_' num2str(userdat.NumPoints)],'backgroundcolor',...
    'blue','foregroundcolor','white','enable','inactive');
uicontrol('parent',h,'style','edit','string','',...
    'units','normalized','position',[0.7+2*0.2/3 0 0.2/3 NewHeight],...
    'tag',['resz_' num2str(userdat.NumPoints)],'backgroundcolor',...
    'blue','foregroundcolor','white','enable','inactive');
% Error box:
uicontrol('parent',h,'style','edit','string','',...
    'units','normalized','position',[1-0.2/3 0 0.2/3 NewHeight],...
    'tag',['err_' num2str(userdat.NumPoints)],'backgroundcolor',...
    'red','foregroundcolor','white','enable','off'); ...
    

function DeletePoint(h,n);
%  Remove uicontrol entries pointset n

delete(findobj(h,'tag',['desc_' num2str(n)]));
delete(findobj(h,'tag',['stat_' num2str(n)]));
delete(findobj(h,'tag',['stdx_' num2str(n)]));
delete(findobj(h,'tag',['stdy_' num2str(n)]));
delete(findobj(h,'tag',['stdz_' num2str(n)]));
delete(findobj(h,'tag',['rem_' num2str(n)]));
delete(findobj(h,'tag',['edit_' num2str(n)]));
delete(findobj(h,'tag',['clear_' num2str(n)]));
delete(findobj(h,'tag',['resx_' num2str(n)]));
delete(findobj(h,'tag',['resy_' num2str(n)]));
delete(findobj(h,'tag',['resz_' num2str(n)]));
delete(findobj(h,'tag',['undo_' num2str(n)]));
delete(findobj(h,'tag',['err_' num2str(n)]));

function RemovePoint(h,n)
%
% Remove uicontrol entries pointset n and adjust window
%

userdat = get(h,'userdata');
OldPos=get(h,'position');
NewPos=OldPos;
if ischar(n) & strcmp(n,'all')
    for j=1:userdat.NumPoints
        DeletePoint(h,j);
    end
    NewPos(4)=OldPos(4)/(userdat.NumPoints+1);
    NewPos(2)=OldPos(2)+(OldPos(4)-NewPos(4));
    userdat.NumPoints=0;
else
    DeletePoint(h,n);
    userdat.NumPoints=userdat.NumPoints-1;
    NewPos(4)=(userdat.NumPoints+1)*OldPos(4)/(userdat.NumPoints+2);
    NewPos(2)=OldPos(2)+(OldPos(4)-NewPos(4));
end
uiconts=findobj('parent',h,'type','uicontrol');
NewHeight=1/(userdat.NumPoints+1);
OldHeight=1/(userdat.NumPoints+2);
uiconts=findobj('parent',h,'type','uicontrol');
RESpoints=cell(1,userdat.NumPoints);
STDpoints=cell(1,userdat.NumPoints);
Errs=zeros(userdat.NumPoints,1);
STDpointsT=cell(userdat.NumPoints,1);
RESpointsT=cell(userdat.NumPoints,1);
if userdat.NumPoints==0
    for j=1:length(uiconts)
        pos=get(uiconts(j),'position');
        pos(2)=0;
        pos(4)=NewHeight;
        set(uiconts(j),'position',pos)
    end
else
    for j=1:length(uiconts)
        pos=get(uiconts(j),'position');
        p=round((1-pos(2))/OldHeight);
        if p>n+1;
            p=p-1;
        end
        pos(2)=1-p*NewHeight;
        pos(4)=NewHeight;
        tag=get(uiconts(j),'tag');
        score=strfind(tag,'_');
        if not(isempty(score))
            tag=[tag(1:score) num2str(p-1)];
        end
        set(uiconts(j),'position',pos,'tag',tag);
    end
    for j=1:length(userdat.RESpoints)
        if j<n
            RESpoints{j}=userdat.RESpoints{j};
            STDpoints{j}=userdat.STDpoints{j};
            RESpointsT{j}=userdat.RESpointsT{j};
            STDpointsT{j}=userdat.STDpointsT{j};
            Errs(j)=userdat.Errs(j);
        elseif j>n
            RESpoints{j-1}=userdat.RESpoints{j};
            STDpoints{j-1}=userdat.STDpoints{j};
            RESpointsT{j-1}=userdat.RESpointsT{j};
            STDpointsT{j-1}=userdat.STDpointsT{j};
            Errs(j-1)=userdat.Errs(j);
        end
    end
end
userdat.RESpoints=RESpoints;
userdat.STDpoints=STDpoints;
userdat.RESpoints=RESpoints;
userdat.STDpoints=STDpoints;
userdat.Errs=Errs;
set(h,'position',NewPos,'userdata',userdat);
if isfield(userdat,'Current')
    if not(isempty(userdat.Current))
        if userdat.Current==n
            SetCurrent(h,[]);
        else
            if userdat.Current>n
                SetCurrent(h,userdat.Current-1);
            end
        end
    end
end

function SetCurrent(fig,number)
%
% Set which point is beeing edited
%
userdat=get(fig,'userdata');
col=get(fig,'color');
if isempty(number)
    userdat.Current=[];
    % Disable all points:
    set(findobj('parent',fig,'style','togglebutton'),'value',0);
    set(findobj('parent',fig,'style','frame'),'backgroundcolor',col);
else
    for j=1:userdat.NumPoints
        if not(j==number)
            StatTag=['stat_' num2str(j)];
            set(findobj('parent',fig,'tag',StatTag),'backgroundcolor',col);
            TogTag=['edit_' num2str(j)];
            set(findobj('parent',fig,'tag',TogTag),'value',0);
        else
            StatTag=['stat_' num2str(j)];
            set(findobj('parent',fig,'tag',StatTag),'backgroundcolor','green');
            TogTag=['edit_' num2str(j)];
            set(findobj('parent',fig,'tag',TogTag),'value',1);
        end
    end
    drawnow;
    userdat.Current=number;
    STDcoord=userdat.STDpoints{number};
    REScoord=userdat.RESpoints{number};
    if not(isempty(STDcoord))
        STDcoord=STDcoord{length(STDcoord)};
    end
    if not(isempty(REScoord))
        REScoord=REScoord{length(REScoord)};
    end
    if not(isempty(STDcoord)) & not(isempty(REScoord))
        set(fig,'userdata',userdat)
        if not(isempty(userdat.A))
            REScoordT=userdat.A*[reshape(REScoord,3,1);1];
            STDcoordT=inv(userdat.A)*[reshape(STDcoord,3,1);1];
            if not(isempty(userdat.STDfig)) | not(isempty(userdat.STDfig))
                Slice3('UpdatePointOnly',userdat.STDfig,STDcoord,REScoordT(1:3));
                Slice3('UpdatePointOnly',userdat.RESfig,REScoord,STDcoordT(1:3));
            end
        else
            if not(isempty(userdat.STDfig)) | not(isempty(userdat.STDfig))
                Slice3('UpdatePointOnly',userdat.STDfig,STDcoord);
                Slice3('UpdatePointOnly',userdat.RESfig,REScoord);
            end
        end
    elseif not(isempty(STDcoord))
        set(fig,'userdata',userdat)
        Slice3('UpdatePointOnly',userdat.STDfig,STDcoord);
    elseif not(isempty(REScoord))
        set(fig,'userdata',userdat)
        Slice3('UpdatePointOnly',userdat.RESfig,REScoord);
    end
end
set(fig,'userdata',userdat)

function UndoCurrent(fig,modality)
%
% Remove latest change of current point
%
userdat=get(fig,'userdata');
number=userdat.Current;
if not(isempty(number))
    if strcmp(modality,'STD')
        STDcoord=userdat.STDpoints{number};
        if length(STDcoord)>1
            STDcoordTMP=cell(length(STDcoord)-1,1);
            STDcoordTMP(:)=STDcoord(1:length(STDcoord)-1);
            STDcoord=STDcoordTMP;
        end
        userdat.STDpoints{number}=STDcoord;
        if not(isempty(STDcoord))
            STDcoord=STDcoord{length(STDcoord)};
            set(fig,'userdata',userdat)
            Slice3('UpdatePoint',userdat.STDfig,STDcoord);
        end
    elseif strcmp(modality,'RES')
        REScoord=userdat.RESpoints{number};
        if length(REScoord)>1
            REScoordTMP=cell(length(REScoord)-1,1);
            REScoordTMP(:)=REScoord(1:length(REScoord)-1);
            REScoord=REScoordTMP;
        end
        userdat.RESpoints{number}=REScoord;
        if not(isempty(REScoord))
            REScoord=REScoord{length(REScoord)};
            set(fig,'userdata',userdat)
            Slice3('UpdatePoint',userdat.RESfig,REScoord);
        end
    end
end

function ClearPoint(fig,number)
% Clear x/y/z coordinates associated wth number
userdat=get(fig,'userdata');
if isnumeric(number)
    userdat.STDpoints{number}=[];
    userdat.RESpoints{number}=[];
elseif strcmp(number,'all');
    userdat.STDpoints{:}=[];
    userdat.RESpoints{:}=[];
end
set(fig,'userdata',userdat);
UpdateList(fig,number);

function UpdateList(fig,number,myflag)
% Update point strings on interface

userdat=get(fig,'userdata');
rigid=get(findobj('tag','RigidState'),'value');
A=userdat.A;
set(fig,'userdata',userdat);
if ischar(number) & strcmp('all',number)
    js=1:userdat.NumPoints;
elseif isnumeric(number)
    js=number;
end
for j=1:length(js)
    xyzAll=userdat.STDpoints{js(j)};
    if not(isempty(xyzAll))
        xyz=xyzAll{length(xyzAll)};
        x=xyz(1);
        y=xyz(2);
        z=xyz(3);
    else
        x=[];
        y=[];
        z=[];
    end
    set(findobj('parent',fig,'tag',['stdx_' num2str(js(j))]),'string',num2str(x));
    set(findobj('parent',fig,'tag',['stdy_' num2str(js(j))]),'string',num2str(y));
    set(findobj('parent',fig,'tag',['stdz_' num2str(js(j))]),'string',num2str(z));
    xyzAll=userdat.RESpoints{js(j)};
    if not(isempty(xyzAll))
        xyz=xyzAll{length(xyzAll)};
        x=xyz(1);
        y=xyz(2);
        z=xyz(3);
    else
        x=[];
        y=[];
        z=[];
    end
    set(findobj('parent',fig,'tag',['resx_' num2str(js(j))]),'string',num2str(x));
    set(findobj('parent',fig,'tag',['resy_' num2str(js(j))]),'string',num2str(y));
    set(findobj('parent',fig,'tag',['resz_' num2str(js(j))]),'string',num2str(z));
    set(findobj('parent',fig,'tag',['err_' num2str(js(j))]),'string',num2str(userdat.Errs(js(j))));
end
if exist('myflag')
    for j=1:userdat.NumPoints
        set(findobj('parent',fig,'tag',['err_' num2str(j)]),'enable',myflag)
    end
end
for j=1:userdat.NumPoints
    if not(isempty(userdat.RESpoints{j})) & not(isempty(userdat.STDpoints{j}))
        if j==userdat.Current;
            Xres=userdat.RESpoints{j}{length(userdat.RESpoints{j})};
            Xstd=userdat.STDpoints{j}{length(userdat.STDpoints{j})};
            if isnan(userdat.Errs(j))
                Slice3('UpdatePointOnly',userdat.RESfig,Xres);
                Slice3('UpdatePointOnly',userdat.STDfig,Xstd);
            else
                Slice3('UpdatePointOnly',userdat.RESfig,Xres,userdat.STDpointsT{j});
                Slice3('UpdatePointOnly',userdat.STDfig,Xstd,userdat.RESpointsT{j});
            end
        end
    end
end

function InputPoint(PointList,target,coords);
% We are recieving a new point set
userdat=get(PointList,'userdata');
% Any points there yet?
eval(['OldCoords=userdat.' target 'points{userdat.Current};']);
Coords=cell(length(OldCoords)+1,1);
if not(isempty(OldCoords))
    LastCoord=OldCoords{length(OldCoords)};
else
    LastCoord=[0 0 0]';
end
if not(all(LastCoord(:)==coords(:)))
    % The following if sentece is seemingly needed to make the
    % program run on matlab 6.0...
    if not(isempty(OldCoords))
        Coords(1:length(OldCoords))=OldCoords;
    end
    Coords{length(Coords)}=coords;
else
    Coords=OldCoords;
end
eval(['userdat.' target 'points{userdat.Current}=Coords;']);
set(PointList,'userdata',userdat);
% Changes made, set 'unsaved' state on main window:
MainWin=userdat.Parent;
ud=get(MainWin,'userdata');
ud.saved=0;
set(MainWin,'userdata',ud);
UpdateList(PointList,userdat.Current,'off');
%UpdateList(PointList,'all','off');
