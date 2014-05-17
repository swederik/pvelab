function varargout=browse2d(arg1,arg2,arg3)
% Tool for browsing of an analyze images in 2d.
% Coordinates given in mm. 
%
% Different calls of the browse2d function:
%
%       1) BROWSE2D; batch mode. Initialize browse2d GUI and let user load files    
%
%       2) HANDLE_FIG=BROWSE2D; setup and return handel to initialized browse2d GUI
%               - HANDLE_FIG: handel to initialized browse2d GUI.
%
%       3) BROWSE2D('LOADDATA',HANDLE_FIG,FILE_NAME); Use handle to init. 
%                      browse2d GUI, and given name of input files
%               - HANDLE_FIG: 'empty' OR as in 2)
%               - FILE_NAME: name and path of inputfile analyze dataset
%
% Call functions:
%   - Slice3
%   - ReadAnalyze
%________________________________________________________
% PW, NRU, jan/feb 2001
% Updates:
% - Add lower(arg1): more user friendly in switch. TD, NRU, jan 2003
% - Add 'fileparts' function to ensure removal of fileextion of input file, 170303TD
%

if nargin==0
    % Starting up - build window
    fig=figure('numbertitle','off','name','browse2D',...
        'units','normalized','menubar','none',...
        'position',[0.0 0.8 0.15 0.1],'closerequestfcn',...
        'browse2d(''Exit'')');
    
    uicontrol('style','pushbutton','string','Load Analyze dataset',...
        'units','normalized','position',[0 0.5 1 0.5],...
        'callback','browse2d(''Load'')');
    uicontrol('style','pushbutton','string','Exit',...
        'units','normalized','position',[0 0 1 0.5],...
        'callback','browse2d(''Exit'')');
    ud.winlist=fig;
    set(fig,'userdata',ud)
    if nargout==1
        varargout{1}=fig;
    end
else
    set(gcbf,'pointer','watch')
    switch lower(arg1)% Set to lower then more user friendly, 280103TD 
    case 'loaddata'      
        fig=arg2;
      %___________________________________________________
      %Below insert 070203TD, if figure is not given 
        if(isempty(fig))
            % Starting up - build window
            fig=figure('numbertitle','off','name','browse2D',...
                'units','normalized','menubar','none',...
                'position',[0.0 0.8 0.15 0.1],'closerequestfcn',...
                'browse2d(''Exit'')');
            
            uicontrol('style','pushbutton','string','Load Analyze dataset',...
                'units','normalized','position',[0 0.5 1 0.5],...
                'callback','browse2d(''Load'')');
            uicontrol('style','pushbutton','string','Exit',...
                'units','normalized','position',[0 0 1 0.5],...
                'callback','browse2d(''Exit'')');
            ud.winlist=fig;
            set(fig,'userdata',ud)
        end
        
        % And return fig-handle (141103 TR)
        if nargout>0
            varargout{1}=fig;
        end
       %___________________________________________________
        File=arg3;
        ud=get(fig,'userdata');
        if length(ud.winlist)>1
            for j=2:length(ud.winlist)
                if isobj(ud.winlist(j))
                    udj=get(ud.winlist(j),'userdata');
                    xyz=udj.xyz;
                end
            end 
        end
        if not(exist('xyz'))
            xyz=[];
        end
        %______ Below: To sensure that extension is removed from filename
        if ~isempty(strfind(File,'.img'))||~isempty(strfind(File,'.hdr'))
            [pathstrX,nameX,extX] = fileparts(File);%To get only name of imagefile, 170303TD
            File=fullfile('',pathstrX,nameX);%170303TD
        end
       
        hdr=ReadAnalyzeHdr(File);
        
        % Is this a 4-d dataset?
        res=1;
        if length(hdr.dim)==4 & hdr.dim(4)>1      
            res={};
            prompt={'Enter Frame List'};
            def={['1:1:' num2str(hdr.dim(4))]};
            Title='4D dataset Frame Selection';
            lineno=1;
            res=inputdlg(prompt,Title,lineno,def);
            res=unique(round(eval(res{1})));
            res(res<1)=[];
            res(res>hdr.dim(4))=[];
        end
        if not(isempty(res))
            for k=1:length(res)
                nametag=[];
                if not(length(res)==1)
                    nametag=[' - Frame ' num2str(res(k))];
                end
                fig=Sliceview('Load',File,res(k),nametag,xyz);
                ud.winlist=[ud.winlist;fig];
                set(ud.winlist(1),'userdata',ud);
                udf=get(fig,'userdata');
                udf.Friends=[ud.winlist(2:length(ud.winlist)-1)]';
                set(fig,'userdata',udf)
                if length(ud.winlist)>2
                    for j=2:length(ud.winlist)-1
                        if isobj(ud.winlist(j))
                            udj=get(ud.winlist(j),'userdata');
                            udj.Friends=[udj.Friends fig];
                            set(ud.winlist(j),'userdata',udj)
                        end
                    end 
                end
            end
        else
            disp('Load Cancelled')
        end
    case 'load'
        % Load an analyze dataset
        [File Path]=uigetfile('*.img','Open Analyze dataset');
        if not(File==0)
            File=NoExt([Path File]);
            if exist([File '.hdr'])==2 & exist([File '.img'])==2
                browse2d('LoadData',gcbf,File);
            else
                disp(['Image hdr/img file ' File ' not existing']);
            end
        else
            disp(['Load Cancelled']);
        end 
    case 'exit'
        answer=questdlg('Exit browse2D?');
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
