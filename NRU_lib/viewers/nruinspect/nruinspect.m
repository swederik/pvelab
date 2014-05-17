function nruinspect(varargin)
%
% Simple script to do a visual inspection of coregistered and
% resliced datasets. Coordinates given in mm. 
%
% Different calls of the nruinspect function:
%
%       1) NRUINSPECT; batch mode. Initialize nruinspect GUI and let user load files    
%
%
%       2) NRUINSPECT(['LOADDATA',FILE_NAME); Use given name of input files
%               - FILE_NAME: cell_array containing names or data of inputfiles (analyze format)
%                    example of struct of file_name:                    
%                       FILE_NAME.imgPET: Imagedata or name and path for PET/SPECT  
%                       FILE_NAME.hdrPET: Headerdata or name and path for PET/SPECT
%                       FILE_NAME.imgMR: Imagedata or name and path for PET/SPECT
%                       FILE_NAME.hdrMR: Headerdata or name and path for PET/SPECT
%
%       3) NRUINSPECT(['LOADDATA',[],FILE_NAME); To be compatible with Browse3D and Browse2D
%               - FILE_NAME: cell_array containing names or data of inputfiles (analyze format)
%                    example of struct of file_name:                    
%                       FILE_NAME.imgPET: Imagedata or name and path for PET/SPECT  
%                       FILE_NAME.hdrPET: Headerdata or name and path for PET/SPECT
%                       FILE_NAME.imgMR: Imagedata or name and path for PET/SPECT
%                       FILE_NAME.hdrMR: Headerdata or name and path for PET/SPECT
%
% Call functions:
%   - Slice3
%   - LoadAnalyze
%________________________________________________________
% PW, NRU, 2001
%
% Updates:
% - lower(arg1), more user friendly in switch. TD, NRU, jan 2003
% - Possible to start nruinspect with argument (FILE_NAME) containing name and 
%   path of input analyze files, By TD, jan 2003
% - Make input parameters compatible with Browse3D and Browse2D, 170303 T. Dyrby
% - Make transparency off as default. PJ, 23/08-09

global MatlabVersion;

if nargin==0
    disp('Please select MR/PET datasets to nruinspect');
    [File Path]=uigetfile('*.img','Load MR image');
    MRname=[Path File];
    [File1 Path1]=uigetfile('*.img','Load PET image');
    PETname=[Path1 File1];
    if not(File==0) | not(File1==0)
        [imgMR,hdrMR]=LoadAnalyze(MRname,'single');
        [imgPET,hdrPET]=LoadAnalyze(PETname,'single');
        A=diag([1 1 1 1]);
        DataStruct.imgPET=double(reshape(imgPET,hdrPET.dim(1:3)')); %PET must be in doubles....
        DataStruct.hdrPET=hdrPET;
        DataStruct.imgMR=reshape(imgMR,hdrMR.dim(1:3)');
        DataStruct.hdrMR=hdrMR;
        DataStruct.A=A;
        nruinspect('LoadData',DataStruct);
    else
        disp('File load cancelled');
    end
else
    if strcmp(lower(varargin{1}),'loaddata')%add lower(), by TD 280103
        DataStruct=varargin{2};
        %______ check if input parameters are as Browse3d and Browse2D, 170303TD
        if(isempty(DataStruct))% 170303TD
           DataStruct=varargin{3}; % 170303TD           
        end
        %______ end
        
        if(isstr(DataStruct.imgPET))%Check if input is data or file name, by TD280103
            [imgMR,hdrMR]=LoadAnalyze(DataStruct.imgMR,'single');
            [imgPET,hdrPET]=LoadAnalyze(DataStruct.imgPET,'single');
            A=diag([1 1 1 1]);
            DataStruct.imgPET=double(reshape(imgPET,hdrPET.dim(1:3)')); %PET must be in doubles....
            DataStruct.hdrPET=hdrPET;
            DataStruct.imgMR=reshape(imgMR,hdrMR.dim(1:3)');
            DataStruct.hdrMR=hdrMR;
            DataStruct.A=A;
        end
        
        imgPET=DataStruct.imgPET;        
        hdrPET=DataStruct.hdrPET;
        imgMR=DataStruct.imgMR;
        hdrMR=DataStruct.hdrMR;
        A=DataStruct.A;        
            
        if isfield(DataStruct,'scales');
            ud.mrmin=DataStruct.scales.STD(1);
            ud.mrmax=DataStruct.scales.STD(2);
            ud.petmin=DataStruct.scales.RES(1);
            ud.petmax=DataStruct.scales.RES(2);
        else
            % ---- MR scan -----
            
            [ud.mrmin,ud.mrmax]=findLim(imgMR);

            % ---- PET/SPECT scan ----
            
            [ud.petmin,ud.petmax]=findLim(imgPET);

            % DISABLE 280103TD ud.mrmin=double(min(imgMR(:)));
            % DISABLE 280103TD ud.mrmax=double(max(imgMR(:)));
            % DISABLE 280103TD ud.petmin=double(min(imgPET(:)));
            % DISABLE 280103TD ud.petmax=double(max(imgPET(:)));
        end
        if isfield(DataStruct,'tag')
            tag=DataStruct.tag;
        else
            tag='';
        end
        clear DataStruct;
        fig=SetupWindow;
        set(fig,'numbertitle','off','name',[hdrPET.name ' on ' hdrMR.name])
        ud.PET=double(imgPET); % unfortunately PET imagesc must be doubles
        ud.MR=imgMR;
        ud.view=3;
        ud.hdrMR=hdrMR;
        ud.hdrPET=hdrPET;
        ud.alpha=0.5;
        ud.slice=round(ud.hdrMR.dim(ud.view)/2);
        ud.min=1;
        ud.max=ud.hdrMR.dim(ud.view);
        ud.step=1;
        ud.A=A;
        ud.transp=0;
        ud.UpdateCmap=1;
        xax=hdrMR.siz(1)*([1:hdrMR.dim(1)]-hdrMR.origin(1));
        yax=hdrMR.siz(2)*([1:hdrMR.dim(2)]-hdrMR.origin(2));
        zax=hdrMR.siz(3)*([1:hdrMR.dim(3)]-hdrMR.origin(3));
        ud.cursor=[mean(xax) mean(yax) mean(zax)];
        ud.MRcmap=gray(64);
        ud.PETcmap=hot(64);
        set(fig,'userdata',ud,'tag',tag);
        clear img*
        nruinspect('update',fig);
    elseif strcmp(varargin{1},'updateview')
        views=findobj(gcbf,'tag','view');
        views(views==gcbo)=[];
        set(views,'value',0)
        set(gcbo,'value',1);
        nruinspect('update');
        
    elseif strcmp(varargin{1},'update')
        reimg=0;
        if nargin==2
            figure(varargin{2});
            ud=get(gcf,'userdata');
            fig=gcf;
            set(findobj(fig,'tag','slicemin'),'string',num2str(1));
            set(findobj(fig,'tag','slicemax'),'string',num2str(ud.hdrMR.dim(ud.view)));
            set(findobj(fig,'tag','slice'),'value',round(ud.hdrMR.dim(ud.view)/2),'min',1,'max',ud.hdrMR.dim(ud.view));
            set(findobj(fig,'tag','petmin'),'string',num2str(ud.petmin));
            set(findobj(fig,'tag','petmax'),'string',num2str(ud.petmax));
            set(findobj(fig,'tag','mrmin'),'string',num2str(ud.mrmin));
            set(findobj(fig,'tag','mrmax'),'string',num2str(ud.mrmax));
            set(findobj(fig,'tag','view'),'value',0);
            set(findobj(fig,'tag','view','userdata',ud.view),'value',1);
            set(findobj(fig,'tag','alpha'),'value',ud.alpha);
            reimg=1;
        else
            fig=gcbf;
            ud=get(fig,'userdata');
        end
        alp=get(findobj(fig,'tag','alpha'),'value');
        view=get(findobj(fig,'tag','view','value',1),'userdata');
        petmin=str2num(get(findobj(fig,'tag','petmin'),'string'));
        petmax=str2num(get(findobj(fig,'tag','petmax'),'string'));
        mrmin=str2num(get(findobj(fig,'tag','mrmin'),'string'));
        mrmax=str2num(get(findobj(fig,'tag','mrmax'),'string'));
        slice=ceil(get(findobj(fig,'tag','slice'),'value'));
        transp=get(findobj(fig,'tag','Transparancy'),'value');
        
        % Different alpha?
        if not(alp==ud.alpha)
            ud.alpha=alp;
            reimg=1;      
        end
        % Different transparancy state?
        if not(transp==ud.transp)
            ud.transp=transp;
            reimg=1;
        end
        % Different min/max?
        if not(petmin==ud.petmin)
            reimg=1;
            ud.petmin=petmin;
        end
        if not(petmax==ud.petmax)
            reimg=1;
            ud.petmax=petmax;
        end
        if not(mrmin==ud.mrmin)
            reimg=1;
            ud.mrmin=mrmin;
        end
        if not(mrmax==ud.mrmax)
            reimg=1;
            ud.mrmax=mrmax;
        end
        
        % Update colormap?
        if ud.UpdateCmap==1
            reimg=1;    
            MRax=findobj(fig,'type','axes','tag','MRcmap');
            col=ud.MRcmap;
            r=col(:,1);
            g=col(:,2);
            b=col(:,3);
            MapImg=[1:64;1:64];
            MapImg=cat(3,r(MapImg),g(MapImg),b(MapImg));
            axes(MRax)
            h=imagesc(MapImg);
            set(MRax,'visible','off','tag','MRcmap');
            set(h,'buttondownfcn','nruinspect(''Cmap'',''MR'')');
            PETax=findobj(fig,'type','axes','tag','PETcmap');
            col=ud.PETcmap;
            r=col(:,1);
            g=col(:,2);
            b=col(:,3);
            MapImg=[1:64;1:64];
            MapImg=cat(3,r(MapImg),g(MapImg),b(MapImg));
            axes(PETax)
            h=imagesc(MapImg);
            set(PETax,'visible','off','tag','PETcmap');
            set(h,'buttondownfcn','nruinspect(''Cmap'',''PET'')');
            ud.UpdateCmap=0;
        end
        
        % Did view change?
        if not(view==ud.view)
            ud.view=view;
            reimg=1;
            set(findobj(fig,'tag','slicemax'),'string',num2str(ud.hdrMR.dim(ud.view)));
            ax=ud.hdrMR.siz(view)*([1:ud.hdrMR.dim(view)]-ud.hdrMR.origin(view));
            [tmp,slice]=min(abs(ax-ud.cursor(view)));
            set(findobj(fig,'tag','slice'),'value',slice,'max',ud.hdrMR.dim(ud.view));
            %slice=ceil(get(findobj(fig,'tag','slice'),'value'));
            %keyboard
        end
        % Did slice change?
        if not(slice==ud.slice)
            ud.slice=ceil(slice);
            reimg=1;
        end 
        set(fig,'userdata',ud);
        
        if reimg==1
            hdrMR=ud.hdrMR;
            hdrPET=ud.hdrPET;   
            xs=hdrMR.siz(1)*([1:hdrMR.dim(1)]-hdrMR.origin(1));
            ys=hdrMR.siz(2)*([1:hdrMR.dim(2)]-hdrMR.origin(2));
            zs=hdrMR.siz(3)*([1:hdrMR.dim(3)]-hdrMR.origin(3));
            if ud.view==1
                MR=squeeze(ud.MR(ud.slice,:,:))';
                %PET=squeeze(ud.PET(ud.slice,:,:))';
                x=ys;
                y=zs;
                X=xs(ud.slice);
                Y=x;
                Z=y;
            elseif ud.view==2	
                MR=squeeze(ud.MR(:,ud.slice,:))';
                %PET=squeeze(ud.PET(:,ud.slice,:))';
                x=xs;
                y=zs;
                X=x;
                Y=ys(ud.slice);
                Z=y;
            else
                MR=squeeze(ud.MR(:,:,ud.slice))';
                %PET=squeeze(ud.PET(:,:,ud.slice))';
                x=hdrMR.siz(1)*([1:hdrMR.dim(1)]-hdrMR.origin(1));
                y=hdrMR.siz(2)*([1:hdrMR.dim(2)]-hdrMR.origin(2));
                X=x;
                Y=y;
                Z=zs(ud.slice);
            end
            [X,Y,Z]=meshgrid(X,Y,Z);
            sx=size(X);
            len=prod(sx);
            xyz=[reshape(X,1,len);reshape(Y,1,len);reshape(Z,1,len);1+0*reshape(X,1,len)];
            xyz=inv(ud.A)*xyz;
            PETx=hdrPET.siz(1)*([1:hdrPET.dim(1)]-hdrPET.origin(1));
            PETy=hdrPET.siz(2)*([1:hdrPET.dim(2)]-hdrPET.origin(2));
            PETz=hdrPET.siz(3)*([1:hdrPET.dim(3)]-hdrPET.origin(3));
            X=reshape(xyz(1,:),sx);
            Y=reshape(xyz(2,:),sx);
            Z=reshape(xyz(3,:),sx);
            PET=squeeze(interp3(PETx,PETy,PETz,permute(ud.PET,[2 1 3]),X,Y,Z,'linear'))';
            if ud.view==3;
                PET=PET';
            end
            MR=scale(double(MR),ud.mrmin,ud.mrmax);
            % Get interpolation indices:
            PET=scale(double(PET),ud.petmin,ud.petmax);
            col=ud.MRcmap;%gray(64);
            r=col(:,1);
            g=col(:,2);
            b=col(:,3);
            MR=cat(3,r(MR),g(MR),b(MR));
            col=ud.PETcmap;%hot(64);
            r=col(:,1);
            g=col(:,2);
            b=col(:,3);
            PET=cat(3,r(PET),g(PET),b(PET));
            % Kill all axes with tag 'View'
            delete(findobj(fig,'type','axes','tag','View'));
            % Show with/without transparancy:
            if ud.transp==1 % Show one slice (fusion)
                axes('position',[0.1 0 0.9 1]);
                h=imagesc(x,y,MR,'buttondownfcn','nruinspect(''Cursor'')');
                axis image
                set(gca,'ydir','normal','tag','View')
                hold on
                h1=imagesc(x,y,PET,'buttondownfcn','nruinspect(''Cursor'')');
                set(h1,'alphadata',ud.alpha);
                hold off
                axis off
                set(findobj(fig,'tag','slicelabel'),'string',['Slice ' num2str(slice)]);
                SetCursor(fig);
            else % Show two slices 
                % Which axes is the longest?
                if max(x)-min(x)>max(y)-min(y)
                    pos1=[0.1 0.5 0.9 0.5];
                    pos2=[0.1 0 0.9 0.5];
                else
                    pos1=[0.1 0 0.45 1];
                    pos2=[0.55 0 0.45 1];
                end
                ax1=axes('position',pos1);
                h=imagesc(x,y,MR,'buttondownfcn','nruinspect(''Cursor'')');
                axis image
                set(gca,'ydir','normal','tag','View')
                axis off
                ax2=axes('position',pos2);
                h1=imagesc(x,y,PET,'buttondownfcn','nruinspect(''Cursor'')');
                axis image
                set(gca,'ydir','normal','tag','View')
                axis off
                set(findobj(fig,'tag','slicelabel'),'string',['Slice ' num2str(slice)]);
                SetCursor(fig);
            end
        end
    elseif strcmp(varargin{1},'domovie');
        ud=get(gcbf,'userdata');
        val=get(gcbo,'value');
        if val==1
            prompt={'Enter output filename: (avi file)','Enter # frames pr. second'};
            def={'myavifile.avi','1.5'};
            dlgtitle='Input data for saving movies';
            lineno=1;
            answer=inputdlg(prompt,dlgtitle,lineno,def);
            if not(isempty(answer))
                ud.MovieName=answer{1};
                ud.FPS=round(str2num(answer{2}));
                ud.MakeAMovie=1;
            else
                if isfield(ud,'MakeAMovie')
                    ud=rmfield(ud,'MakeAMovie');
                end
                set(gcbo,'value',0)
            end
        else
            if isfield(ud,'MakeAMovie')
                ud=rmfield(ud,'MakeAMovie');
            end
        end
        set(gcbf,'userdata',ud)
        
    elseif strcmp(varargin{1},'movie')
        fig=gcbf;
        ud=get(fig,'userdata');
        slices=unique(round(ud.min:ud.step:ud.max));
        if isfield(ud,'MakeAMovie')
            M=moviein(length(slices));
        end
        for j=1:length(slices);
            if slices(j)<=ud.hdrMR.dim(ud.view);
                set(findobj(fig,'tag','slice'),'value',slices(j));
                nruinspect('update');
                pause(0.1);
                if isfield(ud,'MakeAMovie');
                    M(:,j)=getframe(gcbf);
                    pause(0.1);
                end
            end
        end
        if isfield(ud,'MakeAMovie');
            if strcmp(computer,'PCWIN')
                Compression='Cinepak';
            else
                Compression='none';
                Ok=0;
                while Ok==0
                    disp(['Warning! avi files written from UNIX system are LARGE. '...
                            'Do this in windows instead! ']);
                    answer=input('Continue? (y/n) ','s');
                    if strcmp(lower(answer),'y') | strcmp(lower(answer),'n')
                        Ok=1;
                    end
                end
                if strcmp(lower(answer),'n')
                    return
                end
            end
            % Here, you can choose to save a matlab movie. The default
            % is to save an avi instead.
            % save(ud.MovieName,'M');
            disp('Saving your movie...');
            movie2avi(M,ud.MovieName,'Compression',Compression,'FPS',ud.FPS);
            disp('done...');
        end
        
        
    elseif strcmp(varargin{1},'interval')
        fig=gcbf;
        ud=get(fig,'userdata');
        prompt={'Min. slice','Step','Max. slice'};
        def={num2str(ud.min),num2str(ud.step),num2str(ud.max)};
        dlgTitle='Movie slice interval';
        lineNo=1; 
        answer=inputdlg(prompt,dlgTitle,lineNo,def);
        if not(isempty(answer))
            ud.min=str2num(answer{1});
            ud.max=str2num(answer{3});
            ud.step=str2num(answer{2});
            set(fig,'userdata',ud);
        end
    elseif strcmp(varargin{1},'Cursor');
        fig=gcbf;
        ud=get(fig,'userdata');
        NewPoint=get(gca,'CurrentPoint');
        idx=1:3;
        idx(idx==ud.view)=[];
        ud.cursor(idx)=[NewPoint(1,1) NewPoint(1,2)];
        set(gcbf,'userdata',ud);
        SetCursor(fig);
    elseif strcmp(varargin{1},'Cmap')
        % Update colormap
        press = get(gcbf,'SelectionType'); % How far are we?
        if strcmp(press,'open') % Second pass? - Else do nothing
            userdat=get(gcbf,'userdata');
            map=varargin{2};
            eval(['cmap=userdat.' map 'cmap;']);
            [tmp cmap] = cmapsel(' ', cmap); 
            eval(['userdat.' map 'cmap=cmap;']);
            userdat.UpdateCmap=1;
            set(gcbf,'userdata',userdat);
            nruinspect('update')
        end
    end
end

function img1=scale(img,Min,Max)
img(isnan(img))=Min;
img=double(img);
img1=img;
img1(img<Min)=Min;
img1(img>Max)=Max;
if not(Max==Min)
    img1=round(63*(img1-Min)/(Max-Min))+1;
else
    img1=0*img1+1;
end
img1=int16(img1);

function SetCursor(fig)
%if not(isempty(gcbf))
%  fig=gcbf;
%else 
%  fig=gcf;
%end
ud=get(fig,'userdata');
idx=1:3;
idx(idx==ud.view)=[];
cursor=ud.cursor(idx);
% Step through axes
ax=findobj(fig,'type','axes','tag','View');
% delete any old x'es:
delete(findobj(gcbf,'tag','cross'));
for j=1:length(ax)
    axes(ax(j))
    hold on
    xlim=get(ax(j),'xlim');
    ylim=get(ax(j),'ylim');
    plot(xlim,[cursor(2) cursor(2)],'color','white','tag','cross','buttondownfcn','nruinspect(''Cursor'')');
    plot([cursor(1) cursor(1)],ylim,'color','white','tag','cross','buttondownfcn','nruinspect(''Cursor'')');
    hold off
end

function fig=SetupWindow
global MatlabVersion;
fig=figure;

uicontrol('style','slider','units','normalized','position',[0 0.9 0.1 0.05],'tag','alpha','value',0.5,'callback','nruinspect(''update'')');
uicontrol('style','togglebutton','units','normalized','position',[0 0.95 0.1 0.05],'string','Transparancy','value',0,'tag','Transparancy','callback','nruinspect(''update'')');
% Check that this is matlab6!
v=version;
if not(str2num(v(1))>=6)
    disp('Sorry. nruinspect runs without transparancy in matlab5.*');
    %return
    set(findobj(fig,'tag','Transparancy'),'value',0,'enable','off');
    set(findobj(fig,'tag','alpha'),'value',0.5,'enable','off');
else
    MatlabVersion=1;
end

uicontrol('style','togglebutton','units','normalized','position',[0 0.8 0.1/3 0.05],'tag','view', ...
    'value',3,'sliderstep',[0.01 0.1],'callback','nruinspect(''updateview'')','string','x','value',0,'userdata',1);
uicontrol('style','togglebutton','units','normalized','position',[0.1/3 0.8 0.1/3 0.05],'tag','view', ...
    'value',3,'sliderstep',[0.01 0.1],'callback','nruinspect(''updateview'')','string','y','value',0,'userdata',2);
uicontrol('style','togglebutton','units','normalized','position',[2*0.1/3 0.8 0.1/3 0.05],'tag','view', ...
    'value',3,'sliderstep',[0.01 0.1],'callback','nruinspect(''updateview'')','string','z','value',1,'userdata',3);


uicontrol('style','text','units','normalized','position',[0 0.85 0.1 0.05],...
    'string','View x/y/z');

uicontrol('style','pushbutton','units','normalized','position',[0 0.75 0.1 0.05],'tag','reset','String','','callback','nruinspect(''update'')','String','Reset lims');


uicontrol('style','edit','units','normalized','position',[0 0.65 0.1 0.05],'tag','mrmin','callback','nruinspect(''update'')');
uicontrol('style','text','units','normalized','position',[0 0.7 0.1 0.05],...
    'string','MRmin');


uicontrol('style','edit','units','normalized','position',[0 0.55 0.1 0.05],'tag','mrmax','callback','nruinspect(''update'')');
uicontrol('style','text','units','normalized','position',[0 0.6 0.1 0.05],...
    'string','MRmax');

% Axis for showing MR cmap
h=axes('position',[0 0.5 0.1 0.05],'tag','MRcmap','visible','off');

uicontrol('style','edit','units','normalized','position',[0 0.4 0.1 0.05],'tag','petmin','callback','nruinspect(''update'')');
uicontrol('style','text','units','normalized','position',[0 0.45 0.1 0.05],...
    'string','PETmin');


uicontrol('style','edit','units','normalized','position',[0 0.3 0.1 0.05],'tag','petmax','callback','nruinspect(''update'')');
uicontrol('style','text','units','normalized','position',[0 0.35 0.1 0.05],...
    'string','PETmax');

% Axis for showing PET cmap
axes('position',[0 0.25 0.1 0.05],'tag','PETcmap','visible','off');

uicontrol('style','text','units','normalized','position',[0 0.1 0.075 0.05],'tag','slicemin');

uicontrol('style','slider','units','normalized','position',[0.075 0.05 0.025 0.2],'tag','slice','callback', ...
    'nruinspect(''update'')','sliderstep',[0.01 0.1 ]);

uicontrol('style','text','units','normalized','position',[0 0.15 0.075 0.05],...
    'string','Slice ','tag','slicelabel');

uicontrol('style','text','units','normalized','position',[0 0.2 0.075 0.05],'tag','slicemax');

uicontrol('style','togglebutton','units','normalized','position',[0 0.05 0.075 0.05],'tag','savemovie','String','Movie save','callback','nruinspect(''domovie'')');

uicontrol('style','pushbutton','units','normalized','position',[0 0 0.05 0.05],'tag','movie','String','Movie','callback','nruinspect(''movie'')');

uicontrol('style','pushbutton','units','normalized','position',[0.05 0 0.05 0.05],'tag','movint','String','Mov. Int.','callback','nruinspect(''interval'')');




axes('position',[0.1 0 0.9 1])
axis off


