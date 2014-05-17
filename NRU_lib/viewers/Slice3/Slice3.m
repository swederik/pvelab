function varargout=Slice3(varargin);
% 
% Reimplementation of CMM's TreeWin
%
% PW, NRU, 2001
%_______________________________________________________________
% Updates: 
% -Variable 'view' is changed to 'viewAx', to avoid Matlab warn i ver 6.5 cause 'view' is a Matlab function, 300103TD
% -Fixed problem for binary files (8bit 2-colors) where Min became Max and
%  divide by zero error occured. 251103TR

% How many input parms?
if nargin==0 % No inputs - do a call to 'Load'
    Struct=Load('');
    if not(isempty(Struct))
        varargout{1}=Slice3('Startup',Struct);
    end
else
    % More than one input - first is 'task'
    task=varargin{1};
    if not(ischar(task))
        error(['First input parameter MUST be a string!']);
    else
        switch task
        case 'CoarseAlign'
            fig=varargin{2};
            ud=get(fig,'userdata');
            ud.Transform=varargin{3}*ud.Transform;
            set(fig,'userdata',ud);	
        case 'KeyPressed'
            Key=get(gcbf,'CurrentKey');
            if strcmp(Key,'control');
                userdat=get(gcbf,'userdata');
                if userdat.Zoom==0
                    userdat.stdcolor=get(gcbf,'color');
                    userdat.Zoom=1;
                    set(gcbf,'userdata',userdat,'color',[245 222 179]/255);
                else
                    userdat.Zoom=0;
                    set(gcbf,'userdata',userdat,'color',userdat.stdcolor);
                end
            end
        case 'SlaveUpdate'
            % Update window from other window
            ud=get(varargin{2},'userdata');
            if not(all(all(ud.Transform==diag([1 1 1 1]))))
                coord=varargin{3};
                coord=[reshape(coord,3,1);1];
                coord=ud.Transform*coord;
                varargin{3}=reshape(coord(1:3),size(varargin{3}));
            end
            Update(varargin{2},'slave',varargin{3});
        case 'UpdatePoint'
            ud=get(varargin{2},'userdata');
            if not(all(all(ud.Transform==diag([1 1 1 1]))))
                coord=varargin{3};
                coord=[reshape(coord,3,1);1];
                coord=ud.Transform*coord;
                varargin{3}=reshape(coord(1:3),size(varargin{3}));
                if nargin==4
                    project=varargin{4};
                    project=[reshape(project,3,1);1];
                    project=ud.Transform*project;
                    varargin{4}=reshape(project(1:3),size(varargin{4}));
                end
            end
            if nargin==3
                Update(varargin{2},'point',varargin{3});
            elseif nargin==4
                Update(varargin{2},'point',varargin{3},varargin{4});
            end
        case 'UpdatePointOnly'
            ud=get(varargin{2},'userdata');
            EndCallBack=ud.EndCallBack;
            ud.EndCallBack='';
            set(varargin{2},'userdata',ud);
            Slice3('UpdatePoint',varargin{2:length(varargin)});
            ud=get(varargin{2},'userdata');
            ud.EndCallBack=EndCallBack;
            set(varargin{2},'userdata',ud);
            
        case 'AddSlave'
            % Add a slave window
            AddSlave(varargin{2},varargin{3});
        case 'DelSlave'
            % Remove a slave window
            RemoveSlave(varargin{2},varargin{3});
        case 'Update'
            Update(gcbf,varargin{2:length(varargin)});
        case 'Startup'
            Struct=varargin{2};
            fig=SetupWindow(Struct.hdr,Struct.cmap);
            set(fig,'userdata',Struct);
            set(findobj(fig,'tag','MinLabel'),'string',num2str(Struct.Min));
            set(findobj(fig,'tag','MaxLabel'),'string',num2str(Struct.Max));
            Update(fig,'init');
            varargout{1}=fig;
        case 'SetEndCallBack'
            % From the outside, add a callback to run at each new
            % selected point
            userdat=get(varargin{2},'userdata');
            userdat.EndCallBack=varargin{3};
            set(varargin{2},'userdata',userdat);
            %Update(varargin{2},'init');
        case 'ResetEndCallBack'
            % From the outside, remove EndCallBack
            userdat=get(varargin{2},'userdata');
            userdat.EndCallBack='none';
            set(varargin{2},'userdata',userdat);
            %Update(varargin{2},'init')
        case 'colormap'
            chColormap(gcbf);
        otherwise
            % task could be a filename - is it?
            Struct=Load(task);
            if not(isempty(Struct))
                out=Slice3('Startup',Struct);
                varargout{1}=out; %Return fig-handle by Thomas Rask 211103, NRU.
            end
        end
    end
end

function chColormap(fig)
% Colormap / range selection

global MyClickState

press = get(fig,'SelectionType'); % How far are we?
if strcmp(press,'open') % Second pass? - Else do nothing
    userdat=get(fig,'userdata');
    if strcmp(MyClickState,'normal') % Left - select colormap
        [tmp map] = cmapsel(' ', get(fig,'colormap')); 
        set(fig,'colormap',map);
    elseif strcmp(MyClickState,'alt') % Right - select range
        res={};
        Min=userdat.Min;
        Max=userdat.Max;
        if get(findobj(fig,'style','togglebutton','tag','Scale'),'value')==1	
            Min=userdat.hdr.scale*(Min-userdat.hdr.offset);
            Max=userdat.hdr.scale*(Max-userdat.hdr.offset);
        end
        res=inputdlg({char({'Enter limits for colormap:', ...
                    '', ...
                    'Minimum:'}), ...
                'Maximum'}, ...
            'Slice3', 1, ...
            {num2str(Min), num2str(Max)});
        if not(isempty(res))
            min_ = str2num(res{1});
            max_ = str2num(res{2});
            
            if (min_ < max_) 
                if get(findobj(fig,'style','togglebutton','tag','Scale'),'value')==1	
                    min_=round((min_/userdat.hdr.scale)+userdat.hdr.offset);
                    max_=round((max_/userdat.hdr.scale)+userdat.hdr.offset);
                end
                if  (min_ < userdat.hdr.lim(2))
                    userdat.Min = userdat.hdr.lim(2);
                else
                    userdat.Min = min_;
                end
                
                if  (max_ > userdat.hdr.lim(1))
                    userdat.Max = userdat.hdr.lim(1);
                else
                    userdat.Max = max_;
                end
                set(fig,'userdata',userdat);
                Min=userdat.Min;
                Max=userdat.Max;
                if get(findobj(fig,'style','togglebutton','tag','Scale'),'value')==1	
                    Min=userdat.hdr.scale*(Min-userdat.hdr.offset);
                    Max=userdat.hdr.scale*(Max-userdat.hdr.offset);
                end
                set(findobj(fig,'tag','MinLabel'),'string',num2str(Min));
                set(findobj(fig,'tag','MaxLabel'),'string',num2str(Max));
                Update(fig,'scaling');
            end
        end
    end;
end;    
MyClickState=press;    

function AddSlave(master,slave)
if isobj(master) & isobj(slave) & not(master==slave) 
    MTag=get(master,'tag');
    STag=get(slave,'tag');
    if not(strcmp(MTag,'Slice3') & strcmp(STag,'Slice3'))
        disp(['Warning: Slave not added - master or slave not Slice3' ...
                ' window']);
    else  
        userdat=get(master,'userdata');
        if isempty(userdat.Slaves) | not(any(userdat.Slaves==slave))
            userdat.Slaves=[userdat.Slaves;slave];
            set(master,'userdata',userdat);
            Update(master,'simple');
        end
    end
end

function RemoveSlave(master,slave)
if isobj(master) & isobj(slave) 
    MTag=get(master,'tag');
    STag=get(slave,'tag');
    if not(strcmp(MTag,'Slice3') & strcmp(STag,'Slice3'))
        disp(['Warning: Slave not added - master or slave not Slice3' ...
                ' window']);
    else  
        userdat=get(master,'userdata');
        userdat.Slaves(userdat.Slaves==slave)=[];
        set(master,'userdata',userdat);
        Update(master,'simple');
    end
end

function Update(varargin)
% Updates figure

% figure number is always 1st parm.
fig=varargin{1};
% Who is updating?
task=varargin{2};
userdat=get(fig,'userdata');
oldcoords=userdat.coords;
Redraw=0; % Redrawing disabled per default
Slave=0;  % Usually window is not in slave mode
pane=0;   % We do not know yet which pane was clickd
switch task
case 'ThresholdCol'
    oldcol=get(gcbo,'backgroundcolor');
    newcol=uisetcolor(oldcol);
    set(gcbo,'backgroundcolor',newcol);
    Redraw=1;
case 'ThresholdOnOff'
    ThresState=get(gcbo,'value');
    userdat.ThresState=ThresState;
    Redraw=1;
case 'Threshold'
    userdat.Threshold=get(gcbo,'value');
case 'AlignMode'
    AlignMode=get(findobj(fig,'tag','Align'),'value');
    if AlignMode==1
        Stat='on';
    else
        Stat='off';
    end
    disp(['Alignmode is now set to ''' Stat '''']);
    userdat.AlignMode=AlignMode;
case 'scaling'
    Redraw=1;
    Slave=1;
case 'point'
    userdat.coords=varargin{3};
    Redraw=1;
    if nargin==4
        userdat.project=varargin{4};
    elseif nargin==3
        if isfield(userdat,'project')
            userdat=rmfield(userdat,'project');
        end
    end
case 'range' 
    Range=1;
case 'simple' % do simple redraw
    Redraw=1;
case 'slave' % window is in slave mode
    userdat.coords=varargin{3};
    Slave=1;
    Redraw=1;
case 'init'  % startup
    Redraw=1;
case 'box' % called from input box
    newval=str2num(get(gcbo,'string'));
    Ax=varargin{3};
    if not(isempty(newval)) % Sensible number entered
        % Adjust to fit min/max values
        Min = userdat.hdr.siz(Ax)*(1-userdat.hdr.origin(Ax)-0.5);
        Max = userdat.hdr.siz(Ax)*(userdat.hdr.dim(Ax)-userdat.hdr.origin(1)+0.5);
        newval=max(Min,newval);
        newval=min(Max,newval);
        userdat.coords(Ax)=newval;
        Redraw=1;
    end
    
case 'slider' % called from slider
    newval=get(gcbo,'value');
    Ax=varargin{3};
    Min = userdat.hdr.siz(Ax)*(1-userdat.hdr.origin(Ax)-0.5);
    Max = userdat.hdr.siz(Ax)*(userdat.hdr.dim(Ax)-userdat.hdr.origin(1)+0.5);
    newval=max(Min,newval);
    newval=min(Max,newval);
    userdat.coords(Ax)=newval;
    Redraw=1;
    
case 'click' % called by click on axis
    % Determine which axis was clicked
    Axstr=get(gca,'tag');
    pane=gca;
    axnum=str2num(Axstr(5));
    % Is this zoom refinement?
    if userdat.Zoom==1 & not(userdat.AlignMode==1)
        ImproveClick(pane,task);
        return
        % Is this alignment adjustment?
    elseif userdat.AlignMode==1
        disp('Starting transformation');
        curax=get(gcbo,'parent');
        OldPoint=get(curax,'currentpoint');      
        hfig=figure('units','normalized','position',[0 0 1 1],'numbertitle','off','name','Zoom');
        h=hfig;
        set(h,'renderer','opengl')
        himg=findobj('parent',curax,'type','image','tag','');
        img=get(himg,'cdata');
        xd=get(himg,'xdata');
        yd=get(himg,'ydata');
        [xd,yd]=meshgrid(xd,yd); 
        h=surf(xd,yd,0*xd);
        img(isnan(img))=0;
        set(h,'tag','cursor','edgecolor','none','cdata',img,'buttondownfcn','CrossMove');
        view(2);
        axis image
        ud.TransStep=1;
        ud.AngStep=pi/24;
        hold on
        if axnum==1
            viewAx=[1 2 3];%[2 3 1]; view->viewAx, to avoid Matlab warn i ver 6.5, 300103TD
        elseif axnum==2
            viewAx=[1 3 2];%[1 3 2]; view->viewAx, to avoid Matlab warn i ver 6.5, 300103TD
        elseif axnum==3
            viewAx=[2 3 1];%[1 2 3]; view->viewAx, to avoid Matlab warn i ver 6.5, 300103TD
        end
        ud.centre=OldPoint(1,1:2);
        ud.A=diag([1 1 1 1]);
        ud.parent=gcbf;
        ud.alpha=0;
        hold on
        ax=get(h,'parent');
        xl=get(ax,'xlim');
        yl=get(ax,'ylim');
        set(ax,'buttondownfcn','CrossMove')
        h=plot(xl,[ud.centre(2) ud.centre(2)],'g:','linewidth',2,'tag','Cross');
        threscolor=get(findobj(fig,'tag','ThresColor'),'backgroundcolor');
        set(h,'color',threscolor,'buttondownfcn','CrossMove')
        h=plot([ud.centre(1) ud.centre(1)],yl,'g:','linewidth',2,'tag','Cross');
        set(h,'color',threscolor,'buttondownfcn','CrossMove')
        set(hfig,'keypressfcn',['CheckKey_Coreg(findobj(''tag'',''cursor''),[' num2str(viewAx) '])'],'userdata',ud,... view->viewAx, to avoid Matlab warn i ver 6.5, 300103TD
            'closerequestfcn','CoarseAlign','colormap',get(fig, ...
            'colormap'));
        userdat.coords=rand(1,3).*userdat.hdr.dim'.*userdat.hdr.siz';
        set(fig,'userdata',userdat);
        figure(hfig);
        title(['Transl. ' num2str(ud.TransStep) ' mm. Rot. \pi/' ...
                num2str(pi/ud.AngStep) ]);
        uimenu(hfig,'label','Cancel','Callback','CoarseAlign(''cancel'')');
        uimenu(hfig,'label','Accept','Callback','CoarseAlign');
        uiwait(hfig);
        udtmp=get(fig,'userdata');
        userdat.Transform=udtmp.Transform;
        coords=userdat.Transform*[reshape(userdat.Realcoords(1:3),3,1);1];
        if isfield(userdat,'project')
            project=userdat.Transform*[reshape(userdat.Realproject(1:3),3,1);1];
            Update(fig,'point',coords,project);
        else
            Update(fig,'point',coords);
        end
        userdat.coords=userdat.Transform*[reshape(userdat.Realcoords(1:3),3,1);1];
        if isfield(userdat,'project')
            userdat.project=userdat.Transform*[reshape(userdat.Realproject(1:3),3,1);1];
            userdat.project=userdat.project(1:3);
        end
        userdat.coords=userdat.coords(1:3);
        set(findobj(fig,'tag','Align'),'value',0);
        Update(fig,'AlignMode');
        return
        %keyboard
        %Redraw=1;
    else
        % Get new position data:
        newxy=get(gca,'currentpoint');
        newxy=newxy(1,1:2);
        if axnum==1
            userdat.coords(1:2)=newxy;
        elseif axnum==2
            userdat.coords([1 3])=newxy;
        elseif axnum==3
            userdat.coords([2 3])=newxy;
        else
            error(['Invalid axis number: ' num2str(axnum)]);
        end
        Redraw=1;
    end    
otherwise
    error(['Not implemented task: ' task]);
end
%
% Calculate the ''real'' coordinates 
%
Realcoords=inv(userdat.Transform)*[reshape(userdat.coords(1:3),3,1);1];
userdat.Realcoords=Realcoords(1:3);
if isfield(userdat,'project')
    Realproject=inv(userdat.Transform)*[reshape(userdat.project(1:3),3,1);1];
    userdat.Realproject=Realproject(1:3);
end
xax=userdat.hdr.siz(1)*([1:userdat.hdr.dim(1)]-userdat.hdr.origin(1));
yax=userdat.hdr.siz(2)*([1:userdat.hdr.dim(2)]-userdat.hdr.origin(2));
zax=userdat.hdr.siz(3)*([1:userdat.hdr.dim(3)]-userdat.hdr.origin(3));
if not(all(all(userdat.Transform==diag([1 1 1 1]))))
    [xMesh,yMesh,zMesh]=meshgrid(xax,yax,zax);  
end
[tmp xidx]=min(abs(xax-userdat.coords(1)));
[tmp yidx]=min(abs(yax-userdat.coords(2)));
[tmp zidx]=min(abs(zax-userdat.coords(3)));
[tmp xidxold]=min(abs(xax-oldcoords(1)));
[tmp yidxold]=min(abs(yax-oldcoords(2)));
[tmp zidxold]=min(abs(zax-oldcoords(3)));
% Do a check of the coordinate ranges:
userdat.coords(1)=min(max(xax),userdat.coords(1));
userdat.coords(1)=max(min(xax),userdat.coords(1));
userdat.coords(2)=min(max(yax),userdat.coords(2));
userdat.coords(2)=max(min(yax),userdat.coords(2));  
userdat.coords(3)=min(max(zax),userdat.coords(3));
userdat.coords(3)=max(min(zax),userdat.coords(3));
%userdat.project=userdat.coords;
% Present new data in the three views
ax1=findobj(fig,'type','axes','tag','Axis1');
ax2=findobj(fig,'type','axes','tag','Axis2');
ax3=findobj(fig,'type','axes','tag','Axis3');
axes(ax1);
if not(all(all(userdat.Transform==diag([1 1 1 1]))))
    [xM,yM,zM]=meshgrid(xax,yax,zax(zidx));
    tmpimg=permute(userdat.img,[2 1 3]);
    sMesh=size(xM);
    xM=reshape(xM,1,prod(sMesh));
    yM=reshape(yM,1,prod(sMesh));
    zM=reshape(zM,1,prod(sMesh));
    xyz=[xM;yM;zM;1+0*zM];
    xyz=inv(userdat.Transform)*xyz;
    xM=xyz(1,:);
    yM=xyz(2,:);
    zM=xyz(3,:);
    xM=reshape(xM,sMesh);
    yM=reshape(yM,sMesh);
    zM=reshape(zM,sMesh);
    tmpimg=interp3(xMesh,yMesh,zMesh,double(tmpimg),xM,yM,zM,'linear');
    img=GetIdx(tmpimg,userdat.Min,userdat.Max);
else
    img=GetIdx(userdat.img(:,:,zidx)',userdat.Min,userdat.Max);
end
h=findobj('parent',ax1,'type','image');
hx=findobj('parent',ax1,'type','line','tag','x');
hy=findobj('parent',ax1,'type','line','tag','y');  
hpx=findobj('parent',ax1,'type','line','tag','px');
hpy=findobj('parent',ax1,'type','line','tag','py');
if not(isempty(h))
    if strcmp(task,'scaling') | not(zidx==zidxold) 
        set(h,'cdata',img);
    end
    set(hx,'xdata',[userdat.coords(1) userdat.coords(1)]);
    set(hy,'ydata',[userdat.coords(2) userdat.coords(2)]);
    if isfield(userdat,'project')
        set(hpx,'xdata',[userdat.project(1) userdat.project(1)],'visible','on');
        set(hpy,'ydata',[userdat.project(2) userdat.project(2)],'visible','on');
    else
        set(hpx,'visible','off');
        set(hpy,'visible','off'); 
    end
else
    h=image(xax,yax,img);
    xlim=get(ax1,'xlim'); 
    ylim=get(ax1,'ylim');  
    hold on
    hx=plot([userdat.coords(1) userdat.coords(1)],ylim,'w-','tag','x');
    hy=plot(xlim,[userdat.coords(3) userdat.coords(3)],'w-','tag','y'); 
    hpx=plot([userdat.coords(1) userdat.coords(1)],ylim,'r:','tag','px','visible','off');
    hpy=plot(xlim,[userdat.coords(3) userdat.coords(3)],'r:','tag','py','visible','off');
    hold off
    xlabel('x');
    ylabel('y');
end
% Delete any threshold contour on this axis
delete(findobj(fig,'parent',ax1,'tag','ThresholdContour'));
if userdat.ThresState==1
    Thres=GetIdx(userdat.Threshold*(userdat.Max-userdat.Min)+ ...
        userdat.Min,userdat.Min,userdat.Max);
    
    hold on
    [c,hC]=contour(xax,yax,img,[Thres Thres]);
    set(hC,'tag','ThresholdContour','edgecolor',get(findobj(fig,'tag','ThresColor'),'backgroundcolor'));
    hold off
end
axis image
set(ax1,'ydir','normal'); 
set(h,'cdatamapping','direct');
axes(ax2);
if not(all(all(userdat.Transform==diag([1 1 1 1]))))
    [xM,yM,zM]=meshgrid(xax,yax(yidx),zax);
    tmpimg=permute(userdat.img,[2 1 3]);
    sMesh=size(xM);
    xM=reshape(xM,1,prod(sMesh));
    yM=reshape(yM,1,prod(sMesh));
    zM=reshape(zM,1,prod(sMesh));
    xyz=[xM;yM;zM;1+0*zM];
    xyz=inv(userdat.Transform)*xyz;
    xM=xyz(1,:);
    yM=xyz(2,:);
    zM=xyz(3,:);
    xM=reshape(xM,sMesh);
    yM=reshape(yM,sMesh);
    zM=reshape(zM,sMesh);
    tmpimg=squeeze(interp3(xMesh,yMesh,zMesh,double(tmpimg),xM,yM,zM,'linear'))';
    img=GetIdx(tmpimg,userdat.Min,userdat.Max);
else
    img=GetIdx(squeeze(userdat.img(:,yidx,:))',userdat.Min,userdat.Max);
end
%img=GetIdx(squeeze(userdat.img(:,yidx,:))',userdat.Min,userdat.Max);
h=findobj('parent',ax2,'type','image');
hx=findobj('parent',ax2,'type','line','tag','x');
hy=findobj('parent',ax2,'type','line','tag','y');
hpx=findobj('parent',ax2,'type','line','tag','px');
hpy=findobj('parent',ax2,'type','line','tag','py');
if not(isempty(h))
    if not(yidx==yidxold) | strcmp(task,'scaling')
        set(h,'cdata',img);
    end
    set(hx,'xdata',[userdat.coords(1) userdat.coords(1)]);
    set(hy,'ydata',[userdat.coords(3) userdat.coords(3)]);
    if isfield(userdat,'project')
        set(hpx,'xdata',[userdat.project(1) userdat.project(1)],'visible','on');
        set(hpy,'ydata',[userdat.project(3) userdat.project(3)],'visible','on');
    else
        set(hpx,'visible','off');
        set(hpy,'visible','off');
    end
else
    h=image(xax,zax,img);
    xlim=get(ax2,'xlim'); 
    %xlim(1)=xlim(1)-0.5*userdat.hdr.siz(1);
    %xlim(2)=xlim(2)+0.5*userdat.hdr.siz(1);
    ylim=get(ax2,'ylim');  
    %ylim(1)=ylim(1)-0.5*userdat.hdr.siz(3);
    %ylim(2)=ylim(2)+0.5*userdat.hdr.siz(3);
    hold on
    hx=plot([userdat.coords(1) userdat.coords(1)],ylim,'w-','tag','x');
    hy=plot(xlim,[userdat.coords(3) userdat.coords(3)],'w-','tag','y');
    hpx=plot([userdat.coords(1) userdat.coords(1)],ylim,'r:','tag','px','visible','off');
    hpy=plot(xlim,[userdat.coords(3) userdat.coords(3)],'r:','tag','py','visible','off');
    hold off
    xlabel('x');
    ylabel('z');
end
% Delete any threshold contour on this axis
delete(findobj(fig,'parent',ax2,'tag','ThresholdContour'));
if userdat.ThresState==1
    Thres=GetIdx(userdat.Threshold*(userdat.Max-userdat.Min)+ ...
        userdat.Min,userdat.Min,userdat.Max);
    
    hold on
    [c,hC]=contour(xax,zax,img,[Thres Thres]);
    set(hC,'tag','ThresholdContour','edgecolor',get(findobj(fig,'tag','ThresColor'),'backgroundcolor'));
    hold off
end
axis image
set(ax2,'ydir','normal'); 
set(h,'cdatamapping','direct');
axes(ax3);
if not(all(all(userdat.Transform==diag([1 1 1 1]))))
    [xM,yM,zM]=meshgrid(xax(xidx),yax,zax);
    tmpimg=permute(userdat.img,[2 1 3]);
    sMesh=size(xM);
    xM=reshape(xM,1,prod(sMesh));
    yM=reshape(yM,1,prod(sMesh));
    zM=reshape(zM,1,prod(sMesh));
    xyz=[xM;yM;zM;1+0*zM];
    xyz=inv(userdat.Transform)*xyz;
    xM=xyz(1,:);
    yM=xyz(2,:);
    zM=xyz(3,:);
    xM=reshape(xM,sMesh);
    yM=reshape(yM,sMesh);
    zM=reshape(zM,sMesh);
    tmpimg=squeeze(interp3(xMesh,yMesh,zMesh,double(tmpimg),xM,yM,zM,'linear'))';
    img=GetIdx(tmpimg,userdat.Min,userdat.Max);
else
    img=GetIdx(squeeze(userdat.img(xidx,:,:))',userdat.Min,userdat.Max);
end
%img=GetIdx(squeeze(userdat.img(xidx,:,:))',userdat.Min,userdat.Max);
h=findobj('parent',ax3,'type','image');
hx=findobj('parent',ax3,'type','line','tag','x');
hy=findobj('parent',ax3,'type','line','tag','y');
hpx=findobj('parent',ax3,'type','line','tag','px');
hpy=findobj('parent',ax3,'type','line','tag','py');
if not(isempty(h))
    if not(xidxold==xidx)| strcmp(task,'scaling')
        set(h,'cdata',img);
    end
    set(hx,'xdata',[userdat.coords(2) userdat.coords(2)]);
    set(hy,'ydata',[userdat.coords(3) userdat.coords(3)]);
    if isfield(userdat,'project')
        set(hpx,'xdata',[userdat.project(2) userdat.project(2)],'visible','on');
        set(hpy,'ydata',[userdat.project(3) userdat.project(3)],'visible','on');
    else  
        set(hpx,'visible','off');
        set(hpy,'visible','off');
    end
else
    h=image(yax,zax,img);
    xlim=get(ax3,'xlim'); 
    %xlim(1)=xlim(1)-0.5*userdat.hdr.siz(2);
    %xlim(2)=xlim(2)+0.5*userdat.hdr.siz(2);
    ylim=get(ax3,'ylim');  
    %ylim(1)=ylim(1)-0.5*userdat.hdr.siz(3);
    %ylim(2)=ylim(2)+0.5*userdat.hdr.siz(3);
    hold on
    hx=plot([userdat.coords(1) userdat.coords(1)],ylim,'w-','tag','x');
    hy=plot(xlim,[userdat.coords(3) userdat.coords(3)],'w-','tag','y');
    hpx=plot([userdat.coords(1) userdat.coords(1)],ylim,'r:','tag','px','visible','off');
    hpy=plot(xlim,[userdat.coords(3) userdat.coords(3)],'r:','tag','py','visible','off');
    hold off
    xlabel('y');
    ylabel('z');
end
% Delete any threshold contour on this axis
delete(findobj(fig,'parent',ax3,'tag','ThresholdContour'));
if userdat.ThresState==1
    Thres=GetIdx(userdat.Threshold*(userdat.Max-userdat.Min)+ ...
        userdat.Min,userdat.Min,userdat.Max);
    
    hold on
    [c,hC]=contour(yax,zax,img,[Thres Thres]);
    set(hC,'tag','ThresholdContour','edgecolor',get(findobj(fig,'tag','ThresColor'),'backgroundcolor'));
    hold off
end
axis image
set(ax3,'ydir','normal'); 
set(h,'cdatamapping','direct');
set(ax1,'tag','Axis1');
set(get(ax1,'children'),'buttondownfcn','Slice3(''Update'',''click'')');
set(ax2,'tag','Axis2');
set(get(ax2,'children'),'buttondownfcn','Slice3(''Update'',''click'')');
set(ax3,'tag','Axis3');
set(get(ax3,'children'),'buttondownfcn','Slice3(''Update'',''click'')');

% Update uicontrol values
set(findobj(fig,'style','edit','tag','sliceX'),'string', ...
    num2str(userdat.coords(1)));
set(findobj(fig,'style','edit','tag','sliceY'),'string', ...
    num2str(userdat.coords(2)));
set(findobj(fig,'style','edit','tag','sliceZ'),'string', ...
    num2str(userdat.coords(3)));
val=double(userdat.img(xidx,yidx,zidx));
MinVal=userdat.Min;
MaxVal=userdat.Max;
MinValG=userdat.hdr.lim(2);
MaxValG=userdat.hdr.lim(1);
Str='Raw';
% Show scaled or raw values? 
if get(findobj(fig,'style','togglebutton','tag','Scale'),'value')==1
    val=userdat.hdr.scale*(val-userdat.hdr.offset);
    MinVal=userdat.hdr.scale*(MinVal-userdat.hdr.offset);
    MaxVal=userdat.hdr.scale*(MaxVal-userdat.hdr.offset);
    MinValG=userdat.hdr.scale*(MinValG-userdat.hdr.offset);
    MaxValG=userdat.hdr.scale*(MaxValG-userdat.hdr.offset);
    Str='Scaled';
end
set(findobj(fig,'style','text','tag','Value'),'string',num2str(val));
set(findobj(fig,'style','text','tag','MinLabel'),'string',num2str(MinVal));
set(findobj(fig,'style','text','tag','MaxLabel'),'string',num2str(MaxVal));
set(findobj(fig,'style','edit','tag','MinLim'),'string',num2str(MinValG));
set(findobj(fig,'style','edit','tag','MaxLim'),'string',num2str(MaxValG));
set(findobj(fig,'style','togglebutton','tag','Scale'),'string',Str);
set(findobj(fig,'style','slider','tag','slideX'),'value',userdat.coords(1));
set(findobj(fig,'style','slider','tag','slideY'),'value',userdat.coords(2));
set(findobj(fig,'style','slider','tag','slideZ'),'value',userdat.coords(3));
set(fig,'userdata',userdat);
% Is EndCallBack defined?
if not(strcmp(userdat.EndCallBack,'none'));
    eval(userdat.EndCallBack);
end
% Should we update our slave windows?
if not(Slave==1)
    for j=1:length(userdat.Slaves)
        if isobj(userdat.Slaves(j))
            Slice3('SlaveUpdate',userdat.Slaves(j),userdat.Realcoords)
        end
    end
end

function slice1=GetRGB(slice,Min,Max,cmap)
slice1=double(slice);
if (Max-Min)~=0
    slice1(slice1<Min)=Min;
    slice1(slice1>Max)=Max;
    slice1=round(63*(slice1-Min)/(Max-Min))+1;
end
r=cmap(:,1);
g=cmap(:,2);
b=cmap(:,3);
slice1=cat(3,r(slice1),g(slice1),b(slice1));

function slice1=GetIdx(slice,Min,Max)
slice1=double(slice);
if (Max-Min)~=0
    slice1(slice1<Min)=Min;
    slice1(slice1>Max)=Max;
    slice1=round(63*(slice1-Min)/(Max-Min))+1;
end


function Struct=Load(filename)
% Used for calling LoadAnalyze
if strcmp(filename,'');
    % No filename defined
    [img,hdr]=LoadAnalyze('single'); 
else
    [img,hdr]=LoadAnalyze(filename,'single'); 
end
if not(isempty(img))
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
    %______________________________________________________________________

    [Struct.Min,Struct.Max,imgType]=findLim(img); %ADDED by TR060104  
    if strcmp(imgType,'PET'), Struct.cmap=hot(64); end; %ADDED by TR060104  
    
    %Struct.Min=double(min(img(:))); DISABLED by TR060104
    %Struct.Max=double(max(img(:))); DISABLED by TR060104
    %______________________________________________________________________
    Struct.Zoom=0;
    Struct.AlignMode=0;
    Struct.Transform=diag([1 1 1 1]);
    Struct.Threshold=0.5;
    Struct.ThresState=0;
else
    Struct=[];
end

function fig=SetupWindow(hdr,cmap);
% Set up the user interface

% Random placement:
rand('state',sum(100*clock));
position=zeros(1,4);
position(1)=rand*0.5;
position(2)=rand*0.5;
position(3)=0.5;
position(4)=0.5;
fig = figure('numbertitle','off','units','normalized','position',position,...
    'name',hdr.name,'tag','Slice3','Resize','On', ...
    'menubar','none','KeyPressFcn','Slice3(''KeyPressed'')'); 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% Placering af informations felter, såsom størelse, origin,
% nuværende position med mere
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

plVert = .413;
plHort = .501;
plVertSize = .035; 
plDiff = 0.01;
plHortDiff = .01;
plHortSize = .10;
plHortOffset = 0.501;

uicontrol('style','frame','units','normalized','parent',fig,'position',[.5 .41 .48 .07]);

uicontrol('style','text','parent',fig,'units','normalized','position',...
    [plHortOffset+plHortDiff plVert  plHortSize  plVertSize],'string','Position:');

uicontrol('style','text','parent',fig,'units','normalized','position',...
    [plHortOffset+2*plHortDiff+plHortSize plVert+.005+.025 plHortSize plVertSize],'string','x');

uicontrol('style','edit','tag','sliceX','parent',fig,'callback','Slice3(''Update'',''box'',1)','units','normalized',...
    'position',[plHortOffset+2*plHortDiff+plHortSize plVert+.005 plHortSize plVertSize],...
    'string','');

uicontrol('style','text','units','normalized','position',[plHortOffset+3*plHortDiff+2*plHortSize plVert+.005+.025 plHortSize plVertSize],...
    'parent',fig,'string','y');

uicontrol('style','edit','parent',fig,'tag','sliceY','units','normalized','position',...
    [plHortOffset+3*plHortDiff+2*plHortSize plVert+.005 plHortSize plVertSize],...
    'callback','Slice3(''Update'',''box'',2)','string','');

uicontrol('units','normalized','style','text','parent',fig,'position',...
    [plHortOffset+4*plHortDiff+3*plHortSize plVert+.005+.025 plHortSize plVertSize],...
    'string','z');

uicontrol('units','normalized','style','edit','tag','sliceZ','position',...
    [plHortOffset+4*plHortDiff+3*plHortSize plVert+.005 plHortSize plVertSize],...
    'callback','Slice3(''Update'',''box'',3)','parent',fig,'string','')

uicontrol('style','frame','units','normalized','position',[.5 .05 .48 .35],'units','normalized')

plOffset = 0.4;
plVertDiff = 0.004;
plVertSize = 0.038;

uicontrol('style','text','units','normalized','position',...
    [plHortOffset+2*plHortDiff+plHortSize plOffset-plVertSize-plVertDiff plHortSize plVertSize],...
    'parent',fig,'string','Diminsion'); ...
    
uicontrol('style','text','units','normalized','position',...
    [plHortOffset+3*plHortDiff+2*plHortSize  plOffset-plVertSize-plVertDiff plHortSize plVertSize],...
    'parent',fig,'string','Size');

uicontrol('style','text','units','normalized','position',...
    [plHortOffset+4*plHortDiff+3*plHortSize  plOffset-plVertSize-plVertDiff plHortSize plVertSize],...
    'string','Origin');  

uicontrol('style','text','units','normalized','position',...
    [plHortOffset+plHortDiff plOffset-2*plVertSize-2*plVertDiff plHortSize plVertSize],...
    'parent',fig,'string','x'); 

uicontrol('style','edit','enable','inactive','units','normalized','position',...
    [plHortOffset+2*plHortDiff+plHortSize plOffset-2*plVertSize-2*plVertDiff plHortSize plVertSize],...
    'tag','dimx','parent',fig, ...
    'string',hdr.dim(1));       

uicontrol('style','edit','enable','inactive','units','normalized','position',...
    [plHortOffset+3*plHortDiff+2*plHortSize  plOffset-2*plVertSize-2*plVertDiff plHortSize plVertSize],...
    'parent',fig,'tag','sizx','string',hdr.siz(1));   

uicontrol('style','edit','enable','inactive','parent',fig,'units','normalized','position',...
    [plHortOffset+4*plHortDiff+3*plHortSize  plOffset-2*plVertSize-2*plVertDiff plHortSize plVertSize],...
    'tag','orgx','parent',fig,'string',hdr.origin(1));

uicontrol('style','text','units','normalized','position',...
    [plHortOffset+plHortDiff plOffset-3*plVertSize-3*plVertDiff plHortSize plVertSize],...
    'parent',fig,'string','y');  

uicontrol('style','edit','enable','inactive','parent',fig,'units','normalized','position',...
    [plHortOffset+2*plHortDiff+plHortSize plOffset-3*plVertSize-3*plVertDiff plHortSize plVertSize],...
    'parent',fig,'tag','dimy','string',hdr.dim(2));    

uicontrol('style','edit','enable','inactive','units','normalized','position',...
    [plHortOffset+3*plHortDiff+2*plHortSize  plOffset-3*plVertSize-3*plVertDiff plHortSize plVertSize],...
    'parent',fig,'tag','sizy','string',hdr.siz(2))

uicontrol('style','edit','enable','inactive','parent',fig,'units','normalized','position',...
    [plHortOffset+4*plHortDiff+3*plHortSize  plOffset-3*plVertSize-3*plVertDiff plHortSize plVertSize],...
    'units','normalized','tag','orgy','string',hdr.origin(2));

uicontrol('style','text','units','normalized','position',[plHortOffset+plHortDiff plOffset-4*plVertSize-4*plVertDiff plHortSize plVertSize],...
    'parent',fig,'string','z');

uicontrol('style','edit','enable','inactive','units','normalized','position',...
    [plHortOffset+2*plHortDiff+plHortSize plOffset-4*plVertSize-4*plVertDiff plHortSize plVertSize],...
    'parent',fig, 'tag','dimz','string',hdr.dim(3));    

uicontrol('style','edit','enable','inactive','units','normalized','position',...
    [plHortOffset+3*plHortDiff+2*plHortSize  plOffset-4*plVertSize-4*plVertDiff plHortSize plVertSize],...
    'tag','sizz','parent',fig,'string',hdr.siz(3));

uicontrol('style','edit','enable','inactive','units','normalized','position',...
    [plHortOffset+4*plHortDiff+3*plHortSize  plOffset-4*plVertSize-4*plVertDiff plHortSize plVertSize],...
    'tag','orgz','parent',fig,'string',hdr.origin(3));

uicontrol('style','text','units','normalized','position',...
    [plHortOffset+plHortDiff plOffset-5*plVertSize-5*plVertDiff plHortSize plVertSize],...
    'parent',fig,'string','Scale'); 

uicontrol('style','edit','enable','inactive','parent',fig,'tag','scale','units','normalized','position',...
    [plHortOffset+2*plHortDiff+plHortSize plOffset-5*plVertSize-5*plVertDiff plHortSize plVertSize],...
    'string',hdr.scale); 

uicontrol('style','text','enable','inactive','backgroundcolor', [.447 .823 1],'string','Value:',...
    'parent',fig,'tag',' ','units','normalized','position',...
    [plHortOffset+3*plHortDiff+2*plHortSize plOffset-5*plVertSize-5*plVertDiff plHortSize plVertSize]); 


uicontrol('style','text','enable','inactive','backgroundcolor', [.447 .823 1],'parent',fig,...
    'tag','Value','units','normalized','position',...
    [plHortOffset+4*plHortDiff+3*plHortSize plOffset-5*plVertSize-5*plVertDiff plHortSize plVertSize],'string',' '); 

uicontrol('style','togglebutton','backgroundcolor', [.447 .823 1],'string','Raw',...
    'parent',fig,'tag','Scale','units','normalized','position',...
    [plHortOffset+3*plHortDiff+2*plHortSize plOffset-6*plVertSize-6*plVertDiff plHortSize plVertSize],...
    'callback','Slice3(''Update'',''scaling'')'); 

uicontrol('style','togglebutton','backgroundcolor','Red','foregroundcolor','white','string','Alignment',...
    'parent',fig,'tag','Align','units','normalized','position',...
    [plHortOffset+4*plHortDiff+3*plHortSize plOffset-6*plVertSize-6*plVertDiff plHortSize plVertSize],...
    'callback','Slice3(''Update'',''AlignMode'')'); 

uicontrol('style','slider','parent',fig,'tag','Thressslide','units','normalized','position',...
    [plHortOffset+4*plHortDiff+3*plHortSize plOffset-7*plVertSize-7*plVertDiff plHortSize plVertSize],...
    'callback','Slice3(''Update'',''Threshold'')','value',0.5); 

uicontrol('style','togglebutton','parent',fig,'tag','ThresOnOff','units','normalized','position',...
    [plHortOffset+3*plHortDiff+2*plHortSize plOffset-7*plVertSize-7*plVertDiff plHortSize/2 plVertSize],...
    'callback','Slice3(''Update'',''ThresholdOnOff'')','value',0,'string','TC'); 

uicontrol('style','pushbutton','parent',fig,'tag','ThresColor','units','normalized','position',...
    [plHortOffset+3*plHortDiff+2.5*plHortSize plOffset-7*plVertSize-7*plVertDiff plHortSize/2 plVertSize],...
    'callback','Slice3(''Update'',''ThresholdCol'')', ...
    'value',0,'string','','backgroundcolor',[0 1 0]); 


%uicontrol('style','slider','parent',fig,'tag','Thressslide','units','normalized','position',...
%	    [plHortOffset+4*plHortDiff+3*plHortSize plOffset-7*plVertSize-7*plVertDiff plHortSize plVertSize],...
%	    'callback','Slice3(''Update'',''Threshold'')','value',0.5); 




%
% precission, har desvaerren bug og fungere derfor ikke korrekt,
% men er uden betydning
%
if hdr.pre == 1
    str = '2 bit';
elseif hdr.pre == 8
    str = '8 bit';     
elseif hdr.pre == 16	
    if hdr.lim(1) == 0
        str = '16 bit sig.';
    else 
        str = '16 bit unsig.';
    end
elseif hdr.pre == 32
    str = '32 bit';
end

uicontrol('style','text','units','normalized','position',[plHortOffset+plHortDiff  plOffset-6*plVertSize-6*plVertDiff plHortSize plVertSize],...
    'parent',fig,'string','Offset');

uicontrol('style','edit','enable','inactive','units','normalized','position',...
    [plHortOffset+2*plHortDiff+1*plHortSize  plOffset-6*plVertSize-6*plVertDiff plHortSize plVertSize],...
    'parent',fig,'string', hdr.offset);

uicontrol('style','text','units','normalized','position',[plHortOffset+plHortDiff  plOffset-7*plVertSize-7*plVertDiff plHortSize plVertSize],...
    'parent',fig,'string','Precission');

uicontrol('style','edit','enable','inactive','tag', 'pre','units','normalized','position',...
    [plHortOffset+2*plHortDiff+1*plHortSize  plOffset-7*plVertSize-7*plVertDiff plHortSize plVertSize],...
    'parent',fig,'string', str);

uicontrol('style','text','units','normalized','position',[plHortOffset+plHortDiff plOffset-8*plVertSize-8*plVertDiff plHortSize plVertSize],...
    'parent',fig,'string','Limit(min):');

uicontrol('style','edit','enable','inactive','units','normalized','position',...
    [plHortOffset+2*plHortDiff+plHortSize plOffset-8*plVertSize-8*plVertDiff plHortSize plVertSize],...
    'parent',fig,'tag','MinLim','string',hdr.lim(2));    

uicontrol('style','text','units','normalized','position',...
    [plHortOffset+3*plHortDiff+2*plHortSize  plOffset-8*plVertSize-8*plVertDiff plHortSize plVertSize],...
    'parent',fig,'string','Limit(max):');

uicontrol('style','edit','enable','inactive','units','normalized','position',...
    [plHortOffset+4*plHortDiff+3*plHortSize  plOffset-8*plVertSize-8*plVertDiff plHortSize plVertSize],...
    'parent',fig,'tag','MaxLim','string',hdr.lim(1));

axes('parent',fig,'units','normalized','position',[plHortOffset+.1 plOffset-9*plVertSize-9*plVertDiff-0.01 .28 plVertSize]);

n = size(cmap,1);
image([0 1],[0 1],(1:n), 'Tag','Slice3ColorBar', 'ButtonDownFcn','Slice3(''colormap'')'); 
set(fig,'colormap',cmap)

uicontrol('style','text',...
    'units','normalized','position',[plHortOffset plOffset-9*plVertSize-9*plVertDiff-0.01 .1 plVertSize],...
    'units','normalized',...
    'parent',fig,...
    'string',num2str(hdr.lim(2)),'tag','MinLabel');

uicontrol('style','text',...
    'units','normalized','position',[plHortOffset+.38 plOffset+-9*plVertSize-9*plVertDiff-0.01 .1 plVertSize],...
    'units','normalized',...
    'parent',fig,...
    'string',num2str(hdr.lim(1)),'tag','MaxLabel');
axis off

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Set up the axes
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   
Sizes=hdr.dim(1:3).*hdr.siz;
maxS = max(Sizes);

maxX=max(Sizes(1:2));
maxY=max(Sizes(2:3));

WH=0.4;
pos1=WH*[Sizes(1)/maxX Sizes(2)/maxY];
pos2=WH*[Sizes(1)/maxX Sizes(3)/maxY];
pos3=WH*[Sizes(2)/maxX Sizes(3)/maxY];


axes('parent',fig,'position',[3*(0.5-pos1(1))/4  3*(0.5-pos1(2))/4 pos1],...
    'tag','Axis1');
xlabel('x');
ylabel('y');

axes('parent',fig,'position',[3*(0.5-pos2(1))/4  0.5+3*(0.5-pos2(2))/4 pos2],...
    'tag','Axis2')
xlabel('x');
ylabel('z');

axes('parent',fig,'position',[0.5+3*(0.5-pos3(1))/4  0.5+3*(0.5-pos3(2))/4 pos3],...
    'tag','Axis3')
xlabel('y');
ylabel('z');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Set up the sliders
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   

% Y-slider
ymin = hdr.siz(2)*(1-hdr.origin(2)-0.5);
ymax = hdr.siz(2)*(hdr.dim(2)-hdr.origin(2)+0.5);
uicontrol('style','slider','units','normalized','sliderStep',[1/hdr.dim(2)  10/hdr.dim(2)],...
    'tag','slideY','position',[0 3*(0.5-pos1(2))/4 .025 pos1(2)],...
    'parent',fig,'callback','Slice3(''Update'',''slider'',2)',...
    'min',ymin,'max',ymax,'value',(ymax-ymin)/2);
% X-slider
xmin = hdr.siz(1)*(1-hdr.origin(1)-0.5);
xmax = hdr.siz(1)*(hdr.dim(1)-hdr.origin(1)+0.5);
uicontrol('style','slider','units','normalized','sliderStep',[1/hdr.dim(1)  10/hdr.dim(1)],...
    'tag','slideX','position',[3*(0.5-pos1(1))/4 0 pos1(1) .025 ],...
    'parent',fig,'callback','Slice3(''Update'',''slider'',1)',...
    'min',xmin,'max',xmax,'value',(xmax-xmin)/2);

% Z-slider
zmin = hdr.siz(3)*(1-hdr.origin(3)-0.5);
zmax = hdr.siz(3)*(hdr.dim(3)-hdr.origin(3)+0.5);
uicontrol('style','slider','units','normalized','sliderStep',[1/hdr.dim(3)  10/hdr.dim(3)],...
    'tag','slideZ','position',[0 0.5+3*(0.5-pos2(2))/4 0.025 pos2(2)],...
    'parent',fig,'callback','Slice3(''Update'',''slider'',3)',...
    'min',zmin,'max',zmax,'value',(zmax-zmin)/2);



function ImproveClick(pane,task)
% Forced Zooming for point selection - only if task is 'click'
if strcmp(task,'click')
    fig0=get(pane,'parent');
    userdat=get(fig0,'userdata');
    fig=figure('numbertitle','off','name','Zoom','units','normalized','position',[0.01 0.01 0.99 0.99]);
    Axnum=get(pane,'tag');
    Axnum=str2num(Axnum(5));
    if Axnum==1
        coords=userdat.coords([1 2]);
        locked=3;
    elseif Axnum==2
        coords=userdat.coords([1 3]);
        locked=2;
    elseif Axnum==3
        coords=userdat.coords([2 3]);
        locked=1;
    end
    lines(1)=findobj(fig0,'parent',pane,'type','line','tag','x');
    lines(2)=findobj(fig0,'parent',pane,'type','line','tag','y');
    lines(3)=findobj(fig0,'parent',pane,'type','line','tag','px');
    lines(4)=findobj(fig0,'parent',pane,'type','line','tag','py');
    
    img=findobj(fig0,'parent',pane,'type','image');
    ax=axes('parent',fig,'position',[0 0 1 1]);
    x=get(img,'xdata');
    y=get(img,'ydata');
    cdat=get(img,'cdata');
    img1=image(x,y,cdat);
    colormap(get(fig0,'colormap'));
    axis image
    axis off
    set(ax,'ydir','normal');
    hold on
    lines(1)=plot(get(lines(1),'xdata'),get(lines(1),'ydata'),'w:','parent',ax);
    lines(2)=plot(get(lines(2),'xdata'),get(lines(2),'ydata'),'w:','parent',ax);
    if strcmp(get(lines(3),'visible'),'on')
        lines(3)=plot(get(lines(3),'xdata'),get(lines(3),'ydata'),'r:','parent',ax);
        lines(4)=plot(get(lines(4),'xdata'),get(lines(4),'ydata'),'r:','parent',ax);
    else
        lines=lines(1:2);
    end
    set(img1,'buttondownfcn','ZoomClick(''cursor'')');
    set(lines,'buttondownfcn','ZoomClick(''cursor'')');
    cross=plot(coords(1),coords(2),'gx','parent',ax,'tag','cursor','linewidth',5);
    hold off
    ud.TransStep=1;
    ud.Daddy=fig0;
    ud.locked=Axnum;
    set(fig,'keypressfcn','CheckKey_Slice3(''cursor'')','userdata',ud,'closerequestfcn','EndZoom',...
        'deletefcn','EndZoom')
    %    uicontrol('style','pushbutton','units','normalized','position',...
    %      [0 0.9 0.1 0.05],'callback','SetColor(findobj(''tag'',''cursor''))','string','Cursor Color');
end
