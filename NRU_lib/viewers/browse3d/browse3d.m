function varargout=browse3d(arg1,arg2,arg3)
%
% Tool for browsing an analyze images in 3D.
% Coordinates given in mm. 
%
% Different calls of the browse3d function:
%
%       1) BROWSE3D; batch mode. Initialize browse3d GUI and let user load files    
%
%       2) HANDLE_FIG=BROWSE3D; setup and return handel to initialized browse2d GUI
%               - HANDLE_FIG: handel to initialized browse3d GUI.
%
%       3) BROWSE3D('LOADDATA',HANDLE_FIG,FILE_NAME); Use handle to init. browse3d GUI, and given name of input files
%               - HANDLE_FIG: 'empty' OR as in 2)
%               - FILE_NAME: name and path to input analyze dataset
%
% Call functions:
%   - Slice3
%   - LoadAnalyze
%________________________________________________________
% PW, NRU, sep 2001
% Updates:
% - lower(arg1), more user friendly in switch. TD, NRU, jan 2003
% - Improve the contrast of the image on the screeb, 280103TD, NRU
%

if nargin==0
    % Starting up - build window
    fig=figure('numbertitle','off','name','browse3D',...
        'units','normalized','menubar','none',...
        'position',[0.0 0.8 0.15 0.1],'closerequestfcn',...
        'browse3d(''Exit'')');
    
    uicontrol('style','pushbutton','string','Load Analyze dataset',...
        'units','normalized','position',[0 0.5 1 0.5],...
        'callback','browse3d(''Load'')');
    uicontrol('style','pushbutton','string','Exit',...
        'units','normalized','position',[0 0 1 0.5],...
        'callback','browse3d(''Exit'')');
    ud.winlist=fig;
    set(fig,'userdata',ud);
    if nargout>0
        varargout{1}=fig;
    end
else
    set(gcbf,'pointer','watch')
    switch lower(arg1)% Set to lower then more user friendly, 280103TD 
    case 'load'
        % Load an analyze dataset
        [File Path]=uigetfile('*.img','Open Analyze dataset');
        if not(File==0)
            File=NoExt([Path File]);
            if exist([File '.hdr'])==2 & exist([File '.img'])==2
                LoadData(gcbf,File)
            else
                disp(['Image hdr/img file ' File ' not existing']);
            end
        else
            disp(['Load Cancelled']);
        end 
    case 'loaddata'
        % Load an analyze dataset - batch mode
        fig=arg2;
        
        %______________________________________________
        %Check if a fig handle is given else made one, 310103TD
        if(isempty(fig))
            % Starting up - build window
            fig=figure('numbertitle','off','name','browse3D',...
                'units','normalized','menubar','none',...
                'position',[0.0 0.8 0.15 0.1],'closerequestfcn',...
                'browse3d(''Exit'')');
            
            uicontrol('style','pushbutton','string','Load Analyze dataset',...
                'units','normalized','position',[0 0.5 1 0.5],...
                'callback','browse3d(''Load'')');
            uicontrol('style','pushbutton','string','Exit',...
                'units','normalized','position',[0 0 1 0.5],...
                'callback','browse3d(''Exit'')');
            ud.winlist=fig;
            set(fig,'userdata',ud);    
        end  

        % And return fig-handle (141103 TR)
        if nargout>0
            varargout{1}=fig;
        end

        %______________________________________________        
        File=arg3;
        File=NoExt([File]);
        if exist([File '.hdr'])==2 & exist([File '.img'])==2
            LoadData(fig,File)
        else
            disp(['Image hdr/img file ' File ' not existing']);
        end
    case 'exit'
        answer=questdlg('Exit browse3d?');
        if strcmp(answer,'Yes')
            ud=get(gcbf,'userdata');
            if length(ud.winlist>1)
                for j=2:length(ud.winlist)
                    if isobj(ud.winlist(j))
                        set(ud.winlist(j),'closerequestfcn','closereq')
                        close(ud.winlist(j))
                    end
                end
            end
            set(ud.winlist(1),'closerequestfcn','closereq');
            close(ud.winlist(1));
        end
    end  
    if exist('gcbf')
        set(gcbf,'pointer','arrow')
    end
end

function filename1=NoExt(filename)
dots=strfind(filename,'.');
if not(isempty(dots))
    dots=dots(length(dots-1));
    filename1=filename(1:dots-1);
else
    filename1=filename;
end

function LoadData(fig,File)
ud=get(fig,'userdata');
[img,hdr]=LoadAnalyze(File);
figs=[];
if not(isempty(img))
    if not(iscell(img))
        Struct.img=reshape(img,hdr.dim(1:3)');
        Struct.hdr=hdr;
        Struct.cmap=gray(64);
        x=mean(hdr.siz(1)*([1:hdr.dim(1)]-hdr.origin(1)));
        y=mean(hdr.siz(2)*([1:hdr.dim(2)]-hdr.origin(2)));
        z=mean(hdr.siz(3)*([1:hdr.dim(3)]-hdr.origin(3)));
        Struct.coords=[x y z];
        Struct.title=hdr.name;
        Struct.EndCallBack='none';
        Struct.Slaves=[];
        
        %_______________________________________________________________
        
        [Struct.Min,Struct.Max,imgType]=findLim(img);
        
        if strcmp(imgType,'PET')
           Struct.cmap=hot(64);
        end
    
            % DISABLE 010104TR Struct.Min=double(min(imgj(:)));
            % DISABLE 010104TR Struct.Max=double(max(imgj(:)));
        %_______________________________________________________________
        
        
        Struct.Zoom=0;
        Struct.Transform=diag([1 1 1 1]);
        Struct.ThresState=0;
        Struct.AlignMode=0;
        Struct.Threshold=0.5;
        figs=Slice3('Startup',Struct);
    else
        for j=1:length(img)
            imgj=img{j};
            Struct.img=reshape(imgj,hdr.dim(1:3)');
            Struct.hdr=hdr;
            Struct.hdr.name=[Struct.hdr.name ' ' num2str(j) ...
                    ' of ' num2str(length(imgj))];
            Struct.cmap=gray(64);
            x=mean(hdr.siz(1)*([1:hdr.dim(1)]-hdr.origin(1)));
            y=mean(hdr.siz(2)*([1:hdr.dim(2)]-hdr.origin(2)));
            z=mean(hdr.siz(3)*([1:hdr.dim(3)]-hdr.origin(3)));
            Struct.coords=[x y z];
            Struct.title=hdr.name;
            Struct.EndCallBack='none';
            Struct.Slaves=[];
            
            %_______________________________________________________________
        
            [Struct.Min,Struct.Max,imgType]=findLim(img);
            
            if strcmp(imgType,'PET')
                Struct.cmap=hot(64);
            end
    
            
            % DISABLE 010104TR Struct.Min=double(min(imgj(:)));
            % DISABLE 010104TR Struct.Max=double(max(imgj(:)));
            %_______________________________________________________________
            
            
            Struct.Zoom=0;
            figs=[figs;Slice3('Startup',Struct)];
        end
    end
else
    Struct=[];
end
if not(isempty(figs))
    ud.winlist=[ud.winlist;figs];
    for j=1:length(ud.winlist)
        if not(ud.winlist(j)==fig)
            for k=1:length(ud.winlist)
                if not(j==k)
                    if not(ud.winlist(k)==fig)
                        Slice3('AddSlave',ud.winlist(j),ud.winlist(k));
                    end
                end
            end
        end
    end
    set(fig,'userdata',ud);
end
