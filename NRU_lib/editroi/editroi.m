function []=editroi(arg1,arg2)
%EDITROI
% Function: editroi
%
% Program to define and extract region data from static and dynamic images
%
% Daniel Lindholm
% Neurobiology Research Unit
% Rigshospitalet, 1998
%
% Modified by Claus Svarer, 1999
% Circle drawing mode, region summaries for all images, multiload of images,
% multiframe statistics
% by Kenneth Geisshirt <kneth@pet.rh.dk>, 1999
%
% Modified by Claus Madsen, 040720000
% Posiblity to combine regions
% Bug Fixing:
%        When loading region empty regions is overwritten
%        The regions menu does disappear any more.
%
%        If empty regions exists, we know overwrite them.
%
% New Features:
%      Possible to combine regions. Not perfect but can be used in
%      certain situations
%
% Modified by Claus Madses, 20070000
% New Feature:
%     Showing the pixel value, for the current position of the
%     cursor
%
% Modified by Claus Madsen 11082000
% New Feature
%    Y axis is rotated 90 degrees. It is now vertical. The user can
%    freely choose Tallaric or voxel coordinats.
%
% Modified by Claus Madsen 17082000
% Changed feature:
%      Now Peter Willendrup method when combinding regions. Work only
%      HP-UX because nuage can not run on linux.,
% New freature:
%     Display sagital wiev.
%
% Modified by Claus Madsen 19092000
% Bug fixing errors, introducted by me. I had placed a return fatel place.
%
% CS, 201000
%   Changed ROI code to use roiploy instead of poly2bitmap
%
% Modified by Peter Jensen 25112009
%   Made editroi work together with the new SPECTpipeline
%
% Modified by Peter Jensen 11032010
%   Implemented new SPECTpipeline features
%

global ROIlastrollimg ...
    ROIlastzoomimg ...
    ROIcurrentfunc ...
    ROIcurrentmode ...
    ROIcurrentslice ...
    ROIcurrentobjs ...
    ROIcurrentpoints ...
    ROIeditmode ...
    ROIcurrentregion ...
    ROIupdatemask ...
    ROIcurrentroi ...
    ROIcurrentcenter...
    ROImovefcn...
    ROIyaxis...
    ROIhandleXYZstring ...
    ROImainfig...
    spectpipe;

persistent lastclick unselectobj;


if nargin>0
    switch(arg1)
        % this function is called when pointer moves over roll- or zoom-window
        case {'zm' 'rm' 'xm' 'ym'}
            a=get(gcbf,'UserData');
            if ~isempty(a)
                p=get(a.axes,'CurrentPoint');
                switch (arg1)
                    case 'xm' % x-cut window !
                        ud=get(a.slicehandles,'UserData');
                        mmpos=(p(1,1:2)-ud.offset)./ud.scale;
                        x=ud.x;
                        y=mmpos(1);
                        z=mmpos(2);
                        set(ROIhandleXYZstring(1),'String',sprintf('%.1f',x));
                        set(ROIhandleXYZstring(2),'String',sprintf('%.1f',y));
                        set(ROIhandleXYZstring(3),'String',sprintf('%.1f',z));

                    case 'ym' % y-cut window !
                        ud=get(a.slicehandles,'UserData');
                        mmpos=(p(1,1:2)-ud.offset)./ud.scale;
                        x=mmpos(1);
                        y=ud.y;
                        z=mmpos(2);
                        set(ROIhandleXYZstring(1),'String',sprintf('%.1f',x));
                        set(ROIhandleXYZstring(2),'String',sprintf('%.1f',y));
                        set(ROIhandleXYZstring(3),'String',sprintf('%.1f',z));

                    case 'zm' % zoom-window !
                        ud=get(a.slicehandles,'UserData');
                        mmpos=(p(1,1:2)-ud.offset)./ud.scale;
                        z=ud.relslice;
                        set(ROIhandleXYZstring(1),'String',sprintf('%.1f',mmpos(1)));
                        set(ROIhandleXYZstring(2),'String',sprintf('%.1f',mmpos(2)));
                        set(ROIhandleXYZstring(3),'String',sprintf('%.1f',a.z));

                    case 'rm'  % roll-window !
                        x=p(1,1);
                        if (x>=0.5) && (x<=a.dim(1)+0.5)
                            relslice=round(p(1,2)/a.imgheigth);
                            x=(x-a.origin(1))*a.siz(1);
                            y=((p(1,2)/a.imgheigth-relslice+0.5)*a.dim(2)-a.origin(2)+0.5)*a.siz(2);
                            z=relslice*a.siz(3);

                            if not(isempty(a.sidewindow))
                                plotslice('NewPos',round(z/a.siz(3) + a.origin(3)), a.sidewindow);
                            end;

                            set(ROIhandleXYZstring(1),'String',sprintf('%.1f',x));
                            set(ROIhandleXYZstring(2),'String',sprintf('%.1f',y));
                            set(ROIhandleXYZstring(3),'String',sprintf('%.1f',z));

                            SliceimgHandle= findobj('tag','sliceimg');
                            %r = relslice+a.origin(3);
                            r = relslice;
                            r = a.dim(3)-r;
                            if r > 0 && r <= a.dim(3)
                                cdata = get(SliceimgHandle(r),'cdata');
                                %
                                % Beregn koordinat positionen i voxel
                                %
                                voxel(1) =round(x/a.siz(1) + a.origin(1));
                                voxel(2) =round(y/a.siz(2) + a.origin(2));
                                if voxel(1) < 1
                                    voxel(1) = 1;
                                end
                                if voxel(2) < 1
                                    voxel(2) = 1;
                                end
                                s = size(cdata);

                                if voxel(2)>s(1)
                                    voxel(2) = s(1)-1;
                                end;
                                if voxel(1)>s(2)
                                    voxel(1) = s(2)-1;
                                end;
                                set(ROIhandleXYZstring(4),'String',sprintf('%f',cdata(voxel(2),voxel(1))));
                            end
                            mmpos=[x y];
                        else
                            mmpos=[];
                        end;
                end
            end
            switch ROImovefcn   % do something ?

                case 'rub'   % moving rubberband select box
                    p=p(1,1:2);
                    x=[ROIcurrentpoints(1) ROIcurrentpoints(1) p(1) p(1) ROIcurrentpoints(1)];
                    y=[ROIcurrentpoints(2) p(2) p(2) ROIcurrentpoints(2) ROIcurrentpoints(2)];
                    if isempty(ROIcurrentobjs)
                        ROIcurrentobjs=line(x,y,'EraseMode','xor', ...
                            'LineStyle','--', ...
                            'Color', [1 1 1]);
                    else
                        set(ROIcurrentobjs, 'XData', x, 'YData',y);
                    end

                case 'mir'   % update mirror line
                    p=p(1,1:2);
                    x=get(ROIcurrentobjs, 'XData');
                    y=get(ROIcurrentobjs, 'YData');
                    x=[x(1) p(1)];
                    y=[y(1) p(2)];
                    set(ROIcurrentobjs, 'XData', x, 'YData',y);

                case 'edit'  % drag node
                    x=get(ROIcurrentobjs,'XData');
                    y=get(ROIcurrentobjs,'YData');
                    x(ROIcurrentpoints)=p(1,1);
                    y(ROIcurrentpoints)=p(1,2);
                    set(ROIcurrentobjs,'XData',x,'YData',y);

                case 'move'   % move entire polygon

                    dist=p(1,1:2)-ROIcurrentpoints;
                    if isempty(ROIcurrentobjs)
                        hs=findobj(gcbf,'Tag','roipolygon','Selected','on');
                        ROIcurrentobjs=[];
                        for n=1:length(hs)
                            d=get(hs(n),'UserData');
                            if d.slicehandle==ROIcurrentslice
                                ROIcurrentobjs=[ROIcurrentobjs; hs(n)];
                            end
                        end
                        if length(ROIcurrentobjs)>1
                            ROIcurrentroi={};
                            ROIcurrentroi(:,1)=get(ROIcurrentobjs,'XData');
                            ROIcurrentroi(:,2)=get(ROIcurrentobjs,'YData');
                        else
                            ROIcurrentroi={get(ROIcurrentobjs,'XData') ...
                                get(ROIcurrentobjs,'YData')};
                        end
                        set(ROIcurrentobjs, 'EraseMode','xor', ...
                            'Selected','off', ...
                            'Color', [1 1 1]);
                        set(gcbf,'Pointer','fleur');
                    end
                    for n=1:length(ROIcurrentobjs)
                        set(ROIcurrentobjs(n),'XData',ROIcurrentroi{n,1}+dist(1), ...
                            'YData',ROIcurrentroi{n,2}+dist(2));
                    end

                case 'resiz'   % resize one or more polygons
                    if isempty(ROIcurrentobjs)
                        ROIcurrentobjs=findobj(gcbf,'Tag','roipolygon','Selected','on');
                        vertex=[];
                        for n=1:length(ROIcurrentobjs)
                            vertex=[vertex; GetPolygonRoi(ROIcurrentobjs(n))];
                        end
                        ROIcurrentcenter=mean([max(vertex); min(vertex)]);
                        set(ROIcurrentobjs, 'EraseMode','xor', ...
                            'Selected','off', ...
                            'Color', [1 1 1]);
                        set(gcbf,'Pointer','fleur');
                    end
                    dist1=mmpos-ROIcurrentcenter;
                    dist2=ROIcurrentpoints-ROIcurrentcenter;
                    scale=dist1./dist2;
                    for n=1:length(ROIcurrentobjs)
                        ld=get(ROIcurrentobjs(n),'UserData');
                        x=get(ROIcurrentobjs(n),'XData');
                        y=get(ROIcurrentobjs(n),'YData');
                        ud=get(ld.slicehandle,'UserData');
                        x=(x-ud.offset(1))/ud.scale(1);
                        y=(y-ud.offset(2))/ud.scale(2);
                        x=(x-ROIcurrentcenter(1))*scale(1)+ROIcurrentcenter(1);
                        y=(y-ROIcurrentcenter(2))*scale(2)+ROIcurrentcenter(2);
                        x=x*ud.scale(1)+ud.offset(1);
                        y=y*ud.scale(2)+ud.offset(2);
                        set(ROIcurrentobjs(n),'XData',x, ...
                            'YData',y);
                    end
                    ROIcurrentpoints=mmpos;

                case 'rot'
                    if ~isempty(mmpos)
                        if (mmpos~=ROIcurrentcenter(1:2))
                            angle=atan((mmpos(2)-ROIcurrentcenter(2))./(mmpos(1)-ROIcurrentcenter(1)));
                            if mmpos(1)<ROIcurrentcenter(1)
                                angle=angle+pi;
                            end
                            deltaangle=angle-ROIcurrentcenter(3);
                            if length(ROIcurrentobjs)>1
                                ld=get(ROIcurrentobjs,'UserData');
                                x=get(ROIcurrentobjs,'XData');
                                y=get(ROIcurrentobjs,'YData');

                            else
                                ld={get(ROIcurrentobjs,'UserData')};
                                x={get(ROIcurrentobjs,'XData')};
                                y={get(ROIcurrentobjs,'YData')};
                            end
                            for n=1:length(ROIcurrentobjs)
                                ud=get(ld{n}.slicehandle,'UserData');
                                % calculate vertex in mm
                                x1=(x{n}'-ud.offset(1))./ud.scale(1) - ROIcurrentcenter(1,1);
                                y1=(y{n}'-ud.offset(2))./ud.scale(2) - ROIcurrentcenter(1,2);
                                % rotate
                                warning('off');
                                a1=atan(y1./x1);
                                warning('on');
                                x2=x1.*cos(a1+deltaangle)./cos(a1);
                                y2=y1.*sin(a1+deltaangle)./sin(a1);

                                % revers scaling
                                x1=(x2 + ROIcurrentcenter(1,1))*ud.scale(1)+ud.offset(1);
                                y1=(y2 + ROIcurrentcenter(1,2))*ud.scale(2)+ud.offset(2);
                                set(ROIcurrentobjs(n),'XData',x1,'YData',y1);
                            end
                            ROIcurrentcenter(3)=angle;
                        end
                    end


            end
            return;

        case 'zdown'         % button down on zoom-image
            sel=get(gcbf,'SelectionType');
            if ROIeditmode==0
                %        disp(sel);
                ROIlastzoomimg=gcbo;
                sel=get(gcbf,'SelectionType');
                switch sel
                    case 'alt'
                    otherwise
                        % calculate x-y voxel position relative to origin in mm
                        ud=get(gcbo,'UserData');
                        p=get(gca,'CurrentPoint');
                        mmpos=(p(1,1:2)-ud.offset)./ud.scale;
                        z=ud.relslice;
                        %            disp(sprintf('x=%g(mm) y=%g(mm) z=%g (rel)',mmpos(1),mmpos(2),z));
                        ClickFunc(mmpos, z, sel, lastclick);
                        RedrawMasks
                end
            else
                switch ROIcurrentfunc
                    case 'mirror'
                        if strcmp(sel,'normal')
                            ClickMirror;
                        end

                    case 'rotate'
                        if strcmp(sel,'normal')
                            % calculate x-y voxel position relative to origin in mm
                            ud=get(gcbo,'UserData');
                            p=get(gca,'CurrentPoint');
                            mmpos=(p(1,1:2)-ud.offset)./ud.scale;
                            ClickRotate(mmpos);
                        end

                    otherwise
                        if strcmp(sel,'normal')
                            % Start rubberband box to select multiple objects
                            ROImovefcn='rub';
                            set(gcbf,'WindowButtonUpFcn','editroi(''rubup'')');

                            p=get(gca,'CurrentPoint');
                            ROIcurrentpoints=p(1,1:2);
                            ROIcurrentslice=gcbo;
                        end
                end
            end
            lastclick=sel;
            return;

        case 'rdown'         % button down on roller-image
            sel=get(gcbf,'SelectionType');
            ROIlastrollimg=gcbo;
            if ROIeditmode==0
                %        disp(sel);
                switch sel
                    case 'alt'
                    otherwise
                        % calculate x-y voxel position relative to origin in mm
                        ud=get(gcbo,'UserData');
                        p=get(gca,'CurrentPoint');
                        mmpos=(p(1,1:2)-ud.offset)./ud.scale;
                        z=ud.relslice;
                        %            disp(sprintf('x=%g(mm) y=%g(mm) z=%g (rel)',mmpos(1),mmpos(2),z));
                        ClickFunc(mmpos, z, sel, lastclick);
                        RedrawMasks
                end
            else
                switch ROIcurrentfunc
                    case 'mirror'
                        if strcmp(sel,'normal')
                            ClickMirror;
                        end

                    case 'rotate'
                        if strcmp(sel,'normal')
                            % calculate x-y voxel position relative to origin in mm
                            ud=get(gcbo,'UserData');
                            p=get(gca,'CurrentPoint');
                            mmpos=(p(1,1:2)-ud.offset)./ud.scale;
                            ClickRotate(mmpos);
                        end

                    otherwise
                        if strcmp(sel,'normal')
                            % Start rubberband box to select multiple objects
                            ROImovefcn='rub';
                            set(gcbf,'WindowButtonUpFcn','editroi(''rubup'')');

                            p=get(gca,'CurrentPoint');
                            ROIcurrentpoints=p(1,1:2);
                            ROIcurrentslice=gcbo;
                        end
                end
            end
            lastclick=sel;
            return;

        case 'edup'
            set(gcbf,'WindowButtonUpFcn','');
            ROImovefcn='';
            x=get(ROIcurrentobjs,'XData');
            y=get(ROIcurrentobjs,'YData');
            p=get(gca,'CurrentPoint');
            x(ROIcurrentpoints)=p(1,1);
            y(ROIcurrentpoints)=p(1,2);
            if any([x' y']~=ROIcurrentroi)
                StartNextUndo;
                MakePolygonChange(ROIcurrentobjs, x, y);
            else
                ld=get(ROIcurrentobjs, 'UserData');
                set(ROIcurrentobjs, 'EraseMode','normal', ...
                    'Color', GetRegionColor(ld.region));
            end
            ROIcurrentobjs=[];
            ROIcurrentroi=[];
            RedrawMasks;
            return;


        case 'moup'  % button released after moving polygon
            ROImovefcn='';
            set(gcbf,'WindowButtonUpFcn','');
            p=get(gca,'CurrentPoint');
            dist=p(1,1:2)-ROIcurrentpoints;
            if any(dist~=[0 0])
                StartNextUndo;
                for n=1:length(ROIcurrentobjs)
                    x=ROIcurrentroi{n,1}+dist(1);
                    y=ROIcurrentroi{n,2}+dist(2);
                    MakePolygonChange(ROIcurrentobjs(n), x, y);
                end
            else
                set(unselectobj,'Selected','off');
            end
            ROIcurrentobjs=[];
            ROIcurrentroi=[];
            set(gcbf,'Pointer','arrow');
            RedrawMasks;
            return;

        case 'rezup'  % button released after resizing polygon
            ROImovefcn='';
            set(gcbf,'WindowButtonUpFcn','');
            if ~isempty(ROIcurrentobjs)
                StartNextUndo;
                for n=1:length(ROIcurrentobjs)
                    x=get(ROIcurrentobjs(n),'XData');
                    y=get(ROIcurrentobjs(n),'YData');
                    MakePolygonChange(ROIcurrentobjs(n), x, y);
                end
            else
                set(unselectobj,'Selected','off');
            end
            ROIcurrentobjs=[];
            ROIcurrentroi=[];
            ROIcurrentpoint=[];
            set(gcbf,'Pointer','arrow');
            RedrawMasks;
            return;

        case 'rotup'  % button released after rotating polygon
            ROImovefcn='';
            set(gcbf,'WindowButtonUpFcn','');
            if 1
                StartNextUndo;
                for n=1:length(ROIcurrentobjs)
                    x=get(ROIcurrentobjs(n),'XData');
                    y=get(ROIcurrentobjs(n),'YData');
                    MakePolygonChange(ROIcurrentobjs(n), x, y);
                end
            else
                for n=1:length(ROIcurrentobjs)
                    ld=get(ROIcurrentobjs(n),'UserData');
                    set(ROIcurrentobjs(n),'Selected','off', ...
                        'EraseMode','normal', ...
                        'Color',GetRegionColor(ld.region));
                end
            end
            ROIcurrentobjs=[];
            ROIcurrentroi=[];
            RedrawMasks;
            return;

        case 'rubup'  % button released after rubberband select box
            ROImovefcn='';
            set(gcbf,'WindowButtonUpFcn','');
            p=get(gca,'CurrentPoint');
            p=p(1,1:2);
            x=[ROIcurrentpoints(1) p(1)];
            x=[min(x) max(x)];
            y=[ROIcurrentpoints(2) p(2)];
            y=[min(y) max(y)];
            h=findobj(gca,'Tag','roipolygon');
            if any([x(1)-x(2) y(1)-y(2)]~=[0 0])
                for n=1:length(h)
                    lx=get(h(n),'XData');
                    ly=get(h(n),'YData');
                    if (lx>=x(1)) && (lx<=x(2))
                        if (ly>=y(1)) && (ly<=y(2))
                            set(h(n),'Selected','on');
                        end
                    end
                end
            else
                switch ROIcurrentfunc
                    case 'copy'
                        id=GetSelectedIds;
                        StartNextUndo;
                        ud=get(ROIcurrentslice,'UserData');
                        CopyPolygonToSlice(id,ud.relslice);
                        RedrawMasks;
                    otherwise
                        set(h,'Selected','off');
                end
            end
            if ishandle(ROIcurrentobjs)
                delete(ROIcurrentobjs);
            end
            ROIcurrentobjs=[];
            ROIcurrentroi=[];
            return;


        case 'pdown'         % button down on polygon
            sel=get(gcbf,'SelectionType');
            switch(ROIcurrentfunc)
                case 'edit'
                    p=get(gca,'CurrentPoint');
                    x=get(gcbo,'XData');
                    y=get(gcbo,'YData');
                    ROIcurrentroi=[x' y'];
                    dist=(x-p(1,1)).^2+(y-p(1,2)).^2;
                    m=min(dist);

                    switch sel
                        case {'normal'; 'extend'}
                            ROImovefcn='edit';
                            set(gcbf,'WindowButtonUpFcn','editroi(''edup'')');
                            ROIcurrentobjs=gcbo;
                            if strcmp(sel,'normal')
                                ROIcurrentpoints=find(dist==m);
                                x(ROIcurrentpoints)=p(1,1);
                                y(ROIcurrentpoints)=p(1,2);
                            else
                                m=Inf;
                                i=1;
                                l=length(x);
                                for n=1:l-1
                                    a=dist2line(x(n:n+1),y(n:n+1),p(1,1),p(1,2));
                                    if a<m
                                        m=a;
                                        i=n;
                                    end
                                end
                                x=[x(1:i) p(1,1) x(i+1:l)];
                                y=[y(1:i) p(1,2) y(i+1:l)];
                                ROIcurrentpoints=i+1;
                                ROIcurrentroi=[ROIcurrentroi; NaN NaN];
                            end
                            set(gcbo,'XData',x,'YData',y,'EraseMode','xor','Color', [1 1 1]);


                        case 'alt'  % delete point
                            i=find(dist~=m);
                            x=x(i);
                            y=y(i);
                            l=length(x);
                            if (x(1)~=x(l)) || (y(1)~=y(l))
                                x(l+1)=x(1);
                                y(l+1)=y(1);
                            end
                            MakePolygonChange(gcbo, x, y);
                            RedrawMasks;
                    end

                case {'move' 'resize'}
                    if strcmp(get(gcbo,'Selected'),'on')
                        unselectobj=gcbo;
                    else
                        unselectobj=[];
                        set(gcbo,'Selected','on');
                    end
                    p=get(gca,'CurrentPoint');
                    ld=get(gcbo,'UserData');
                    ROIcurrentslice=ld.slicehandle;
                    ROIcurrentpoints=p(1,1:2);
                    ROIcurrentobjs=[];
                    switch ROIcurrentfunc
                        case 'move'
                            ROImovefcn='move';
                            set(gcbf,'WindowButtonUpFcn','editroi(''moup'')');
                        case 'resize'
                            ROImovefcn='resiz';
                            set(gcbf,'WindowButtonUpFcn','editroi(''rezup'')');
                            ud=get(ROIcurrentslice,'UserData');
                            ROIcurrentpoints=(ROIcurrentpoints-ud.offset)./ud.scale;
                    end

                case { 'mirror' 'rotate' 'copy'}
                    if strcmp(get(gcbo,'Selected'),'on')
                        set(gcbo,'Selected','off');
                    else
                        set(gcbo,'Selected','on');
                    end

                otherwise
            end
            return;

        case 'close'


        case 'rslider'       % slider on roll-image

            hcf=gcf;

            if nargin == 1 
                SlVal=get(gcbo,'Value');
            else
                a=get(gcf,'UserData');
                SlVal=arg2/a.dim(3);
            end

            hf=findobj('tag','zoom');
            for i=1:length(hf)
                set(findobj(hf(i),'Tag','Slider1'),'Value',SlVal)

                a=get(hf(i),'UserData');
                y=SlVal*(a.ylen-a.ycount*a.imgheigth);
                set(findobj(hf(i),'Tag','roll'),...
                     'YLim',[y y+a.ycount*a.imgheigth]+a.ymin);
                showyaxis(hf(i));                
            end

            figure(hcf);
            return;

        case 'resizeroll'
            a=get(arg2,'UserData');
            figure(arg2)
            set(arg2,'Units','pixels');
            pos=get(arg2,'Position');
            ax=findobj(arg2,'Tag','roll');
            set(ax,'Units','pixels','Position',[20 38 pos(3)-45 pos(4)-45]);
            cb=findobj(arg2,'Tag','Colorbar');
            set(cb,'Units','pixels','Position',[20 18 pos(3)-23 15]);
            sl=findobj(arg2,'Tag','Slider1');
            set(sl,'Position',[pos(3)-20 38 20 pos(4)-45]);
            set(ax,'Units','centimeters');
            p=get(ax,'Position');
            a.ycount=(p(4)/p(3))/a.aspect;
            y=get(sl,'Value')*(a.ylen-a.ycount*a.imgheigth);
            set(ax,'YLim',[y y+a.ycount*a.imgheigth]+a.ymin);
            step=[1/(a.dim(3)-a.ycount) a.ycount/(a.dim(3)-a.ycount)];
            % step=[min(step) max(step)];
            % Decreased the movement of the slider, cmm 250900
            step=[min(step)*.25 max(step)*.7];
            set(sl,'SliderStep',step);

            set(arg2,'UserData',a);

            showyaxis
            return

        case 'resizezoom'
            a=get(gcbf,'UserData');
            set(gcbf,'Units','centimeters');
            p=get(gcbf,'Position');
            faspect=(p(4)/p(3));
            if faspect>a.aspect
                p(4)=p(3)*a.aspect;
                set(gcbf,'Position',p);
            else
                p(3)=p(4)/a.aspect;
                set(gcbf,'Position',p);
            end
            showyaxis
            return;

        case 'newzoom'    % callback from roll context-menu
            a=get(gcbf,'UserData');
            n=get(gcbf,'Name');
            ud=get(ROIlastrollimg,'UserData');  % slice no...
            img=get(ROIlastrollimg,'CData');
            s=ud.relslice;
            cmap=get(gcf,'ColorMap');
            clim=get(gca,'CLim');
            name=sprintf('%s   Z=%d mm', n, ud.relslice*a.siz(3));

            NewZoomFigure(img, cmap, clim, name, ...
                a.aspect, s, a.siz, a.origin);
            return;

        case 'newmask'    % callback from roll context-menu
            a=get(gcbf,'UserData');
            n=get(gcbf,'Name');
            ud=get(ROIlastrollimg,'UserData');  % slice no...
            s=ud.relslice;
            img=get(ROIlastrollimg,'CData');
            region=1;
            name=sprintf('%s   Z=%d mm', GetRegionName(ROIcurrentregion), ...
                ud.relslice*a.siz(3));
            NewMaskFigure(size(img), name, ...
                a.aspect, s, a.siz, a.origin, ROIcurrentregion);
            RedrawMasks;
            return;

        case 'newcut'
            MakeCutFigure(gcf);

        case 'updateallcut'
            h=findobj('Type','figure','Tag','roicut');
            UpdateCutFigure(h);

        case 'calculateroll'    % Slightly modified by kneth
            handles=findobj('Type', 'axes');
            for n=1:length(handles)
                tag=get(handles(n), 'Tag');
                if strcmp(tag, 'roll')==1
                    MakeRegionSummary(handles(n));
                end
            end

        case 'rollhisto'
            n=get(gcbf,'Name');
            h=findobj(gca,'Tag','sliceimg');
            a=get(gcf,'UserData');
            Data=get(GetMainFigure,'UserData');
            MakeHistogram(h,[a.min a.max],Data.histobins,sprintf('Histogram for ''%s''',n));

        case 'draw'
            ROIcurrentfunc=arg2;
            delete(ROIcurrentobjs);
            ROIcurrentobjs=[];
            ROIcurrentroi=[];
            Editmode(0);

            hd=NaN;
            switch arg2
                case 'poly'
                    SetHelpText('Draw: Polygon');
                    hd=findobj(gcbf,'Tag','butPoly');
                case 'contour'
                    SetHelpText('Draw: Contour');
                    hd=findobj(gcbf,'Tag','butContour');
                case 'ellipse'
                    SetHelpText('Draw: Circle');
                    hd=findobj(gcbf,'Tag','butEllipse');
            end
            hu=findobj(gcbf,'UserData','drawbutton');
            if ishandle(hd)
                i=find(hu~=hd);
                set(hu(i),'Value',0);
                set(hd,'Value',1);
            else
                set(hu,'Value',0);
            end


        case 'drawmode'
            p=get(gcbo,'Parent');
            h1=findobj(p,'Tag','popInout');
            h2=findobj(p,'Tag','popAdd');
            v1=get(h1,'Value');
            v2=get(h2,'Value');
            s1=get(h1,'String');
            s2=get(h2,'String');
            ROIcurrentmode=[s1{v1} s2{v2}];
            %      Editmode(0);
            UpdatePreviewLine;

        case 'loadimg'
            if nargin == 1
                [files, results] = ui_choosefiles('.','*.img','Load Images');
                for n=1:length(files)
                    name=files{n};
                    h=NewRollFigure(name(1:length(name)-4));
                    showtallarich(gcf, h);
                end
            elseif nargin == 2
                [fpath,fname] = fileparts(arg2);
                h=NewRollFigure(fname);
                showtallarich(gcf, h);
            end
                

        case 'timestudy'
            [fil pat] = uigetfile('*.img','Load 4D Image');
            if fil~=0
                [path, nam, ext] = fileparts(fil);
                Plot4DFile(fullfile(pat, nam));
            end

        case 'multiframe'
            [files, results] = ui_choosefiles('.', '*.img', 'Load Images');
            PlotMultiFrame(files);

        case 'movenodes'
            Editmode(1);
            ROIcurrentfunc='move';
            delete(ROIcurrentobjs);
            ROIcurrentobjs=[];
            SetHelpText('Select and move polygons');
            hu=findobj(gcbf,'UserData','drawbutton');
            hd=findobj(gcbf,'Tag','butMove');
            i=find(hu~=hd);
            set(hu(i),'Value',0);
            set(hd,'Value',1);
            ROImovefcn='';

        case 'editnodes'
            Editmode(1);
            ROIcurrentfunc='edit';
            delete(ROIcurrentobjs);
            ROIcurrentobjs=[];
            SetHelpText('Move/add/delete nodes');
            hu=findobj(gcbf,'UserData','drawbutton');
            hd=findobj(gcbf,'Tag','butEdit');
            i=find(hu~=hd);
            set(hu(i),'Value',0);
            set(hd,'Value',1);
            ROImovefcn='';

        case 'rotate'
            Editmode(1);
            ROIcurrentfunc='rotate';
            delete(ROIcurrentobjs);
            ROIcurrentobjs=[];
            SetHelpText('Set center and rotate selected polygons');
            hu=findobj(gcbf,'UserData','drawbutton');
            hd=findobj(gcbf,'Tag','butRotate');
            i=find(hu~=hd);
            set(hu(i),'Value',0);
            set(hd,'Value',1);
            ROImovefcn='';

        case 'resizenodes'
            Editmode(1);
            ROIcurrentfunc='resize';
            delete(ROIcurrentobjs);
            ROIcurrentobjs=[];
            SetHelpText('Select and resize polygons');
            hu=findobj(gcbf,'UserData','drawbutton');
            hd=findobj(gcbf,'Tag','butResize');
            i=find(hu~=hd);
            set(hu(i),'Value',0);
            set(hd,'Value',1);
            ROImovefcn='';

        case 'mirror'
            Editmode(1);
            ROIcurrentfunc='mirror';
            delete(ROIcurrentobjs);
            ROIcurrentobjs=[];
            SetHelpText('Draw line to mirror selected polygons');
            hu=findobj(gcbf,'UserData','drawbutton');
            hd=findobj(gcbf,'Tag','butMirror');
            i=find(hu~=hd);
            set(hu(i),'Value',0);
            set(hd,'Value',1);
            ROImovefcn='';

        case 'copy'
            Editmode(1);
            ROIcurrentfunc='copy';
            delete(ROIcurrentobjs);
            ROIcurrentobjs=[];
            SetHelpText('Click on slice to copy selected polygons');
            hu=findobj(gcbf,'UserData','drawbutton');
            hd=findobj(gcbf,'Tag','butCopy');
            i=find(hu~=hd);
            set(hu(i),'Value',0);
            set(hd,'Value',1);
            ROImovefcn='';

        case 'selectregion'
            if nargin==2
                ROIcurrentregion=arg2;
                h=findobj(gcf,'Tag','mnuRegionItem');
                set(h,'Checked','off');
                set(gcbo,'Checked','on');
                h=findobj(gcbf,'Tag','popRegion');
                set(h,'Value',ROIcurrentregion);
            else                         % Callback from Popup-menu
                ROIcurrentregion=get(gcbo,'Value');
            end
            UpdatePreviewLine;
            return;

        case 'newregion'
            r=InputNewRegion;
            if (r)
                ROIcurrentregion=r;
                h=findobj(gcf,'Tag','mnuRegionItem');
                set(h,'Checked','off');
                h=findobj(h,'UserData',r);
                set(h,'Checked','on');
                h=findobj(gcf,'Tag','popRegion');
                set(h,'Value',r);
                UpdatePreviewLine;
            end
            return;

        case 'renregion'
            RenameRegion(ROIcurrentregion);
            return;

        case 'regioncol'
            EditRegionColor(ROIcurrentregion);
            UpdatePreviewLine;
            return;

        case 'combineRegion'
            combineRegion(ROIcurrentregion);
            return;

        case 'undo'
            Undo(0);
            RedrawMasks;
            return;

        case 'redo'
            Undo(1);
            RedrawMasks;
            return;

        case 'delete'
            id=GetSelectedIds;
            if ~isempty(id)
                StartNextUndo;
                DeletePolygons(id);
                RedrawMasks;
            end

            %    case 'edcut'
            %      id = GetSelectedIds;
            %      if ~isempty(id)
            %        Data=get(GetMainFigure,'UserData');
            %        Data.clipboard=id;
            %        set(GetMainFigure,'UserData',Data);
            %        StartNextUndo;
            %        DeletePolygons(id);
            %        RedrawMasks;
            %      end

            %    case 'edcopy'
            %      id = GetSelectedIds;
            %      if ~isempty(id)
            %        Data=get(GetMainFigure,'UserData');
            %        Data.clipboard=id;
            %        set(GetMainFigure,'UserData',Data);
            %      end

            %    case 'edpaste'

        case 'selectall'
            h=findobj('Tag','roipolygon');
            set(h,'Selected','on');

        case 'selectallregion'
            h=findobj('Tag','roipolygon','EraseMode','normal');
            if length(h)>1
                ld=get(h,'UserData');
            else
                ld={get(h,'UserData')};
            end
            for n=1:length(h);
                if ld{n}.region==ROIcurrentregion
                    set(h(n),'Selected','on');
                end
            end

        case 'changeregion'
            id=GetSelectedIds;
            if ~isempty(id)
                StartNextUndo;
                DeletePolygons(id);
                CopyPolygonToRegion(id,ROIcurrentregion);
                RedrawMasks;
            end

        case 'changemode'
            id=GetSelectedIds;
            if ~isempty(id)
                StartNextUndo;
                ChangePolygonDrawmode(id,ROIcurrentmode);
                RedrawMasks;
            end

        case 'load'
            if nargin == 1
                LoadMatlabFile;
                RedrawMasks;
            elseif nargin == 2
               [path, name, ext] = fileparts(arg2);
                name = [name ext];
                if ~ischar(name)
                    return;
                end
                filename=fullfile(path,name);
                
                gData=get(GetMainFigure,'UserData');
                gData.filename=name;
                set(GetMainFigure,'UserData',gData);
                [S, message] = LoadRoi(filename,gData);
                if isempty(S)
                    warndlg(message)
                    return
                end
                
                if not(isempty(S.region))
                    StartNextUndo
                    for i=1:length(S.regionname)
                        region = AddNewRegion(S.regionname{i});
                        for j=1:length(S.region)
                            if S.region(j) == i
                                AddRoi(S.vertex{j},S.mode{j},S.relslice(j),region);
                            end
                        end
                    end
                end
                RedrawMasks;
                fig=GetMainFigure;
                set(fig,'Name',name);
                
            end

        case 'save'
            SaveInMatlabFile(0);

        case 'saveas'
            SaveInMatlabFile(1);

        case 'exporttxt'
            Data=get(GetMainFigure,'UserData');
            [sel, ok]=listdlg('SelectionMode','multiple', ...
                'InitialValue',1:length(Data.regionname), ...
                'PromptString',{'Select one or more regions' ...
                'to export:'}, ...
                'ListString',Data.regionname, ...
                'Name', 'Regions');
            if ~ok, return; end;
            [fil, pat]=uiputfile('*.txt', 'Export Regions');
            if ischar(nam)
                [path, nam, ext] = fileparts(fil);
                if ~strcmp(ext,'.txt')
                    fil=[nam ext '.txt'];
                else
                    fil=[nam ext];
                end
                name=fullfile(pat,fil);
                SaveInTextFile(name,sel);
            end

        case 'savemask'
            Data=get(GetMainFigure,'UserData');
            [sel, ok]=listdlg('SelectionMode','multiple', ...
                'InitialValue',ROIcurrentregion, ...
                'PromptString',{'Select one or more regions' ...
                'to include in bitmap-image:'}, ...
                'ListString',Data.regionname, ...
                'Name', 'Regions');
            if ~ok, return; end;
            [mode, ok]=listdlg('SelectionMode','single', ...
                'InitialValue',1, ...
                'PromptString',{'Generate image as:'}, ...
                'ListString',{'Zeros and ones', ...
                'Zeros and image inside', ...
                'Zeros and image outside'}, ...
                'Name', 'Save Mode');
            if ~ok, return; end;
            [nam, pat]=uiputfile('*.img', 'Save Image As');
            if ischar(nam)
                name=fullfile(pat,nam);
                if strcmp(name(end-3:end),'.img')
                    name=name(1:end-4);
                end
                SaveMask(gcbf, sel, name, mode);
            end


        case 'showvoxel'
            showvoxel(gcbf)

        case 'showtallarich'
            showtallarich(gcbf)

        case 'showsideview'
            g = gcbf;
            a=get(g,'UserData');
            if isempty(a.sidewindow)
                %color = findobj(g,'tag','Colorbar');
                color = findobj(g,'tag','roll');
                %colorUD = get(color,'userdata');
                %clim = get(colorUD.PlotHandle(1),'clim');
                clim = get(color,'clim');
                a.sidewindow = plotslice('init',a,g,clim);

                set(g,'userdata',a);
%                colorUD.PlotHandle = [colorUD.PlotHandle findobj(a.sidewindow,'tag','plotslice_a')];
%               set(color,'userdata',colorUD);
                color = [color findobj(a.sidewindow,'tag','plotslice_a')];
                set(color,'userdata',color);
                set(a.sidewindow,'colormap', get(g,'colormap'));

%                set(findobj(a.sidewindow,'tag','plotslice_a'),'clim', get(colorUD.PlotHandle(1),'clim'));
                set(findobj(a.sidewindow,'tag','plotslice_a'),'clim', clim);

                figure(g);
                showyaxis;
            end
            return

        case 'showyaxis'
            showyaxis
            return


        case 'clearall'
            if spectpipe ~= 1
                a=questdlg('Clear all regions?', '', 'No', 'Yes', 'No');
                if strcmp(a,'Yes')
                    ClearAllRegions;
                end
            else
                ClearAllRegions;
            end

        case 'saveplot'
            if spectpipe ~= 1
                [fil pat] = uiputfile('*.txt','Save Data As...');
                if fil~=0
                    [path, nam, ext] = fileparts(fil);
                    if ~strcmp(ext,'.txt')
                        fil=[nam ext '.txt'];
                    else
                        fil=[nam ext];
                    end
                    saveplot(gcf, fullfile(pat, fil))
                end
            else
                % Special use under the SPECTpipeline
                fil='RegionSummary.txt';
                pat=pwd;
                saveplot(gcf,fullfile(pat, fil))
                RegSumfig=findobj('Name','Region Summary for ''PatientInTemplateSpace''');
                ROIsfig=findobj('type','figure','Name','PatientInTemplateSpace');
                set(ROIsfig,'CloseRequestFcn','closereq');
                editroifig=findobj('type','figure','Name','AllROIs');
                set(editroifig,'CloseRequestFcn','closereq');
                neweditroifig=findobj('type','figure','Name','AllROIs.mat');
                set(neweditroifig,'CloseRequestFcn','closereq');
                correditroifig=findobj('type','figure','Name','AllROIs_corr');
                set(correditroifig,'CloseRequestFcn','closereq');
                roiautofig = findobj('type','figure','Name','roiauto');
                delete(RegSumfig)
                delete(ROIsfig)
                delete(editroifig)
                delete(neweditroifig)
                delete(correditroifig)
                delete(roiautofig)
            end

        case 'histogramset'
            fig=GetMainFigure;
            Data=get(fig,'UserData');
            d={num2str(Data.histobins)};
            a=inputdlg('Enter number of bins:','Histogram Setup',1,d);
            if ~isempty(a)
                v=str2num(a{1});
                if ~isempty(v)
                    Data.histobins=v;
                    set(fig,'UserData',Data);
                end
            end

        case 'SpectPipeline'
            spectpipe = 1;
            
        case 'SpectPipelineError'
            errordlg('You can only close this figure by saving a region summary!','SPECTpipeline error')
            
        case 'SpectPipelineWarning'
            answer = questdlg('Are you done manually correcting the ROIs?','Continue?','Yes','No','Yes');
            if strcmp(answer,'Yes')
                editroi('SpectPipelineCloseFig');
            else
                return;
            end
            
        case 'SpectPipelineCloseFig'
            editroi('save')
            ROIsfig=findobj('type','figure','Name','PatientInTemplateSpace');
            editroifig=findobj('type','figure','Name','ROIStriatum_central');
            set(ROIsfig,'CloseRequestFcn','closereq')
            delete(ROIsfig);
            delete(editroifig);
            
        otherwise
            disp(arg1);
            return;

    end
else
    ROImainfig=findobj('Tag','editroi'); % see if main figure exist
    fig=ROImainfig;
    spectpipe = 0;
    
    if isempty(fig)
        load roidefaultcolors

        a.slicepolys.vertex={};   % vertex data for each slice
        a.slicepolys.mode={};     % text string describing mode
        a.slicepolys.id=[];       % the id of each polygon
        a.slicepolys.region=[];   % the region of each polygon
        a.slicepolys.relslice=[]; % Which slice the polygon applies to
        a.slicepolys.status={};   % text string describing status ('','deleted')
        a.regioncolor=roidefaultcolors;
        a.regionname{1,1}='Region 1';
        a.undostack={};           % stack containing id's to undo/redo
        a.undopointer=0;          % the number of undos to make
        a.slicedist=[];      % slice distance
        a.nextid=1;          % the id for next roi to add
        a.filename='';
        a.histobins=64;      % number of bins in histogram
        %    a.clipboard=[];      % id's of polygons in clipboard

        fig=MakeMainFigure(a);  % make main figure
 
        lastclick='';
        ROImovefcn='';
        ROIcurrentmode='InsideAdd';
        ROIcurrentobjs=[];
        ROIcurrentroi=[];
        ROIeditmode=0;       % 1 if program is in edit mode
        ROIcurrentfunc='';
        ROIcurrentregion=1;
        ROIupdatemask=[];    % handles to masks that needs an update
        ROImainfig=fig;
        ROIyaxis = [];
    end
    ROIhandleXYZstring=[findobj('Tag','xpos'); ...
        findobj('Tag','ypos'); ...
        findobj('Tag','zpos'); ...
        findobj('Tag','value')];  % Store handles for optimization
end


%*******************************************
%*******************************************
%*******************************************
function Editmode(ed)

global ROIeditmode

if ed
    % turn on editing
    h=findobj('Tag','roipolygon');
    set(h,'HitTest','on');
    ROIeditmode=1;
else
    % turn off editing
    h=findobj('Tag','roipolygon');
    set(h,'HitTest','off');
    h=findobj('Selected','on');
    set(h,'Selected','off');
    ROIeditmode=0;
end

%************************

function ClickFunc(xy, relslice, type, lasttype)

global ROIcurrentfunc ...
    ROIcurrentmode ...
    ROIcurrentslice ...
    ROIcurrentobjs ...
    ROIcurrentregion ...
    ROIcurrentroi;


switch (ROIcurrentfunc)
    case 'poly'
        if isempty(ROIcurrentobjs)  %If it is first click
            h=getslicehandles(relslice);
            for n=1:length(h)
                ud=get(h(n),'Userdata');
                p=get(h(n),'Parent');
                col=GetRegionColor(ROIcurrentregion);
                hl=line('XData', xy(1)*ud.scale(1)+ud.offset(1), ...
                    'YData', xy(2)*ud.scale(2)+ud.offset(2), ...
                    'Visible', 'on', ...
                    'Clipping', 'off', ...
                    'Color', [1 1 1], ...
                    'HitTest', 'off', ...
                    'LineStyle', '-', ...
                    'LineWidth', 1, ...
                    'Marker', 'o', ...
                    'color',col,...
                    'MarkerSize', 1, ...
                    'EraseMode', 'none', ...
                    'Parent', p, ...
                    'UserData',ud);
                ROIcurrentobjs=[ROIcurrentobjs; hl];
            end
            ROIcurrentslice=relslice;
            ROIcurrentroi=xy;
        else   % NOT the first click
            if ROIcurrentslice==relslice
                ROIcurrentobjs=ROIcurrentobjs(find(ishandle(ROIcurrentobjs)));
                switch type
                    case 'normal'
                        for n=1:length(ROIcurrentobjs)
                            ud=get(ROIcurrentobjs(n),'Userdata');
                            x=get(ROIcurrentobjs(n),'XData');
                            y=get(ROIcurrentobjs(n),'YData');
                            set(ROIcurrentobjs(n), 'XData',[x xy(1)*ud.scale(1)+ud.offset(1)], ...
                                'YData',[y xy(2)*ud.scale(2)+ud.offset(2)]);
                        end
                        ROIcurrentroi=[ROIcurrentroi; xy];

                    case 'extend'  %middle button
                        l=size(ROIcurrentroi,1);
                        if (l>1)
                            for n=1:length(ROIcurrentobjs)
                                x=get(ROIcurrentobjs(n),'XData');
                                y=get(ROIcurrentobjs(n),'YData');
                                set(ROIcurrentobjs(n),'XData',x(1:l-1), 'YData',y(1:l-1));
                            end
                            ROIcurrentroi=ROIcurrentroi(1:l-1,:);
                        else
                            delete(ROIcurrentobjs);
                            ROIcurrentobjs=[];
                            ROIcurrentroi=[];
                        end

                    case 'open'
                        switch lasttype
                            case 'normal'
                                delete(ROIcurrentobjs);
                                ROIcurrentobjs=[];
                                if length(ROIcurrentroi)>2
                                    StartNextUndo;
                                    AddRoi(ROIcurrentroi, ROIcurrentmode, ROIcurrentslice, ROIcurrentregion);
                                    %	          ROIcurrentregion=mod(ROIcurrentregion,3)+1;
                                end
                                ROIcurrentroi=[];
                            case 'extend'
                                delete(ROIcurrentobjs);
                                ROIcurrentobjs=[];
                                ROIcurrentroi=[];
                        end

                end
            end
        end

        %% ellipse function by kneth
    case 'ellipse'
        if (isempty(ROIcurrentobjs))         % If first click
            h=getslicehandles(relslice);
            for n=1:length(h)
                ud=get(h(n), 'Userdata');
                p=get(h(n), 'Parent');
                dphi=2*3.141592/100;   % 100 points
                phi=0.0;
                we=15.0;
                he=15.0;
                xarray=[];
                yarray=[];
                for i=1:100
                    tmp=we*he/sqrt(we*we*sin(phi)*sin(phi)+he*he*cos(phi)*cos(phi));
                    xarray(i)=(xy(1)+tmp*cos(phi));
                    yarray(i)=(xy(2)+tmp*sin(phi));
                    phi=phi+dphi;
                end
                ud.center=[xy(1) xy(2)];
                ud.height=he;
                ud.width=we;
                handle=line('XData', xarray, ...
                    'YData', yarray, ...
                    'Visible', 'off', ...
                    'Clipping', 'off', ...
                    'Color', [1 1 1], ...
                    'HitTest', 'off', ...
                    'LineStyle', '-', ...
                    'LineWidth', 1, ...
                    'Marker', '.', ...
                    'MarkerSize', 1, ...
                    'EraseMode', 'xor', ...
                    'Parent', p, ...
                    'UserData', ud);
                ROIcurrentobjs=[ROIcurrentobjs; handle];
            end
            ROIcurrentroi=[xarray' yarray'];
            ROIcurrentslice=relslice;
            AddRoi(ROIcurrentroi, ROIcurrentmode, ROIcurrentslice, ROIcurrentregion);
            ROIcurrentobjs=[];
            ROIcurrentroi=[];
        end

    case 'contour'
        switch type
            case 'normal'
                ud=get(gcbo,'Userdata');
                img=get(gcbo, 'CData');
                z=zeros(size(img)+2);
                z(2:end-1,2:end-1)=img;
                clear img;
                px=xy(1)/ud.siz(1)+ud.origin(1)+1;
                py=xy(2)/ud.siz(2)+ud.origin(2)+1;
                h=findobj('Tag','HoldContour');
                holdit=get(h,'Value');
                h=findobj('Tag','AutoContour');
                auto=get(h,'Value');
                he=findobj('Tag','EditContourLevel');
                if ~auto
                    if holdit
                        level=str2num(get(he,'String'));
                        [cx cy]=singlecontour(z, px, py, level);
                    else
                        [cx cy level]=singlecontour(z, px, py);
                        if ~isempty(cx)
                            set(he,'String',num2str(level));
                        end
                    end
                    if ~isempty(cx)
                        cx=(cx-ud.origin(1)-1)*ud.siz(1);
                        cy=(cy-ud.origin(2)-1)*ud.siz(2);
                        StartNextUndo;
                        AddRoi([cx' cy'], ROIcurrentmode, relslice, ROIcurrentregion);
                    end
                else
                    if holdit
                        level=str2num(get(he,'String'));
                    else
                        [dummy1 dummy2 level]=multicontour(z, px, py);
                        set(he,'String',num2str(level));
                    end
                    StartNextUndo;
                    a=get(gcbf,'UserData');
                    for sh=a.slicehandles(:)'
                        ud=get(sh,'UserData');
                        z(2:end-1,2:end-1)=get(sh,'CData');
                        [data mode]=multicontour(z, level);
                        if ~isempty(data)
                            for n=1:length(data)
                                cx=(data{n}(1,:)-ud.origin(1)-1)*ud.siz(1);
                                cy=(data{n}(2,:)-ud.origin(2)-1)*ud.siz(2);
                                roi=CompressRoi([cx' cy']);
                                %                roi=[cx' cy'];
                                if mode(n)
                                    %                   AddRoi([cx' cy'], 'InsideAdd', ud.relslice, ROIcurrentregion);
                                    AddRoi(roi, 'InsideAdd', ud.relslice, ROIcurrentregion);
                                else
                                    AddRoi(roi, 'InsideRemove', ud.relslice, ROIcurrentregion);
                                end
                            end
                        end
                    end
                end

            otherwise

        end

    otherwise

end


%*************************
function ClickMirror

global ROIcurrentobjs ...
    ROIcurrentpoints ...
    ROIcurrentslice ...
    ROImovefcn

% calculate x-y voxel position relative to origin in mm
ud=get(gcbo,'UserData');
p=get(gca,'CurrentPoint');
mmpos=(p(1,1:2)-ud.offset)./ud.scale;
z=ud.relslice;

if isempty(ROIcurrentobjs)
    % Start drawing mirror line

    ROImovefcn='mir';

    ROIcurrentobjs=line(p(1,1),p(1,2),'EraseMode','xor', ...
        'HitTest','off', ...
        'LineStyle','--', ...
        'Color', [1 1 1]);

    ROIcurrentpoints=mmpos;
    ROIcurrentslice=gcbo;
else
    % End drawing mirror line
    if (gcbo==ROIcurrentslice) && any(ROIcurrentpoints~=mmpos)
        mmpos=[ROIcurrentpoints; mmpos];
        ROImovefcn='';
        if ishandle(ROIcurrentobjs)
            delete(ROIcurrentobjs);
            id=GetSelectedIds;
            if ~isempty(id)
                StartNextUndo;
                PolygonMirror(id,mmpos);
            end
        end
        ROIcurrentobjs=[];
        ROIcurrentslice=[];
        ROIcurrentpoints=[];
    end
end


%***************************

function ClickRotate(mmpos)

global ROIcurrentobjs ...
    ROIcurrentcenter ...
    ROImovefcn

% calculate center x-y voxel position relative to origin in mm
id=GetSelectedIds;
if isempty(id)
    return;
end

%fig=GetMainFigure;
%Data=get(fig,'UserData');

%vertex=[];
%for n=id
%  i=find(Data.slicepolys.id==n);
%  vertex=[vertex; Data.slicepolys.vertex{i}];
%end
%k=convhull(vertex(:,1), vertex(:,2));
%center=mean(vertex(k,:));

%center=mean([max(vertex); min(vertex)]);

ROIcurrentobjs=findobj(gcf,'Tag','roipolygon','Selected','on');
if isempty(ROIcurrentobjs)
    return;
end

set(ROIcurrentobjs,'Selected','off', ...
    'EraseMode','xor', ...
    'Color', [1 1 1]);


ROIcurrentcenter=[mmpos pi/2];
ROImovefcn='rot';
set(gcbf,'WindowButtonUpFcn','editroi(''rotup'')');



%*************************
function id=AddRoi(roi,mode,relslice,region)

%
% Make sure that roi can be used in nuage.
%

% roi=UnCrossPoly(roi);  % No check here, done before calling nuages

%Close roi if first and last point differs
l=size(roi,1);
if any(roi(1,:) ~= roi(l,:))
    roi(l+1,:)=roi(1,:);
end


% Throw away if roi has less than 3 corners or if x or y coordinate is constant
if (length(roi)<=3) || all(roi(1,1)==roi(:,1)) || all(roi(1,2)==roi(:,2))
    return;
end


fig=GetMainFigure;
Data=get(fig,'UserData');


n=length(Data.slicepolys.id)+1;
id = Data.nextid;
Data.nextid=id+1;
Data.slicepolys.vertex{n,1}=roi;
Data.slicepolys.mode{n,1}=mode;
Data.slicepolys.id(n,1)=id;
Data.slicepolys.region(n,1)=region;
Data.slicepolys.relslice(n,1)=relslice;
Data.slicepolys.status{n,1}='';

set(fig,'UserData',Data);
PutPolyOnSlice(getslicehandles(relslice,region), roi, mode, id, region);

AddToUndoStack(id);

disp(sprintf('Added ROI %d', id));


%****************************
function PutPolyOnSlice(slicehandles, vertex, mode, id, region, ext)

global ROIeditmode ROIupdatemask


putline=1;

if nargin>5
    if strcmp(ext,'m')
        putline=0;
    end
end

[style marker]=GetLineStyle(mode);

if ROIeditmode
    hittest='on';
else
    hittest='off';
end

col=GetRegionColor(region);

ul.id=id;
ul.region=region;
for n=1:length(slicehandles)
    ul.slicehandle=slicehandles(n);
    ud=get(slicehandles(n),'Userdata');
    p=get(slicehandles(n),'Parent');
    if putline
        hl=line('XData', [vertex(:,1)'.*ud.scale(1)+ud.offset(1)], ...
            'YData', [vertex(:,2)'.*ud.scale(2)+ud.offset(2)], ...
            'Visible', 'on', ...
            'Clipping', 'off', ...
            'HitTest', hittest, ...
            'LineStyle', style, ...
            'LineWidth', 1, ...
            'Color', col, ...
            'Marker', marker, ...
            'MarkerSize', 1, ...   % modified by kneth: 8->1
            'Parent', p, ...
            'Tag', 'roipolygon', ...
            'ButtonDownFcn','editroi(''pdown'')', ...
            'erasemode','normal',...
            'UserData',ul);

        %            'EraseMode', 'xor', ...

    end

    if strcmp(ud.type, 'mask')
        ROIupdatemask=[ROIupdatemask; slicehandles(n)];
    end
end



%*************************
function RedrawMasks

global ROIupdatemask

slicehandles=ROIupdatemask(find(ishandle(ROIupdatemask)));
ROIupdatemask=[];
if isempty(slicehandles)
    return;
end

maskhandles=[];
slice=[];
region=[];
for n=1:length(slicehandles)
    ud=get(slicehandles(n),'UserData');
    if strcmp(ud.type,'mask')
        maskhandles=[maskhandles; slicehandles(n)];
        slice=[slice; ud.relslice];
        region=[region; ud.regions];
    end
end

if isempty(maskhandles)
    return;
end

[maskhandles i]=sort(maskhandles);
slice=slice(i);
region=region(i);

Data=get(GetMainFigure,'UserData');

last=0;
n=1;
while n<=length(maskhandles)
    h=maskhandles(n);
    if h~=last
        last=h;
        ud=get(maskhandles(n), 'UserData');
        img=get(maskhandles(n), 'CData');
        img=GetSliceMask(slice(n), region(n), size(img), ud.siz, ud.origin);
        set(h, 'CData', img);
    end
    n=n+1;
end


%*************************
function mask=GetSliceMask(relslice, region, dim, siz, origin)

mask=zeros([dim(1) dim(2)]);

Data=get(GetMainFigure,'UserData');

if isempty(Data.slicepolys.region)
    return;
end

i=find( (Data.slicepolys.relslice==relslice) & ...
    (Data.slicepolys.region==region) );

for x=1:length(i)  % do for all polygons
    if ~strcmp(Data.slicepolys.status{i(x)},'deleted')
        xi=Data.slicepolys.vertex{i(x)}(:,1)/siz(1)+origin(1); % 0.5 .. n+0.5
        yi=Data.slicepolys.vertex{i(x)}(:,2)/siz(2)+origin(2);

        % Changed, 201000, CS to use roipoly (standard way at NRU)
        %img=poly2bitmap(size(mask),xi,yi);
        if isempty(which('roipoly'))
            if x==1
                fprintf('Uses own 30 times slower implementation of roipoly\n');
            end
            [sx,sy]=size(mask);
            img=roipoly2(1:sy,1:sx,xi,yi);
        else
            img=roipoly(mask,xi,yi);
        end
        switch Data.slicepolys.mode{i(x)}
            case 'InsideAdd'
                mask=mask | img;
            case 'InsideRemove'
                mask=mask & not(img);
            case 'InsideXor'
                mask=xor(mask,img);
            case 'OutsideAdd'
                mask=mask | not(img);
            case 'OutsideRemove'
                mask=mask & img;
            case 'OutsideXor'
                mask=xor(mask,not(img));
            otherwise
                error('Unknown mode');
        end
    end
end


%*************************
function AddPolygons(slicehandles, relslice, regions, mode)

% regions is describing the regions for which polygons will be added ':'=all

if nargin==3
    mode='n';  % normal add
end

h=GetMainFigure;
Data=get(h,'UserData');

if ~isempty(Data.slicepolys.relslice)
    if strcmp(regions, ':')
        enable=ones(size(Data.slicepolys.region));
    else
        enable=zeros(size(Data.slicepolys.region));
        for n=1:length(regions)
            enable=enable | (Data.slicepolys.region==regions(n));
        end
    end

    idx=find(Data.slicepolys.relslice==relslice);

    for x=1:length(idx)
        if ~strcmp(Data.slicepolys.status{idx(x)},'deleted')
            if enable(idx(x))
                PutPolyOnSlice(slicehandles, ...
                    Data.slicepolys.vertex{idx(x)}, ...
                    Data.slicepolys.mode{idx(x)}, ...
                    Data.slicepolys.id(idx(x)), ...
                    Data.slicepolys.region(idx(x)), ...
                    mode);
            end
        end
    end
end


%*************************
function DeletePolygons(id)

DeletePolygonsNoUndo(id);
AddToUndoStack(id);

%************************
function DeletePolygonsNoUndo(id)

global ROIupdatemask

% delete all polygons with a specific id.
% id can be a row vector with multiple values

fig=GetMainFigure;
Data=get(fig,'UserData');

idx=[];
for n=1:length(id)
    if n>1
        if all(id(1:n-1)~=id(n))       % if this id hasn't been searched before
            idx=[idx find(Data.slicepolys.id==id(n))]; % search it
        end
    else
        idx=[idx find(Data.slicepolys.id==id(n))]; % search it
    end
end

if isempty(idx)
    return;
end

for x=idx
    Data.slicepolys.status{x}='deleted';
end

set(fig,'UserData',Data);

h=findobj('Tag', 'roipolygon');

if length(h)>1
    ul=get(h,'UserData');
else
    ul={get(h,'UserData')};
end

hl=[];
hs=[];
region=[];

for n=1:length(h)
    if any(id==ul{n}.id)
        hl=[hl; h(n)];
        hs=[hs; ul{n}.slicehandle];
    end
end

delete(hl);          % Delete lines

ROIupdatemask=[ROIupdatemask; hs];

%*************************

function UpdatePreviewLine

global ROIcurrentregion ...
    ROIcurrentmode


col=GetRegionColor(ROIcurrentregion);
[style, marker]=GetLineStyle(ROIcurrentmode);

h=findobj('Tag','previewline');
set(h,'Color',col, 'Marker',marker, 'LineStyle', style);


%*************************
function sh=getslicehandles(relslice, region)

%return handles to all images with specific slice and region

sh=[];
h=findobj('Tag','sliceimg');  %Find all slice images
a=get(h,'UserData');
if iscell(a)
    for n=1:length(a)
        if a{n}.relslice==relslice
            sh=[sh; h(n)];
        end
    end
else
    if ~isempty(a)
        if a.relslice==relslice
            sh=h;
        end
    end
end

% now test for region
i=[];
if nargin>=2
    if ~ischar(region)
        for n=1:length(sh)
            ud=get(sh(n),'UserData');
            if ischar(ud.regions)
                i=[i; n];
            else
                if any(ud.regions==region)
                    i=[i; n];
                end
            end
        end
        sh=sh(i);
    end
end

%*************************
function id=GetSelectedIds

%return row vector with id for all polygons which have been selected

id=[];
h=findobj('Selected','on');       %Find all selected objects
h=findobj(h,'Tag','roipolygon');  %Find all polygons

for n=1:length(h)
    ld=get(h(n),'UserData');
    if isempty(id)
        id=ld.id;
    elseif all(ld.id~=id)
        id=[id ld.id];
    end
end

%*******************************************
function roi=GetPolygonRoi(polygonhandle)

% return the roi coordinates in mm for the selected polygon

ld=get(polygonhandle,'UserData');
x=get(polygonhandle,'XData');
y=get(polygonhandle,'YData');
ud=get(ld.slicehandle,'UserData');
%roi(:,1)=(x'-ud.offset(1))*ud.scale(1);
%roi(:,2)=(y'-ud.offset(2))*ud.scale(2);
roi(:,1)=(x'-ud.offset(1))/ud.scale(1);
roi(:,2)=(y'-ud.offset(2))/ud.scale(2);


%*******************************************

function col=GetRegionColor(region)

Data=get(GetMainFigure, 'UserData');
if isstruct(Data)
    if region>size(Data.regioncolor,1)
        s=size(Data.regioncolor,1);
        dummy=load('roidefaultcolors');
        roidefaultcolors=dummy.roidefaultcolors;
        for n=s+1:region
            Data.regioncolor(n,:)=roidefaultcolors(1+mod(n-1,size(roidefaultcolors,1)),:);
        end
        set(GetMainFigure, 'UserData', Data);
    end
    col=Data.regioncolor(region,:);
else
    dummy=load('roidefaultcolors');
    roidefaultcolors=dummy.roidefaultcolors;
    col=roidefaultcolors(1+mod(region-1,size(roidefaultcolors,1)),:);
end


%*******************************************

function name=GetRegionName(region)

Data=get(GetMainFigure, 'UserData');

if (region<=length(Data.regionname)) && (region>0)
    name=Data.regionname{region};
else
    name='';
end


%*************************

function [style, marker]=GetLineStyle(mode)

switch mode
    case 'InsideAdd'
        marker='x';
        style='-';
    case 'InsideRemove'
        marker='x';
        style='--';
    case 'InsideXor'
        marker='x';
        style='-.';
    case 'OutsideAdd'
        marker='o';
        style='-';
    case 'OutsideRemove'
        marker='o';
        style='--';
    case 'OutsideXor'
        marker='o';
        style='-.';
    otherwise
        marker='none';
        style=':';
end

%*************************
function newroi=CompressRoi(roi)

% roi must be an [n,2] array containing x- and y- coordinates

dx=diff(roi(:,1));
dy=diff(roi(:,2));

warning('off');
a=dx./dy;
warning('on');


i=[];

for n=1:length(a)-1
    if ~isnan(a(n))
        if (a(n)~=a(n+1))    % if it is a corner
            i=[i n+1];
        end
    end
end
i=[1 i length(a)+1];
newroi=roi(i',:);



%*******************************************
%*******************************************
%*******************************************

function MakePolygonChange(polygonhandle, xdata, ydata);

% polygonhandle is a handle to a single polygon
% xdata and ydata is coordinates stored in the 'XDAta' and 'YDATA' properties

ld=get(polygonhandle, 'UserData');
ud=get(ld.slicehandle,'UserData');
x=(xdata-ud.offset(1))/ud.scale(1);
y=(ydata-ud.offset(2))/ud.scale(2);
fig=GetMainFigure;
Data=get(fig,'UserData');
i=find(Data.slicepolys.id==ld.id);
mode=Data.slicepolys.mode{i};
relslice=Data.slicepolys.relslice(i);
DeletePolygons(ld.id);
AddRoi([x' y'],mode,relslice,ld.region);

% move new roi to layer-position next to deleted polygon
fig=GetMainFigure;
Data=get(fig, 'UserData');
p1=find(Data.slicepolys.id==ld.id);

c=struct2cell(Data.slicepolys);
f=fieldnames(Data.slicepolys);
for n=1:length(c)
    newroi=c{n}(end);
    c{n}=[c{n}(1:p1); newroi; c{n}(p1+1:end-1)];
end
Data.slicepolys=cell2struct(c,f,1);
set(fig,'UserData',Data);

%*******************************************

function PolygonMirror(id,mirrorpos)

% mirrors polygons in line with absolute coordinates in mirrorpos
% id can be a row vector with multiple values
% If polygons were deleted they will appear undeleted in new region
% mirrorpos = [x1 y1; x2 y2] in mm-coordinates

fig=GetMainFigure;
Data=get(fig,'UserData');

id=sort(id(:));

idx=[];
for n=1:length(id)
    if n>1
        if id(n-1)~=id(n)       % if this id hasn't been searched before
            i=find(Data.slicepolys.id==id(n)); % search it
            idx=[idx i];
        end
    else
        i=find(Data.slicepolys.id==id(n)); % search it
        idx=[idx i];
    end
end

newvertex=cell(length(idx),1);

%calculate mirror angle

p=mirrorpos(2,:)-mirrorpos(1,:);
if p(1)~=0
    vm=atan(p(2)/p(1));
else
    if p(2)>0
        vm=0.5*pi;
    else
        vm=1.5*pi;
    end
end

newregions=[];

for n=1:length(idx)
    v=Data.slicepolys.vertex{idx(n)};  % Get vertex for one polygon
    reg=Data.slicepolys.region(idx(n));
    if isempty(newregions)
        newregions=reg;
    elseif newregions~=reg
        newregions=[newregions; reg];
    end
    for c=1:size(v,1)
        p=v(c,:)-mirrorpos(1,:);
        if p(1)~=0
            v1=atan(p(2)/p(1));
        else
            if p(2)>0
                v1=0.5*pi;
            else
                v1=1.5*pi;
            end
        end
        if p(1)<0
            v1=v1+pi;
        end
        v2=2*vm-v1;   % angle for new point
        len=sqrt((p(1)^2) + (p(2)^2));
        p2=[cos(v2)*len sin(v2)*len] + mirrorpos(1,:);
        newvertex{n,1}=[newvertex{n,1}; p2];
    end
end

newregions=sort(newregions);

for n=1:size(newregions,1)
    name=['M: ' Data.regionname{newregions(n,1),1}];
    newregions(n,2)=AddNewRegion(name);
end


for n=1:length(idx)
    region=Data.slicepolys.region(idx(n));
    nr=newregions(find(newregions(:,1)==region),2);
    AddRoi(newvertex{n,1},Data.slicepolys.mode{idx(n)},Data.slicepolys.relslice(idx(n)),nr);
end


%*******************************************

function CopyPolygonToSlice(id,newslice)

% Copies polygons with selected id to a new slice (x and y pos remain the same)
% id can be a row vector with multiple values
% If polygons were deleted they will appear undeleted in new slice

fig=GetMainFigure;
Data=get(fig,'UserData');

id=sort(id(:));

% find index for each id
idx=[];
for n=1:length(id)
    if n>1
        if id(n-1)~=id(n)       % if this id hasn't been searched before
            i=find(Data.slicepolys.id==id(n)); % search it
            %      if (Data.slicepolys.relslice(i)~=newslice)
            idx=[idx i];
            %      end
        end
    else
        i=find(Data.slicepolys.id==id(n)); % search it
        %    if (Data.slicepolys.relslice(i)~=newslice)
        idx=[idx i];
        %    end
    end
end

for x=idx
    nid=AddRoi(Data.slicepolys.vertex{x}, ...
        Data.slicepolys.mode{x}, ...
        newslice, ...
        Data.slicepolys.region(x));
end

%*******************************************

function CopyPolygonToRegion(id,newregion)

% Copies polygons with selected id to a new region
% id can be a row vector with multiple values
% If polygons were deleted they will appear undeleted in new region

fig=GetMainFigure;
Data=get(fig,'UserData');

id=sort(id(:));

idx=[];
for n=1:length(id)
    if n>1
        if id(n-1)~=id(n)       % if this id hasn't been searched before
            i=find(Data.slicepolys.id==id(n)); % search it
            if (Data.slicepolys.region(i)~=newregion) | ...
                    strcmp(Data.slicepolys.status{i},'deleted')
                idx=[idx i];
            end
        end
    else
        i=find(Data.slicepolys.id==id(n)); % search it
        if (Data.slicepolys.region(i)~=newregion) | ...
                strcmp(Data.slicepolys.status{i},'deleted')
            idx=[idx i];
        end
    end
end

for x=idx
    nid=AddRoi(Data.slicepolys.vertex{x}, ...
        Data.slicepolys.mode{x}, ...
        Data.slicepolys.relslice(x), ...
        newregion);
end


%*******************************************

function ChangePolygonDrawmode(id,newdrawmode)

% Deletes polygons with selected id and makes new roi's with new draw-mode.
% id can be a row vector with multiple values
% Deleted rois can't change drawmode

fig=GetMainFigure;
Data=get(fig,'UserData');

id=sort(id(:));

idx=[];
for n=1:length(id)
    if n>1
        if id(n-1)~=id(n)       % if this id hasn't been searched before
            i=find(Data.slicepolys.id==id(n)); % search it
            if ~strcmp(Data.slicepolys.mode{i},newdrawmode) & ...
                    ~strcmp(Data.slicepolys.status{i},'deleted')
                idx=[idx i];
            end
        end
    else
        i=find(Data.slicepolys.id==id(n)); % search it
        if ~strcmp(Data.slicepolys.mode{i},newdrawmode) & ...
                ~strcmp(Data.slicepolys.status{i},'deleted')
            idx=[idx i];
        end
    end
end

DeletePolygons(Data.slicepolys.id(idx)');

for x=idx
    nid=AddRoi(Data.slicepolys.vertex{x}, ...
        newdrawmode, ...
        Data.slicepolys.relslice(x), ...
        Data.slicepolys.region(x));
end


%*******************************************
%** SAVE AND LOAD FUNCTIONS ****************
%*******************************************
function SaveInTextFile(filename, regions)

fig=GetMainFigure;
a=get(fig,'UserData');

k=find(~strcmp(a.slicepolys.status,'deleted'));

i=[];
for n=k(:)'
    if any(a.slicepolys.region(n)==regions)
        i=[i n];
    end
end

if ~isempty(i)
    vertex     = a.slicepolys.vertex(i,1);
    mode       = a.slicepolys.mode(i,1);
    region     = a.slicepolys.region(i);
    z          = a.slicepolys.relslice(i,1)*a.slicedist;
    regionname = a.regionname;

    % sort polygons by region
    [region idx]=sort(region);
    vertex=vertex(idx);
    mode=mode(idx);
    z=z(idx);

    fid=fopen(filename,'w');
    if fid>0
        lastregion=-Inf;
        for n=1:length(region)
            if region(n)~=lastregion
                lastregion=region(n);
                fprintf(fid, '\nregionname\t%s\r\n',regionname{region(n)});
            end
            fprintf(fid,'x');
            for x=1:size(vertex{n},1)
                fprintf(fid,'\t%.7e',vertex{n}(x,1));
            end
            fprintf(fid,'\r\ny');
            for x=1:size(vertex{n},1)
                fprintf(fid,'\t%.7e',vertex{n}(x,2));
            end
            fprintf(fid,'\r\nz\t%.7e\r\nmode\t%s\r\n',z(n),mode{n});
        end

        fclose(fid);
    else
        warndlg('File did not open!');
    end
else
    warndlg('Nothing to save!');
end

%*****************************

function SaveInMatlabFile(newfilename)

fig=GetMainFigure;
a=get(fig,'UserData');

i=find(~strcmp(a.slicepolys.status,'deleted'));

vertex     = a.slicepolys.vertex(i,1);
mode       = a.slicepolys.mode(i,1);
region     = a.slicepolys.region(i,1);
relslice   = a.slicepolys.relslice(i,1);
regionname = a.regionname;
slicedist  = a.slicedist;

if isempty(a.filename) | newfilename
    [name path]=uiputfile('*.mat','Save roi as...');
    if ~ischar(name)
        return;
    end
    a.filename=fullfile(path,name);
    set(fig,'UserData',a,'Name',name);
end

filetype='EditRoiFile';
v=version;
if v(1)>'6'
  save(a.filename,'filetype', ...
    'vertex', ...
    'mode', ...
    'region', ...
    'relslice', ...
    'regionname', ...
    'slicedist','-V6');
else
  save(a.filename,'filetype', ...
    'vertex', ...
    'mode', ...
    'region', ...
    'relslice', ...
    'regionname', ...
    'slicedist');
end


%*********************
function LoadMatlabFile

global ROIcurrentregion

fig=GetMainFigure;
a=get(fig,'UserData');

[name path]=uigetfile('*.mat','Load roi...');
if ~ischar(name)
    return;
end
filename=fullfile(path,name);

gData=get(GetMainFigure,'UserData');
[S, message] = LoadRoi(filename,gData);
if isempty(S)
    warndlg(message)
    return
end
% $$$ if ~isfield(S,'filetype') | ~isfield(S,'vertex')
% $$$   warndlg('File contains no regions!','Load error');
% $$$   return;
% $$$ end
% $$$
% $$$ if ~strcmp(S.filetype,'EditRoiFile')
% $$$   warndlg('File contains no regions!','Load error');
% $$$   return;
% $$$ end
% $$$
% $$$
% $$$ if isempty(a.slicedist)
% $$$   a.slicedist=S.slicedist;
% $$$   set(fig,'UserData',Data);
% $$$ else

%
% cmm 05072000
%
% Because the way regions is added changed, it was also nessersarye
% to change the way files are loaded.
%
if not(isempty(S.region))
    StartNextUndo
    for i=1:length(S.regionname)
        region = AddNewRegion(S.regionname{i});
        for j=1:length(S.region)
            if S.region(j) == i
                AddRoi(S.vertex{j},S.mode{j},S.relslice(j),region);
            end
        end
    end
end
RedrawMasks;

set(fig,'Name',name);


%***************************
function SaveMask(rollhandle, regions, filename, mode)

% regions can specify one or more regions to apply in mask

ud=get(rollhandle,'UserData');

mask=zeros(ud.dim(1),ud.dim(2),ud.dim(3));

for z=1:ud.dim(3)
    for r=regions(:)'
        mask(:,:,z)=mask(:,:,z) | GetSliceMask(z-ud.origin(3), r, [ud.dim(2) ud.dim(1)], ud.siz, ud.origin)';
    end
    switch mode
        case 1  % Zeros and ones -- do nothing

        case 2  % Zeros and image inside
            mask(:,:,z)=mask(:,:,z).*get(ud.slicehandles(z),'CData')';
        case 3  % Zeros and image outside
            mask(:,:,z)=not(mask(:,:,z)).*get(ud.slicehandles(z),'CData')';
    end
end

if mode>1
    ma=max(mask(:));
    mi=min(mask(:));
    scale=(ma-mi)/255
    offset=-mi/scale;
    mask=round(mask/scale+offset);
else
    Scale=1;
    offset=0;
end
WriteAnalyzeImg(filename,mask,ud.dim,ud.siz,8,[255 0],scale,offset,ud.origin);



%***************************
function ClearAllRegions

global ROIcurrentregion ROIupdatemask

fig=GetMainFigure;
Data=get(fig,'UserData');

DeletePolygonsNoUndo(Data.slicepolys.id);

Data.slicepolys.vertex={};   % vertex data for each slice
Data.slicepolys.mode={};     % text string describing mode
Data.slicepolys.id=[];       % the id of each polygon
Data.slicepolys.region=[];   % the region of each polygon
Data.slicepolys.relslice=[]; % Which slice the polygon applies to
Data.slicepolys.status={};   % text string describing status ('','deleted')
Data.regioncolor=colorcube(9);
Data.regionname={'Region 1'}; % cmm
% Data.regionname={}; %
Data.undostack={};           % stack containing id's to undo/redo
Data.undopointer=0;          % the number of undos to make
Data.nextid=1;          % the id for next roi to add

set(fig,'UserData',Data);

h=findobj('Tag','sliceimg');
for a=h'
    ud=get(a,'UserData');
    if strcmp(ud.type, 'mask')
        ROIupdatemask=[ROIupdatemask; a];
    end
end

RedrawMasks;


ROIcurrentregion=1;

UpdatePreviewLine;


delete(findobj(fig,'Tag','mnuRegion'));

h1 = uimenu('Parent',gcf, ...
    'Label','&Region', ...
    'Tag','mnuRegion');
uimenu('Parent',h1, ...
    'Label',sprintf('&1: %s',Data.regionname{1}), ...
    'Callback','editroi(''selectregion'',1)', ...
    'Checked','on', ...
    'ForegroundColor', GetRegionColor(1), ...
    'UserData',1, ...
    'Tag','mnuRegionItem');
uimenu('Parent',h1, ...
    'Label','&New...', ...
    'Callback','editroi(''newregion'')', ...
    'Separator','on', ...
    'Tag','mnuNewRegion');
uimenu('Parent',h1, ...
    'Label','&Rename...', ...
    'Callback','editroi(''renregion'')', ...
    'Tag','mnuRenRegion');
uimenu('Parent',h1, ...
    'Label','&Color...', ...
    'Callback','editroi(''regioncol'')', ...
    'Tag','mnuRegionCol');

%  UpdateRegionMenus;

h=findobj(fig,'Tag','popRegion');
set(h,'Value',1,'String','Region 1');



%*******************************************
%*******************************************
%*******************************************

%***************************
function axeshandle=NewRollFigure(fname)

hdr=ReadAnalyzeHdr(fname);
pre=hdr.pre;
dim=hdr.dim;
siz=hdr.siz;
lim=hdr.lim;
scale=hdr.scale;
offset=hdr.offset;
origin=hdr.origin;

if all(origin==0)
    origin=origin+1;
end

Data=get(GetMainFigure,'UserData');
if isempty(Data.slicedist)
    Data.slicedist=siz(3);
    set(GetMainFigure,'UserData',Data);
else
    if abs((siz(3)-Data.slicedist)/siz(3)) > 1e-5   % allow for uncertainty in format (single precision)
        a=questdlg({'The image you want to load has not' ...
            ' the same distance between slices' ...
            '  as the images currently loaded!' ...
            '         Load anyway?'}, ...
            'Load warning','Yes','No','No');
        if strcmp(a,'No')
            return;
        end
    end
end

ud = get(GetMainFigure,'userdata');
ud.dim = dim;
ud.origin = origin;
ud.siz = siz;
set(GetMainFigure,'userdata',ud);
dim4=0;

if length(dim)>3
    a=inputdlg(sprintf('Enter time frame (1..%d):',dim(4)),'Loading 4-D image',1,{'1'});
    if isempty(a)
        return;
    end
    dim4=str2num(a{1});
    if isempty(dim4)
        dim4=1;
    end
    if (dim4>dim(4)) | (dim4<1)
        dim4=1;
    end
    [img,hdr]=ReadAnalyzeImg(fname,sprintf(':%d',dim4));
    if scale~=0
        img=(img-offset)*scale;
    end
else
    img=ReadAnalyzeImg(fname);
    if scale~=0
        img=(img-offset)*scale;
    end
end

ma=max(img(:));
mi=min(img(:));

dim=dim';
clear('a');
a.dim=dim;
a.origin=origin;
a.siz=siz;
a.aspect=siz(2)*dim(2)/(siz(1)*dim(1));
a.min=mi;
a.max=ma;
a.filename = fname;
a.sidewindow = [];

img=reshape(img, dim(1:3));
img=img(:,:,:,end);

[d1, name, d2]=fileparts(fname);

if dim4>0
    name=sprintf('%s - Time fr. %d/%d', name, dim4, dim(4));
end


% h0 = figure('Units','normalized', ...
%     'ColorMap',gray(64), ...
%     'MenuBar','none', ...
%     'Position',[0.5 0.2 0.33 0.9], ...
%     'Name',name, ...
%     'Tag', 'zoom', ...
%     'WindowButtonMotionFcn','editroi(''rm'')',...
%     'numbertitle','off');
screensize=get(0,'ScreenSize');
h0 = figure('Units','pixels', ...
    'ColorMap',gray(64), ...
    'MenuBar','none', ...
    'Position',[screensize(3)-1160 screensize(4)/2-270 700 700], ...
    'Name',name, ...
    'Tag', 'zoom', ...
    'WindowButtonMotionFcn','editroi(''rm'')',...
    'numbertitle','off');

%set(h0,'ResizeFcn',strcat('editroi(''resizeroll'',',num2str(h0),')'))

cm=MakeRollContextMenu(h0);
set(h0,'Units','pixels');
pos=get(h0,'Position');
rpos=[20 38 pos(3)-45 pos(4)-45];
axeshandle=axes('Parent',h0, ...
    'Units','pixels', ...
    'Position',rpos, ...
    'Color',[0 0 0]);

set(axeshandle,'Units','centimeters');
p=get(axeshandle,'Position');
a.ycount=(p(4)/p(3))/a.aspect;
a.imgheigth=siz(3);
a.axes=axeshandle;
a.slicehandles=[];
a.ylen=dim(3)*siz(3);           % Total length of y-axes (including all images)
a.ymin=(0.5-origin(3))*siz(3);  % Lowest point on y-axes to display
a.sidewindow = [];
y=1;

figure(h0);
hold on;

y=1/dim(2);
for n=1:dim(3);
    relslice=n-origin(3);
    ypos=[relslice-0.5+y/2 relslice+0.5-y/2]*siz(3);

    if (any([mi ma]))
        h=imagesc([1 dim(1)], ypos, img(:,:,n)',[mi ma]);
    else
        h=imagesc([1 dim(1)], ypos, img(:,:,n)');
    end
    %  ttt=text(-5,n,sprintf('z=%d',(n-origin(3))*siz(3)));
    %  set(ttt,'Rotation',90);
    %            'Position', [-10,n,0], ...
    %   get(ttt)
    %
    ud.relslice=relslice;
    ud.offset=[origin(1) (relslice-0.5+y*(origin(2)-0.5))*siz(3)];
    ud.scale=[1/siz(1) 1/(siz(2)*dim(2)/siz(3))];
    ud.type='image';
    ud.siz=siz;
    ud.origin=origin;
    ud.regions=':';
    a.slicehandles(1,n)=h;


    % Axes coordinates in image = [x(mm) y(mm)]*ud.scale + ud.offset

    set(h,'ButtonDownFcn','editroi(''rdown'')', ...
        'UserData',ud, ...
        'Tag','sliceimg', ...
        'UIContextMenu',cm);

    AddPolygons(h, ud.relslice,ud.regions)
end
hold off;
set(axeshandle,'YLim',([0.5 a.ycount+0.5]-origin(3))*siz(3), ...
    'XLim',[0.5 dim(1)+0.5], ...
    'YTick',([1:dim(3)]-origin(3))*siz(3), ...
    'XTick',[], ...
    'Tag', 'roll');
%
% cmm, Inds?tter selv akser.
%
set(axeshandle,'visible','off')

%'BackgroundColor',[0.701961 0.701961 0.701961], ...

if (a.ycount > dim(3))
    SlStp=[0 1];
else
    SlStp=[1/(dim(3)-a.ycount) a.ycount/(dim(3)-a.ycount)];
    if any(SlStp>1)
        SlStp=[0 1];
    end
end

h=findobj('Tag','Slider1');
if isempty(h)
    SlStartVal=0;
else
    SlStartVal=get(h(1),'Value');
end

h = uicontrol('Parent',h0, ...
    'Units','pixels', ...
    'Callback','editroi(''rslider'')', ...
    'Interruptible','off', ...
    'Position',[pos(3)-20 38 20 pos(4)-45], ...
    'SliderStep',SlStp, ...
    'Style','slider', ...
    'Tag','Slider1', ...
    'Value',SlStartVal);

a.yaxis = [];
a.showtallarich = 1;

set(h0,'UserData',a);

set(h0,'ResizeFcn',strcat('editroi(''resizeroll'',',num2str(h0),')'))

figure(h0);

a=get(h0,'UserData');
y=SlStartVal*(a.ylen-a.ycount*a.imgheigth);
set(findobj(h0,'Tag','roll'),'YLim',[y y+a.ycount*a.imgheigth]+a.ymin);

%h=supercolorbar('horiz','nomove');
load('ShowImageColMap.txt');
colormap(ShowImageColMap);
h=colorbar('south');
set(h,'Units','pixels',...
    'Position',[20 18 pos(3)-50 15]);
set(h,'ButtonDownFcn','ColormapMenu');

set(axeshandle,'Position',p);         

disp('');
disp('Use slider to scroll up/down in z-direction.');
disp('Double-click on colorbar with left mouse button to change colormap.');
disp('Double-click or drag colorbar with right mouse button to set limits.');
disp('Right-click on image to bring up menu.');
disp('');

%****************************
function NewZoomFigure(img, cmap, clim, name, aspect, relslice, siz, origin)

fig = figure('Name',name, ...
    'NumberTitle', 'off', ...
    'MenuBar','none', ...
    'Tag', 'roizoom', ...
    'WindowButtonMotionFcn','editroi(''zm'')',...
    'visible','off');

cm=MakeZoomContextMenu(fig);

a.aspect=aspect;
a.relslice=relslice;
a.siz=siz;
a.origin=origin;
a.z=relslice*siz(3);

ax=axes('Position',[0 0 1 1]);

p=get(gcf,'Position');
faspect=(p(4)/p(3));
if faspect>aspect
    p(4)=p(3)*aspect;
    set(gcf,'Position',p);
else
    p(3)=p(4)/aspect;
    set(gcf,'Position',p);
end
h=imagesc([1 size(img,2)], [1 size(img,1)], img, clim);

ud.relslice=relslice;
ud.offset=[origin(1) origin(2)];
ud.scale=[1/siz(1) 1/siz(2)];
ud.type='image';
ud.siz=siz;
ud.origin=origin;
ud.regions=':';

a.slicehandles=h;
a.axes=ax;

% Axes coordinates in image = [x(mm) y(mm)]*ud.scale + ud.offset

set(h,'ButtonDownFcn','editroi(''zdown'')', ...
    'Tag','sliceimg', ...
    'UserData',ud, ...
    'UIContextMenu',cm);

set(ax, 'YDir','normal', 'Color',[0 0 0]);
colormap(cmap);

set(fig,'UserData',a, ...
    'Units','normalized');

AddPolygons(h, relslice, ':');

set(fig,'visible','on',...
        'ResizeFcn','editroi(''resizezoom'')');


%****************************
function NewMaskFigure(dim, name, aspect, relslice, siz, origin, region)

cmap=[0.25 0.25 0.5; ...
    0.134 0.422 1.000];


fig = figure('ColorMap',cmap, ...
    'Name',name, ...
    'NumberTitle', 'off', ...
    'MenuBar','none', ...
    'Tag', 'roimask', ...
    'WindowButtonMotionFcn','editroi(''zm'')',...
    'visible','off');

cm=MakeZoomContextMenu(fig);

a.aspect=aspect;
a.relslice=relslice;
a.siz=siz;
a.origin=origin;
a.z=relslice*siz(3);

ax=axes('Position',[0 0 1 1]);
p=get(gcf,'Position');
faspect=(p(4)/p(3));
if faspect>aspect
    p(4)=p(3)*aspect;
    set(gcf,'Position',p);
else
    p(3)=p(4)/aspect;
    set(gcf,'Position',p);
end
mask=zeros(dim);
h=imagesc([1 dim(2)], [1 dim(1)], mask, [0 1]);

ud.relslice=relslice;
ud.offset=[origin(1) origin(2)];
ud.scale=[1/siz(1) 1/siz(2)];
ud.type='mask';
ud.siz=siz;
ud.origin=origin;
ud.regions=region;

a.slicehandles=h;
a.axes=ax;

% Axes coordinates in image = [x(mm) y(mm)]*ud.scale + ud.offset

set(h,'ButtonDownFcn','editroi(''zdown'')', ...
    'Tag','sliceimg', ...
    'UserData',ud, ...
    'UIContextMenu',cm);

set(ax, 'YDir','normal', 'Color',[0 0 0]);
set(fig,'UserData',a);

AddPolygons(h, relslice, region);

set(fig,'visible','on',...
        'ResizeFcn','editroi(''resizezoom'')');


%****************************
function MakeCutFigure(rollhandle)

global ROIlastrollimg

p=get(gca,'CurrentPoint');

%[x,y]=ginput(1)
ud=get(ROIlastrollimg,'UserData');
mmpos=(p(1,1:2)-ud.offset)./ud.scale;
cutpos=round(mmpos./ud.siz(1:2)'+ud.origin(1:2)');

Data=get(GetMainFigure,'UserData');

%** Find regions with undeleted polygons

i=find(~strcmp(Data.slicepolys.status,'deleted'));
if length(i)>0
    regions=Data.slicepolys.region(i(1));
    for x=Data.slicepolys.region(i(2:end))'
        if regions~=x
            regions=[regions x];
        end
    end
else
    regions=[];
end

fd=get(gcf,'UserData');
clim=get(fd.axes,'CLim');
cmap=get(rollhandle,'ColorMap');
xlen=fd.dim(1)*fd.siz(1);
ylen=fd.dim(2)*fd.siz(2);
zlen=fd.dim(3)*fd.siz(3);

imgxz=zeros(fd.dim(3),fd.dim(1));
imgyz=zeros(fd.dim(3),fd.dim(2));

for z=1:fd.dim(3)
    img=get(fd.slicehandles(z),'CData');
    imgxz(z,:)=img(cutpos(2),:);
    imgyz(z,:)=img(:,cutpos(1))';
end

%** Now make Y-cut figure

ud.offset=[fd.origin(1) fd.origin(3)];
ud.scale=[1/fd.siz(1) 1/fd.siz(3)];
ud.y=(cutpos(2)-fd.origin(2))*fd.siz(2);
ud.cut='y';
ud.dim=[fd.dim(1) fd.dim(3)];
ud.siz=fd.siz;
ud.origin=fd.origin;
ud.hor_line_origin=[fd.origin(1) fd.origin(2)-cutpos(2)+1];

fig = figure('Name',sprintf('Cut: Y=%d mm',ud.y), ...
    'Units','centimeters', ...
    'NumberTitle', 'off', ...
    'MenuBar','none', ...
    'Tag', 'roicut', ...
    'WindowButtonMotionFcn','editroi(''ym'')');
cm=MakeZoomContextMenu(fig);
uimenu('Parent',cm,...
    'Label','Update all cut images', ...
    'CallBack','editroi(''updateallcut'')',...
    'Visible','off');

p=get(gcf,'Position');
p(3)=xlen/20;
p(4)=zlen/20;
set(gcf,'Position',p);

a.aspect=zlen/xlen;
a.axes=axes('Position',[0 0 1 1]);
a.slicehandles=imagesc([1 size(imgxz,2)], [1 size(imgxz,1)], imgxz, clim);

set(a.axes, 'YDir','normal', 'Color',[0 0 0]);
colormap(cmap);
set(fig,'UserData',a, ...
    'Units','normalized');
set(a.slicehandles,'UserData',ud, ...
    'UIContextMenu',cm);
UpdateCutFigure(fig);
set(fig,'Visible','on',...
        'ResizeFcn','editroi(''resizezoom'')');

%** Now make X-cut figure

ud.offset=[fd.origin(2) fd.origin(3)];
ud.scale=[1/fd.siz(2) 1/fd.siz(3)];
ud.x=(cutpos(1)-fd.origin(1))*fd.siz(1);
ud.cut='x';
ud.dim=[fd.dim(2) fd.dim(3)];
ud.siz=fd.siz;
ud.origin=fd.origin;
ud.hor_line_origin=[fd.origin(1)-cutpos(1)+1 fd.origin(2)];

fig = figure('Name',sprintf('Cut: X=%d mm',ud.x), ...
    'Units','centimeters', ...
    'NumberTitle', 'off', ...
    'MenuBar','none', ...
    'Tag', 'roicut', ...
    'WindowButtonMotionFcn','editroi(''xm'')',...
    'Visible','off');
cm=MakeZoomContextMenu(fig);
uimenu('Parent',cm,...
    'Label','Update all cut images', ...
    'CallBack','editroi(''updateallcut'')');

p=get(gcf,'Position');
p(3)=ylen/20;
p(4)=zlen/20;
set(gcf,'Position',p);

a.aspect=zlen/ylen;
a.axes=axes('Position',[0 0 1 1]);
a.slicehandles=imagesc([1 size(imgyz,2)], [1 size(imgyz,1)], imgyz, clim);
set(a.axes, 'YDir','normal', 'Color',[0 0 0]);
colormap(cmap);
set(fig,'UserData',a, ...
    'Units','normalized');
set(a.slicehandles,'UserData',ud, ...
    'UIContextMenu',cm);

UpdateCutFigure(fig);
set(fig,'Visible','on',...
        'ResizeFcn','editroi(''resizezoom'')');

%********************************
function UpdateCutFigure(fig)

delete(findobj(fig,'Tag','roicutpolygon'));

Data=get(GetMainFigure,'UserData');

%** Find regions with polygons to show
i=find(~strcmp(Data.slicepolys.status,'deleted'));
if length(i)>0
    regions=Data.slicepolys.region(i(1));
    for x=Data.slicepolys.region(i(2:end))'
        if regions~=x
            regions=[regions x];
        end
    end
else
    regions=[];
end

for n=1:length(fig)
    a=get(fig(n),'UserData');
    ud=get(a.slicehandles,'UserData');

    % Now add contours to image

    if strcmp(ud.cut,'x')
        maskline=[ud.dim(1) 1];   % size of mask from each layer = [n,1]  (x,y)
    else
        maskline=[1 ud.dim(1)];   % size of mask from each layer = [1,n]  (x,y)
    end
    axes(a.axes);
    hold on;
    for region=regions
        mask=zeros(ud.dim(2)+2,ud.dim(1)+2);
        for z=1:ud.dim(2)
            mask(z+1,2:end-1)=reshape(GetSliceMask(z-ud.origin(3), region, ...
                maskline, ud.siz, ...
                ud.hor_line_origin),1,ud.dim(1));
        end
        [cc,hc]=contour([0:ud.dim(1)+1], [0:ud.dim(2)+1], mask,[0.55 0.55],'r');
        set(hc,'Color',GetRegionColor(region), ...
            'Tag', 'roicutpolygon');
    end
end



%********************************
%*** CALCULATION FUNCTIONS ******
%********************************

function MakeRegionSummary(rollaxes)

Data=get(GetMainFigure, 'UserData');
rcount=size(Data.regionname,1);
h=findobj(rollaxes,'Tag','sliceimg');
savedata.data=[];
for region=1:rcount
    masscent=[0 0 0];
    values=[];
    for n=1:length(h)
        ud=get(h(n),'UserData');
        img=get(h(n),'CData');
        idx=find(GetSliceMask(ud.relslice, region, ...
            size(img), ud.siz, ud.origin));
        values=[values; img(idx)];
        if ~isempty(idx)
            [y x]=ind2sub(size(img), idx);
            xy=[x-ud.origin(1) y-ud.origin(2)];
            clear x y;
            masscent=masscent+sum([xy repmat(ud.relslice,size(xy,1),1)]);
        end
    end
    count=length(values);
    if count>0
        masscent=(masscent/count).*ud.siz';   % [x y z] center of mass in mm
        tot=sum(values);
        ma=max(values);
        mi=min(values);
        mn=tot/count;
        vol=prod(ud.siz./10)*count;
        d=std(values);
        dm=d*count/tot;
    else
        tot=0;
        ma=NaN;
        mi=NaN;
        mn=NaN;
        vol=0;
        d=NaN;
        dm=NaN;
    end
    savedata.data=[savedata.data ...
        [count; vol; tot; mn; mi; ma; d; dm; ...
        masscent(1); masscent(2); masscent(3);]];
end

p=get(rollaxes,'Parent');
name=sprintf('Region Summary for ''%s''', get(p,'Name'));

% Generate data for save-menu function
savedata.top=[{''} Data.regionname'];
savedata.left={'No. of voxels'; ...
    'ccm (ml)'; ...
    'Sum'; ...
    'Mean'; ...
    'min'; ...
    'max'; ...
    'Std.dev'; ...
    'Norm std.dev.'; ...
    'Center of mass, x';...
    'Center of mass, y';...
    'Center of mass, z'...
    };



%************
data=savedata;

for roffset=1:4:size(data.data,2)
    if roffset==1
        str=sprintf('               Region:');
    else
        str=[str sprintf('               Region:')];
    end
    for x=roffset:min([roffset+3 size(data.top,2)-1])
        str=[str sprintf('%16s',data.top{x+1})];
    end
    str=[str sprintf('\r\n\n')];

    a=size(data.left);

    l=0;
    for y=1:size(data.data,1)
        for x=1:size(data.left,2)
            str=[str sprintf('%22s',data.left{y,x})];
        end
        for x=roffset:min([roffset+3 size(data.data,2)])
            s=sprintf('%6g',data.data(y,x));
            str=[str sprintf('%16s',s)];
        end
        str=[str sprintf('\r\n')];
        l=l+1;
        if l==4
            l=0;
            str=[str sprintf('\n')];
        end
    end
    str=[str sprintf('\r\n\n')];
end

fig=figure('Name',name, ...
    'MenuBar','none', ...
    'NumberTitle','off', ...
    'Units','pixels');
% 'Position',[209 100 860 600]);
uicontrol('Parent',fig, ...
    'Units','normalized', ...
    'BackgroundColor',[0.7 0.7 0.7], ...
    'FontName','courier', ...
    'FontUnits','pixels', ...
    'FontSize',16, ...
    'FontWeight','normal', ...
    'HorizontalAlignment','left', ...
    'ListboxTop',0, ...
    'Position',[0 0 1 1], ...
    'String',textwrap({str},Inf), ...
    'Style','text', ...
    'ListboxTop', 1, ...
    'Tag','StaticText1');

%  'Style','listbox', ...

set(fig,'MenuBar','none');
set(fig,'UserData',savedata);

h1 = uimenu('Parent',fig, ...
    'Label','&File');
uimenu('Parent',h1, ...
    'Label','&Save', ...
    'Callback','editroi(''saveplot'')');

%********************

function MakeHistogram_old(slicehandles, limits, name)


Data=get(GetMainFigure, 'UserData');
rcount=max(Data.slicepolys.region);
count=zeros(rcount,length(limits)-1);
tot=zeros(rcount,1);
%tothist=zeros(1,length(limits)-1);  % Histogram for whole image
%totcount=0;

hw=waitbar(0,'Calculating histogram');
for i=1:length(slicehandles)
    ud=get(slicehandles(i),'UserData');
    img=get(slicehandles(i),'CData');

    for region=1:rcount
        idx=find(GetSliceMask(ud.relslice, region, ...
            size(img), ud.siz, ud.origin));
        values=img(idx);
        tot(region,1)=tot(region,1)+length(idx);
        for x=1:length(limits)-1
            if x==1
                count(region,x)=count(region,x)+length(find((values>=limits(x)) & (values<=limits(x+1))));
            else
                count(region,x)=count(region,x)+length(find((values>limits(x)) & (values<=limits(x+1))));
            end
        end
    end
    waitbar(i/length(slicehandles));
end

delete(hw);

for n=1:length(limits)-1
    x(n)=(limits(n)+limits(n+1))/2;
end

h0=figure('Name','Histogram');
AddPlotMenu(h0);

ah=axes;
set(ah,'Color',[0.7 0.7 0.7], ...
    'XGrid','on', ...
    'YGrid','on');
xlabel('Voxel value');
title(name,'Interpreter','none');

hl=[];

i=find(tot(:,1)>0);
if ~isempty(i)
    for region=i'
        count(region,:)=count(region,:)*100/tot(region,1);
        h=line(x,count(region,:), ...
            'Color',GetRegionColor(region), ...
            'Marker','.');
        hl=[hl h];
    end

    legend(hl, char(Data.regionname(i)));

    % Generate data for save-menu function
    savedata.top=[{'> (1: >=)' '<='} Data.regionname(i)'];
    savedata.left={};
    savedata.data=[limits(1:end-1)' limits(2:end)' count(i,:)'];
    set(h0,'UserData',savedata);
else
    h=findobj('Tag','mnuSavePlot');
    set(h,'Enable','off');
end

%*************************
%********************

function MakeHistogram(slicehandles, limits, bins, name)

%bins=length(limits)-1
%limits=[min(limits) max(limits)];

Data=get(GetMainFigure, 'UserData');
rcount=max(Data.slicepolys.region);
count=zeros(rcount,bins);
tot=zeros(rcount,1);
%tothist=zeros(1,bins);  % Histogram for whole image
%totcount=0;

hw=waitbar(0,'Calculating histogram');
for i=1:length(slicehandles)
    ud=get(slicehandles(i),'UserData');
    img=get(slicehandles(i),'CData');

    for region=1:rcount
        values=img(find(double(GetSliceMask(ud.relslice, region, ...
            size(img), ud.siz, ud.origin))));
        if ~isempty(values)
            tot(region,1)=tot(region,1)+length(values);
            bin_no=ceil((values-limits(1))*bins/(limits(2)-limits(1)));
            bin_no(find(bin_no<=0))=1;
            for x=bin_no(:)'
                count(region,x)=count(region,x)+1;
            end
        end
    end
    waitbar(i/length(slicehandles));
end

delete(hw);

xdist=range(limits)/bins;
x=[1:bins]*xdist-xdist/2+limits(1);

h0=figure('Name','Histogram');
AddPlotMenu(h0);

ah=axes;
set(ah,'Color',[0.7 0.7 0.7], ...
    'XGrid','on', ...
    'YGrid','on');
xlabel('Voxel value');
title(name,'Interpreter','none');

hl=[];

limdata=[0:bins]*xdist+limits(1);

i=find(tot(:,1)>0);
if ~isempty(i)
    for region=i'
        count(region,:)=count(region,:)*100/tot(region,1);
        h=line(x,count(region,:), ...
            'Color',GetRegionColor(region), ...
            'Marker','.');
        hl=[hl h];
    end

    legend(hl, char(Data.regionname(i)));

    % Generate data for save-menu function
    savedata.top=[{'> (1: >=)' '<='} Data.regionname(i)'];
    savedata.left={};
    savedata.data=[limdata(1:end-1)' limdata(2:end)' count(i,:)'];
    set(h0,'UserData',savedata);
else
    h=findobj('Tag','mnuSavePlot');
    set(h,'Enable','off');
end

%*************************


function Plot4DFile(fname)

hdr=ReadAnalyzeHdr(fname);
pre=hdr.pre;
dim=hdr.dim;
siz=hdr.siz;
lim=hdr.lim;
scale=hdr.scale;
offset=hdr.offset;
origin=hdr.origin;

if all(origin==0)
    origin=origin+1;
end
f=fopen([fname '.tim'],'r');
if f>0
    time=fscanf(f,'%f %f',[2 Inf])';
    fclose(f);
else
    time=[1:dim(4)]';
end

Data=get(GetMainFigure,'UserData');
regioncount=size(Data.regionname,1);

vsum=zeros(regioncount, dim(4));  % sum of voxel values
count=zeros(regioncount);  % no. of voxels

wb=waitbar(0,'Loading and calculating...');
t=1;
for z=1:dim(3)
    relslice=(z-origin(3));
    for region=1:regioncount
        waitbar(t/(dim(3)*regioncount));
        [img,hdr]=ReadAnalyzeImg(fname,sprintf('%d:',z));
        img=reshape(img,dim(1),dim(2),dim(4));
        img_dim=size(img);
        mask=flipud(GetSliceMask(relslice, region, [img_dim(2) img_dim(1)], siz, origin));
        mask_ind=find(mask);
        count(region)=count(region)+length(mask_ind);
        for n=1:dim(4)
            img2=img(:,:,n);
            img2=flipud(img2');
            vsum(region,n)=vsum(region,n)+sum(img2(mask_ind));
        end
        t=t+1;
    end
end

delete(wb);

% calculate means
for n=1:dim(4)
    for region=1:regioncount
        if count(region)>0
            vsum(region,n)=(vsum(region,n)/count(region)-offset)*scale;
        else
            vsum(region,n)=0;
        end
    end
end

h0 = figure('Name','4D Mean Plot');
AddPlotMenu(h0);

ah=axes;
set(ah,'Color',[0.7 0.7 0.7], ...
    'XGrid','on', ...
    'YGrid','on');
xlabel('Time');
ylabel('Mean value');
title(fname,'Interpreter','none');

hl=[];
tt=[];
for m=1:regioncount
    for n=1:dim(4)
        h=line(time(n,1)', vsum(m,n),...
            'Color',GetRegionColor(m), ...
            'Marker','.');
        tt=[tt m];
    end
    hl=[hl h];
    %
    legend(hl, Data.regionname{unique(tt)});
    % Generate data for save-menu function
    savedata.top=[{'Time'} Data.regionname(unique(tt))'];
    savedata.left={};
    savedata.data=[time(:,1) vsum([unique(tt)],:)']; %indsat af btd 060100
    set(h0,'UserData',savedata);
    %
    % So legend text (regionnames) is not changed by latex interpreter
    %
    h=findobj('type','text');
    set(h,'interpreter','none');
end



%*************************

function saveplot(fighandle, filename)

data=get(fighandle,'UserData');
if isempty(data)
    uiwait(warndlg('Nothing to save!'));
    return;
end

f=fopen(filename,'w');
if f<=0
    return;
end

for x=1:size(data.top,2)
    if x>1
        fprintf(f,'\t');
    end
    fprintf(f,data.top{x});
end
fprintf(f,'\r\n');

a=size(data.left);

for y=1:size(data.data,1)
    for x=1:size(data.left,2)
        fprintf(f,'%s\t',data.left{y,x});
    end
    for x=1:size(data.data,2)
        if x>1
            fprintf(f,'\t');
        end
        fprintf(f,'%7e',data.data(y,x));
    end
    fprintf(f,'\r\n');
end
fclose(f);

type(filename);
txt=sprintf('Data saved in %s ',filename);
disp(txt)
%*************************
function AddPlotMenu(fig)

set(fig,'MenuBar','none');

h1 = uimenu('Parent',fig, ...
    'Label','&File');
uimenu('Parent',h1, ...
    'Label','&Save', ...
    'Callback','editroi(''saveplot'')', ...
    'Tag','mnuSavePlot');
h1 = uimenu('Parent',fig, ...
    'Label','&Axes');
uimenu('Parent',h1, ...
    'Label','L&ogarithmic', ...
    'Callback','set(gca,''XScale'',''log'')');
uimenu('Parent',h1, ...
    'Label','L&inear', ...
    'Callback','set(gca,''XScale'',''linear'')');


%*************************
%*** UNDO FUNCTIONS ******
%*************************
function AddToUndoStack(polygonid)

if isempty(polygonid)
    return;
end
fig=GetMainFigure;
Data=get(fig, 'UserData');
p=Data.undopointer;
Data.undostack{p}=[Data.undostack{p} polygonid];
set(fig, 'UserData', Data);

%*******
function StartNextUndo

% Must be called before starting adding deleting polygons

fig=GetMainFigure;
Data=get(fig, 'UserData');
p=Data.undopointer;
if p<length(Data.undostack)
    Data.undostack=Data.undostack(1:p);
    h=[findobj(fig,'Tag','mnuRedo'); findobj(fig,'Tag','butRedo')];
    set(h,'Enable','off');              % disable 'redo' menu
end
if p==0
    h=[findobj(fig,'Tag','mnuUndo'); findobj(fig,'Tag','butUndo')];
    set(h,'Enable','on');               % enable 'undo' menu
else
    if p<=length(Data.undostack)
        if isempty(Data.undostack{p})
            return;
        end
    end
end
Data.undopointer=p+1;
Data.undostack{p+1}=[];
set(fig, 'UserData', Data);

%*******
function Undo(redo)

fig=GetMainFigure;
Data=get(fig, 'UserData');
p=Data.undopointer;
if redo
    if (p>=length(Data.undostack))
        return;
    end
    Data.undopointer=p+1;
    p=p+1;
    if p==length(Data.undostack)
        h=[findobj(fig,'Tag','mnuRedo'); findobj(fig,'Tag','butRedo')];
        set(h,'Enable','off');               % disable 'redo' menu
    end
    if p>=0
        h=[findobj(fig,'Tag','mnuUndo'); findobj(fig,'Tag','butUndo')];
        set(h,'Enable','on');               % enable 'undo' menu
    end
else
    if p<1
        return;
    end
    Data.undopointer=p-1;
    h=[findobj(fig,'Tag','mnuRedo'); findobj(fig,'Tag','butRedo')];
    set(h,'Enable','on');               % enable 'redo' menu
    if p==1
        h=[findobj(fig,'Tag','mnuUndo'); findobj(fig,'Tag','butUndo')];
        set(h,'Enable','off');               % disable 'undo' menu
    end
end

% p is now pointing to stack-entry to invert
set(fig, 'UserData', Data);

Data=get(fig, 'UserData');
i=zeros(length(Data.undostack{p}),1);

for n=1:length(Data.undostack{p})
    i(n)=find(Data.slicepolys.id==Data.undostack{p}(n));
end

x=strcmp([Data.slicepolys.status(i)],'deleted');
id=i(find(x));      % index to deleted polygons
i=i(find(not(x)));  % index to not deleted polygons

if ~isempty(id)
    disp('Undo is undeleting');
    [Data.slicepolys.status{id}]=deal('');
    set(fig, 'UserData', Data);
    for n=1:length(id)
        h=getslicehandles(Data.slicepolys.relslice(id(n)),Data.slicepolys.region(id(n)));
        PutPolyOnSlice(h, Data.slicepolys.vertex{id(n)}, ...
            Data.slicepolys.mode{id(n)}, ...
            Data.slicepolys.id(id(n)), ...
            Data.slicepolys.region(id(n)));
    end
end

if ~isempty(i)
    disp('Undo is deleting');
    DeletePolygonsNoUndo(Data.slicepolys.id(i));
end





%***********************
%**** REGIONS **********
%***********************

function region=InputNewRegion

h=findobj(gcbf, 'Tag', 'mnuRegionItem');
p=get(h(1), 'Parent');
region=length(h)+1;
name=sprintf('Region %d',region);
name=inputdlg(sprintf('Enter name for region %d:', region), ...
    'New Region', 1, {name});
if ~isempty(name)
    % AddNewRegion(name{1});
    region=AddNewRegion(name{1});
else
    region=0;
end

%***********************
function retregion=AddNewRegion(name, col)  % color is optional
%
% Rewritten by Claus M?ller Madsen 02072000. The orignal version is
% in comments below
%
global ROIcurrentregion
fig=GetMainFigure;
Data=get(fig,'UserData');

% Check if there inserted points
ok = 0;
%
% If slicepolys is empty. Overwrite the first region
%
if (length(Data.slicepolys.region)==0)
    ok = 1;
    region = 1;
else
    %
    % Chech if there is an empty region
    %
    for i=1:length(Data.regionname)
        if (sum(Data.slicepolys.region==i)==0)
            region = i;
            ok = 1;
            break
        end
    end;
end;


if ok == 0
    %
    % No empty region. Insert last
    %
    region=size(Data.regionname,1)+1;
end;


%
% Make sure that too regions does not have the same name
%
newname = name;
n=1;
while any(strcmp(Data.regionname,newname))
    newname=sprintf('%s (%d)',name,n);
    n=n+1;
end
if nargin<2
    col=GetRegionColor(region);
end
if ok == 0
    Data.regionname{region,1}=newname;
else
    if strcmp(name,Data.regionname{region,1})
    else
        Data.regionname{region,1}=newname;
    end;
end



%
% Update the regions menu and popupmenu
%
set(fig, 'UserData',Data);
h=findobj(fig,'Tag','popRegion');
if length(Data.regionname) == 1
    ROIcurrentregion = region;
    set(h,'value',region,'String',newname);
else
    s = Data.regionname{1};
    for i=2:length(Data.regionname)
        s = [s '|' Data.regionname{i}];
    end
    set(h,'String',s,'value',region);
end;

h=findobj(fig, 'Tag', 'mnuRegion');
delete(h);

h1 = uimenu('Parent',GetMainFigure, ...
    'Label','&Region', ...
    'Tag','mnuRegion');

for i=1:length(Data.regionname)
    uimenu('Parent',h1, ...
        'Label',sprintf('&%d: %s',i,Data.regionname{i}), ...
        'Callback',strcat('editroi(''selectregion'',',num2str(i),')'),...
        'Checked','on', ...
        'ForegroundColor', GetRegionColor(i), ...
        'UserData',i, ...
        'Tag','mnuRegionItem');
end;
uimenu('Parent',h1, ...
    'Label','&New...', ...
    'Callback','editroi(''newregion'')', ...
    'Separator','on', ...
    'Tag','mnuNewRegion');
uimenu('Parent',h1, ...
    'Label','&Rename...', ...
    'Callback','editroi(''renregion'')', ...
    'Tag','mnuRenRegion');
uimenu('Parent',h1, ...
    'Label','&Color...', ...
    'Callback','editroi(''regioncol'')', ...
    'Tag','mnuRegionCol');

retregion = region;
set(fig,'UserData',Data);



% $$$
% $$$ function region=AddNewRegion(name, col)  % color is optional
% $$$
% $$$ fig=GetMainFigure;
% $$$ Data=get(fig,'UserData');
% $$$ region=size(Data.regionname,1)+1;
% $$$
% $$$ if nargin<2
% $$$   col=GetRegionColor(region);
% $$$   Data=get(fig,'UserData');    % Read UserData again
% $$$ end
% $$$
% $$$ % Check if another region has the same name
% $$$ newname=name;
% $$$ n=1;
% $$$ while any(strcmp(Data.regionname,newname))
% $$$   newname=sprintf('%s (%d)',name,n);
% $$$   n=n+1;
% $$$ end
% $$$
% $$$ Data.regioncolor(region,:)=col;
% $$$ Data.regionname{region,1}=newname;
% $$$ set(fig, 'UserData',Data);
% $$$ h=findobj(fig,'Tag','popRegion');
% $$$ set(h,'String',Data.regionname);
% $$$
% $$$ h=findobj(fig, 'Tag', 'mnuRegionItem');
% $$$ p=get(h(1), 'Parent');
% $$$ h2 = uimenu('Parent',p, ...
% $$$       'Label',sprintf('&%d: %s',region,newname), ...
% $$$       'Callback',sprintf('editroi(''selectregion'',%d)',region), ...
% $$$       'UserData',region, ...
% $$$       'ForegroundColor', col, ...
% $$$       'Tag','mnuRegionItem');
% $$$
% $$$ %      'Checked','on', ...
% $$$
% $$$
% $$$ c=get(p,'Children');
% $$$ c=[c(2:4); c(1); c(5:end)];
% $$$ set(p,'Children',c);
% $$$

%***********************
function RenameRegion(region)

fig=GetMainFigure;
Data=get(fig,'UserData');

h=findobj(gcbf, 'Tag', 'mnuRegionItem');
h=findobj(h, 'UserData', region);
if isempty(h)
    return;
end
region
name=Data.regionname{region}
name=inputdlg(sprintf('Enter name for region %d:', region), ...
    'Rename Region', 1, {name});
if ~isempty(name)
    set(h, 'Label', sprintf('&%d: %s', region, name{1}));
    Data.regionname{region}=name{1};
    set(fig, 'UserData',Data);
    h=findobj(fig,'Tag','popRegion');
    set(h,'String',Data.regionname);
end


%***********************
function EditRegionColor(region)

h=findobj(gcbf, 'Tag', 'mnuRegionItem');
h=findobj(h, 'UserData', region);
if isempty(h)
    return;
end

col=GetRegionColor(region);

col=uisetcolor(col, sprintf('Set color for region %d', region));
if length(col)==3
    Data=get(GetMainFigure, 'UserData');
    Data.regioncolor(region,:)=col;
    set(GetMainFigure, 'UserData', Data);
    set(h, 'ForegroundColor', col);
    h=findobj('Tag','roipolygon');
    h=findobj(h,'EraseMode','normal');
    if length(h)>1
        ld=get(h,'UserData');
    else
        ld={get(h,'UserData')};
    end
    for n=1:length(h);
        if ld{n}.region==region
            set(h(n),'Color',col);
        end
    end
end

%***********************
function UpdateRegionMenus
%
% May only be used when regions are cleared
%

fig=GetMainFigure;
Data=get(fig,'UserData');

h=findobj(fig,'Tag','popRegion');
set(h,'String',Data.regionname);

h=findobj(fig,'Tag','mnuRegionItem');
p=findobj(fig,'Tag','mnuRegion');
c = get(p,'Children');
region = 1;
h2 = uimenu('Parent',p, ...
    'Label',sprintf('&%d: %s',region,Data.regionname{region}), ...
    'Callback',sprintf('editroi(''selectregion'',%d)',region), ...
    'UserData',region, ...
    'ForegroundColor', GetRegionColor(region), ...
    'Tag','mnuRegionItem');

get(p,'children');
set(h2,'Checked','on');
delete(h);
set(p,'Children',[h2 c(3) c(2) c(1)]);


%***********************
function cm = MakeRollContextMenu(fig)

cm=uicontextmenu('Tag','RollContext', ...
    'Parent',fig);
uimenu('Parent',cm,...
    'Label','View slice in new window', ...
    'CallBack','editroi(''newzoom'')');
uimenu('Parent',cm,...
    'Label','View mask', ...
    'CallBack','editroi(''newmask'')');
uimenu('Parent',cm,...
    'Label','View cut', ...
    'CallBack','editroi(''newcut'')');
uimenu('Parent',cm,...
    'Label','Region summary', ...
    'Separator','on', ...
    'CallBack','editroi(''calculateroll'')');
uimenu('Parent',cm,...
    'Label','Region histogram', ...
    'CallBack','editroi(''rollhisto'')');
uimenu('Parent',cm, ...
    'Label','Save image', ...
    'Callback','editroi(''savemask'')', ...
    'Tag','mnuSavemask');
uimenu('Parent',cm, ...
    'Label','Show voxel', ...
    'Separator','on', ...
    'Callback','editroi(''showvoxel'')', ...
    'Tag','mnuShowtallarich');  
uimenu('Parent',cm, ...
    'Label','Show Tallarich', ...
    'Callback','editroi(''showtallarich'')', ...
    'Tag','mnuShowvoxel');
uimenu('Parent',cm, ...
    'Label','Show Sagital View', ...
    'Callback','editroi(''showsideview'')', ...
    'Tag','mnuShowSideview');


%***********************
function cm = MakeZoomContextMenu(fig)

cm=uicontextmenu('Tag','ZoomContext', ...
    'Parent',fig);
b=uimenu('Parent',cm,...
    'Label','Print/save image', ...
    'CallBack','printeasy(gcbf)');

%******************************
function h0=GetMainFigure

global ROImainfig

h0=ROImainfig;
%h0=findobj('Tag','editroi');

%******************************

function SetHelpText(str)

h=findobj(GetMainFigure,'Tag','HelpText');
set(h,'String',str);

%******************************


function h0=MakeMainFigure(userdata)

if ~isempty(findobj('Tag','editroi'))
    h0=[];
    return;
end

un=get(0,'Units');
set(0,'Units','pixels');
screensize=get(0,'ScreenSize');
set(0,'Units',un);

bgcolor=[0.445 0.667 0.582];

h0 = figure('Color', bgcolor, ...
    'MenuBar','none', ...
    'NumberTitle','off', ...
    'Units','pixels',...
    'Position',[screensize(3)-450 screensize(4)/2-110 360 220], ...
    'Resize','off', ...
    'Tag','editroi', ...
    'UserData', userdata,...
    'name','editroi');
%'Color',[0.8 0.8 0.8], ...

h1 = uimenu('Parent',h0, ...
    'Label','&File', ...
    'Tag','&File1');
uimenu('Parent',h1, ...
    'Callback','editroi(''loadimg'')', ...
    'Label','&Load images...', ...
    'Tag','mnuLoadimage');
uimenu('Parent',h1, ...
    'Label','Load &Regions...', ...
    'Callback','editroi(''load'')', ...
    'Tag','mnuLoadregions');
uimenu('Parent',h1, ...
    'Label','&Save regions', ...
    'Callback','editroi(''save'')', ...
    'Separator','on', ...
    'Tag','&File&Save1');
uimenu('Parent',h1, ...
    'Label','Save regions &As...', ...
    'Callback','editroi(''saveas'')', ...
    'Tag','&FileSave &As1');
uimenu('Parent',h1, ...
    'Label','&Export regions...', ...
    'Callback','editroi(''exporttxt'')', ...
    'Tag','mnuExport');
uimenu('Parent',h1, ...
    'Label','&Clear all', ...
    'Callback','editroi(''clearall'')', ...
    'Separator','on', ...
    'Tag','mnuClearall');

h1 = uimenu('Parent',h0, ...
    'Label','&Edit', ...
    'Tag','&Edit1');
uimenu('Parent',h1, ...
    'Label','&Undo', ...
    'Enable','off', ...
    'Callback','editroi(''undo'')', ...
    'Tag','mnuUndo');
uimenu('Parent',h1, ...
    'Label','&Redo', ...
    'Callback','editroi(''redo'')', ...
    'Enable','off', ...
    'Tag','mnuRedo');
uimenu('Parent',h1, ...
    'Label','&Delete', ...
    'Callback','editroi(''delete'')', ...
    'Tag','mnuDelete');
uimenu('Parent',h1, ...
    'Label','&Select all', ...
    'Callback','editroi(''selectall'')', ...
    'Separator','on', ...
    'Tag','mnuSelectall');
uimenu('Parent',h1, ...
    'Label','Select &Region', ...
    'Callback','editroi(''selectallregion'')', ...
    'Tag','mnuSelectregion');
uimenu('Parent',h1, ...
    'Label','C&hange region', ...
    'Callback','editroi(''changeregion'')', ...
    'Separator','on', ...
    'Tag','mnuChangeregion');
uimenu('Parent',h1, ...
    'Callback','editroi(''changemode'')', ...
    'Label','Change draw&mode', ...
    'Tag','mnuChangemode');

h1 = uimenu('Parent',h0, ...
    'Label','&Draw', ...
    'Tag','&Draw1');
uimenu('Parent',h1, ...
    'Callback','editroi(''draw'',''poly'')', ...
    'Label','&Polygon', ...
    'Tag','mnuPoly');
uimenu('Parent',h1, ...
    'Callback','editroi(''draw'',''ellipse'')', ...
    'Label','&Ellipse', ...
    'Tag','mnuEllipse');
uimenu('Parent',h1, ...
    'Callback','editroi(''draw'',''contour'')', ...
    'Label','&Contour', ...
    'UserData','contour', ...
    'Tag','mnuContour');

%
% cmm, 20052000
%
uimenu('Parent',h1, ...
    'Label','C&ombine Region...', ...
    'Callback','editroi(''combineRegion'')', ...
    'Tag','mnuCombindeRegion');

uimenu('Parent',h1, ...
    'Label','&Select/Move', ...
    'Callback','editroi(''movenodes'')', ...
    'Separator','on', ...
    'Tag','mnumove');
uimenu('Parent',h1, ...
    'Label','Edit &Nodes', ...
    'Callback','editroi(''editnodes'')', ...
    'Tag','mnueditnodes');
uimenu('Parent',h1, ...
    'Label','R&otate', ...
    'Callback','editroi(''rotate'')', ...
    'Tag','mnurotate');
uimenu('Parent',h1, ...
    'Label','&Resize', ...
    'Callback','editroi(''resizenodes'')', ...
    'Tag','mnuresize');
uimenu('Parent',h1, ...
    'Label','Cop&y', ...
    'Callback','editroi(''copy'')', ...
    'Tag','mnucopy');
uimenu('Parent',h1, ...
    'Label','&Mirror', ...
    'Callback','editroi(''mirror'')', ...
    'Tag','mnumiror');

%h1 = uimenu('Parent',h0, ...
%	'Label','&Mode', ...
%	'Tag','&Mode1');
%  h2 = uimenu('Parent',h1, ...
%	  'Label','&Add', ...
%	  'Callback','editroi(''drawmode'')', ...
%	  'Checked','on', ...
%	  'UserData','Add', ...
%	  'Tag','addmnu');
%  h2 = uimenu('Parent',h1, ...
%	  'Label','&Remove', ...
%	  'Callback','editroi(''drawmode'')', ...
%	  'UserData','Remove', ...
%	  'Tag','addmnu');
%  h2 = uimenu('Parent',h1, ...
%	  'Label','&Xor', ...
%	  'Callback','editroi(''drawmode'')', ...
%	  'UserData','Xor', ...
%	  'Tag','addmnu');
%  h2 = uimenu('Parent',h1, ...
%	  'Label','&Inside', ...
%	  'Callback','editroi(''drawmode'')', ...
%	  'Checked','on', ...
%	  'UserData','Inside', ...
%	  'Separator','on', ...
%	  'Tag','inoutmnu');
%  h2 = uimenu('Parent',h1, ...
%	  'Label','&Outside', ...
%	  'Callback','editroi(''drawmode'')', ...
%	  'UserData','Outside', ...
%	  'Tag','inoutmnu');


h1 = uimenu('Parent',h0, ...
    'Label','&Options', ...
    'Tag','&Options1');
uimenu('Parent',h1, ...
    'Callback','editroi(''histogramset'')', ...
    'Label','&Histogram settings...', ...
    'Tag','mnuHistoset');

h1 = uimenu('Parent',h0, ...
    'Label','&4-D', ...
    'Tag','mnu4D');
uimenu('Parent',h1, ...
    'Callback','editroi(''timestudy'')', ...
    'Label','Mean in regions...', ...
    'Separator','on', ...
    'Tag','mnuTimestudy');

uimenu('Parent',h1, ...
    'Callback','editroi(''multiframe'')', ...
    'Label','Multi frame...', ...
    'Separator','on', ...
    'Tag','mnuMultiFramestudy');

h1 = uimenu('Parent',h0, ...
    'Label','&Region', ...
    'Tag','mnuRegion');
uimenu('Parent',h1, ...
    'Label',sprintf('&1: %s',userdata.regionname{1}), ...
    'Callback','editroi(''selectregion'',1)', ...
    'Checked','on', ...
    'ForegroundColor', GetRegionColor(1), ...
    'UserData',1, ...
    'Tag','mnuRegionItem');
uimenu('Parent',h1, ...
    'Label','&New...', ...
    'Callback','editroi(''newregion'')', ...
    'Separator','on', ...
    'Tag','mnuNewRegion');
uimenu('Parent',h1, ...
    'Label','&Rename...', ...
    'Callback','editroi(''renregion'')', ...
    'Tag','mnuRenRegion');
uimenu('Parent',h1, ...
    'Label','&Color...', ...
    'Callback','editroi(''regioncol'')', ...
    'Tag','mnuRegionCol');


uicontrol('Parent',h0, ...
    'Units','pixels', ...
    'BackgroundColor',[0.701960784313725 0.701960784313725 0.701960784313725], ...
    'FontUnits','pixels', ...
    'FontSize',14, ...
    'FontWeight','normal', ...
    'HorizontalAlignment','left', ...
    'ListboxTop',0, ...
    'Position',[0 0 360 25], ...
    'String','', ...
    'Style','text', ...
    'Tag','HelpText');

uicontrol('Parent',h0, ...
    'Units','pixels', ...
    'BackgroundColor', bgcolor, ...
    'HorizontalAlignment','right', ...
    'ListboxTop',0, ...
    'Position',[10 51 75 12]  , ...
    'String','Contour level:', ...
    'Style','text', ...
    'Tag','StaticText2');

uicontrol('Parent',h0, ...
    'Units','pixels', ...
    'BackgroundColor',[1 1 1], ...
    'HorizontalAlignment','left', ...
    'ListboxTop',0, ...
    'Position',[90 48, 80 19], ...
    'String','', ...
    'Style','edit', ...
    'Tag','EditContourLevel');

uicontrol('Parent',h0, ...
    'Units','pixels', ...
    'BackgroundColor',[0.8 0.8 0.8], ...
    'HorizontalAlignment','center', ...
    'ListboxTop',0, ...
    'Position',[175 49 40 18], ...
    'String','Lock', ...
    'Style','togglebutton', ...
    'Tag','HoldContour', ...
    'Value',0);

uicontrol('Parent',h0, ...
    'Units','pixels', ...
    'BackgroundColor',[0.8 0.8 0.8], ...
    'HorizontalAlignment','center', ...
    'ListboxTop',0, ...
    'Position',[217 49 40 18], ...
    'String','Auto', ...
    'Style','togglebutton', ...
    'Tag','AutoContour', ...
    'Value',0);

uicontrol('Parent',h0, ...
    'Units','pixels', ...
    'BackgroundColor',[0.8 0.8 0.8], ...
    'Position',[1 25 360 17], ...
    'Style','frame');


uicontrol('Parent',h0, ...
    'Units','pixels', ...
    'BackgroundColor',[0.8 0.8 0.8], ...
    'HorizontalAlignment','left', ...
    'ListboxTop',0, ...
    'Position',[5 28 15 12], ...
    'String','x:', ...
    'Style','text');

uicontrol('Parent',h0, ...
    'Units','pixels', ...
    'BackgroundColor',[0.8 0.8 0.8], ...
    'HorizontalAlignment','left', ...
    'ListboxTop',0, ...
    'Position',[20 28 40 12], ...
    'String','', ...
    'Style','text', ...
    'Tag','xpos');

uicontrol('Parent',h0, ...
    'Units','pixels', ...
    'BackgroundColor',[0.8 0.8 0.8], ...
    'HorizontalAlignment','left', ...
    'ListboxTop',0, ...
    'Position',[60 28 15 12], ...
    'String','y:', ...
    'Style','text');

uicontrol('Parent',h0, ...
    'Units','pixels', ...
    'BackgroundColor',[0.8 0.8 0.8], ...
    'HorizontalAlignment','left', ...
    'ListboxTop',0, ...
    'Position',[75 28 40 12], ...
    'String','', ...
    'Style','text', ...
    'Tag','ypos');

uicontrol('Parent',h0, ...
    'Units','pixels', ...
    'BackgroundColor',[0.8 0.8 0.8], ...
    'HorizontalAlignment','left', ...
    'ListboxTop',0, ...
    'Position',[115 28 15 12], ...
    'String','z:', ...
    'Style','text');

uicontrol('Parent',h0, ...
    'Units','pixels', ...
    'BackgroundColor',[0.8 0.8 0.8], ...
    'HorizontalAlignment','left', ...
    'ListboxTop',0, ...
    'Position',[130 28 40 12], ...
    'String','', ...
    'Style','text', ...
    'Tag','zpos');

uicontrol('Parent',h0, ...
    'Units','pixels', ...
    'BackgroundColor',[0.8 0.8 0.8], ...
    'HorizontalAlignment','left', ...
    'ListboxTop',0, ...
    'Position',[170 28 15 12], ...
    'String','v:', ...
    'Style','text');

uicontrol('Parent',h0, ...
    'Units','pixels', ...
    'BackgroundColor',[0.8 0.8 0.8], ...
    'HorizontalAlignment','left', ...
    'ListboxTop',0, ...
    'Position',[185 28 40 12], ...
    'String','', ...
    'Style','text', ...
    'Tag','value');

% CS, 260199
%
uicontrol('Parent',h0, ...
    'Units','pixels', ...
    'BackgroundColor',[0.8 0.8 0.8], ...
    'HorizontalAlignment','left', ...
    'ListboxTop',0, ...
    'Position',[240 28 120 12], ...
    'String','NRU, 1998-2008', ...
    'Style','text', ...
    'Tag','acknowledgement');

uicontrol('Parent',h0, ...
    'Units','pixels', ...
    'BackgroundColor',[0.8 0.8 0.8], ...
    'Callback','editroi(''selectregion'')', ...
    'HorizontalAlignment','left', ...
    'ListboxTop',0, ...
    'Position',[6 100 110 18], ...
    'String',userdata.regionname, ...
    'Style','popupmenu', ...
    'Tag','popRegion', ...
    'Value',1);

uicontrol('Parent',h0, ...
    'Units','pixels', ...
    'BackgroundColor',[0.8 0.8 0.8], ...
    'Callback','editroi(''drawmode'')', ...
    'HorizontalAlignment','left', ...
    'ListboxTop',0, ...
    'Position',[122 100 70 18], ...
    'String',{'Add' 'Remove' 'Xor'}, ...
    'Style','popupmenu', ...
    'Tag','popAdd', ...
    'Value',1);

uicontrol('Parent',h0, ...
    'Units','pixels', ...
    'BackgroundColor',[0.8 0.8 0.8], ...
    'Callback','editroi(''drawmode'')', ...
    'HorizontalAlignment','left', ...
    'ListboxTop',0, ...
    'Position',[198 100 70 18], ...
    'String',{'Inside' 'Outside'}, ...
    'Style','popupmenu', ...
    'Tag','popInout', ...
    'Value',1);

h1=axes('Parent',h0, ...
    'Box','on', ...
    'Units','pixels', ...
    'Color',[0.6 0.6 0.6], ...
    'Position',[274 100 40 18], ...
    'Tag','preview', ...
    'XColor',[0.8 0.6 0.8], ...
    'XLim', [0 1], ...
    'XTick',[], ...
    'YColor',[0.8 0.6 0.8], ...
    'YLim', [0 1], ...
    'YTick',[]);

[style, marker]=GetLineStyle('InsideAdd');

h1=line([0.1 0.9],[0.5 0.5], ...
    'HitTest','off', ...
    'Linewidth',1,...
    'LineStyle', style, ...
    'Color', GetRegionColor(1), ...
    'Marker', marker, ...
    'MarkerSize', 8, ...
    'Tag','previewline');

%but.load=imread('load.tif');
%but.save=imread('save.tif');
%but.undo=imread('undo.tif');
%but.redo=imread('redo.tif');
%but.cut=imread('cut.tif');
%but.delete=imread('delete.tif');
%but.edit=imread('edit.tif');
%but.contour=imread('contour.tif');
%but.ellipse=imread('elipse.tif');
%but.info=imread('info.tif');
%but.move=imread('move.tif');
%but.copy=imread('copy.tif');
%but.plot=imread('plot.tif');
%but.polygon=imread('polygon.tif');
%but.roll=imread('roll.tif');
%but.rotate=imread('rotate.tif');
%but.resize=imread('resize.tif');
%but.mirror=imread('mirror.tif');
%but.mode=imread('mode.tif');
%but.region=imread('region.tif');

% All button images are saved into a single matlab file for speed optimization
load('buttons');

uicontrol('Parent',h0, ...
    'Units','pixels', ...
    'BackgroundColor',[0.702 0.702 0.702], ...
    'Callback','editroi(''save'')', ...
    'CData',but.save, ...
    'Position',[1 175 33 25], ...
    'Style','pushbutton', ...
    'TooltipString','Save regions', ...
    'Tag','butSave');

uicontrol('Parent',h0, ...
    'Units','pixels', ...
    'BackgroundColor',[0.702 0.702 0.702], ...
    'Callback','editroi(''load'')', ...
    'CData',but.load, ...
    'Position',[34 175 33 25], ...
    'Style','pushbutton', ...
    'TooltipString','Load regions', ...
    'Tag','butLoad');

uicontrol('Parent',h0, ...
    'Units','pixels', ...
    'BackgroundColor',[0.702 0.702 0.702], ...
    'Callback','editroi(''loadimg'')', ...
    'CData',but.roll, ...
    'Position',[67 175 33 25], ...
    'Style','pushbutton', ...
    'TooltipString','Load images', ...
    'Tag','butRoll');

uicontrol('Parent',h0, ...
    'Units','pixels', ...
    'BackgroundColor',[0.702 0.702 0.702], ...
    'Callback','editroi(''undo'')', ...
    'CData',but.undo, ...
    'Enable','off', ...
    'Position',[106 175 33 25], ...
    'Style','pushbutton', ...
    'TooltipString','Undo', ...
    'Tag','butUndo');

uicontrol('Parent',h0, ...
    'Units','pixels', ...
    'BackgroundColor',[0.702 0.702 0.702], ...
    'Callback','editroi(''redo'')', ...
    'CData',but.redo, ...
    'Enable','off', ...
    'Position',[139 175 33 25], ...
    'Style','pushbutton', ...
    'TooltipString','Redo', ...
    'Tag','butRedo');

uicontrol('Parent',h0, ...
    'Units','pixels', ...
    'BackgroundColor',[0.702 0.702 0.702], ...
    'Callback','editroi(''delete'')', ...
    'CData',but.delete, ...
    'Position',[178 175 33 25], ...
    'Style','pushbutton', ...
    'TooltipString','Delete', ...
    'Tag','butDelete');

uicontrol('Parent',h0, ...
    'Units','pixels', ...
    'BackgroundColor',[0.702 0.702 0.702], ...
    'Callback','editroi(''changeregion'')', ...
    'CData',but.region, ...
    'Position',[217 175 33 25], ...
    'Style','pushbutton', ...
    'TooltipString','Change Region', ...
    'Tag','butChRegion');

uicontrol('Parent',h0, ...
    'Units','pixels', ...
    'BackgroundColor',[0.702 0.702 0.702], ...
    'Callback','editroi(''changemode'')', ...
    'CData',but.mode, ...
    'Position',[250 175 33 25], ...
    'Style','pushbutton', ...
    'TooltipString','Change drawmode', ...
    'Tag','butChMode');

uicontrol('Parent',h0, ...
    'Units','pixels', ...
    'BackgroundColor',[0.702 0.702 0.702], ...
    'Callback','editroi(''draw'',''poly'')', ...
    'CData',but.polygon, ...
    'Position',[1 140 33 25], ...
    'Style','togglebutton', ...
    'TooltipString','Polygon', ...
    'Tag','butPoly', ...
    'UserData','drawbutton');

uicontrol('Parent',h0, ...
    'Units','pixels', ...
    'BackgroundColor',[0.702 0.702 0.702], ...
    'Callback','editroi(''draw'',''ellipse'')', ...
    'CData',but.ellipse, ...
    'Position',[34 140 33 25], ...
    'Style','togglebutton', ...
    'TooltipString','Ellipse', ...
    'Tag','butEllipse', ...
    'UserData','drawbutton');

uicontrol('Parent',h0, ...
    'Units','pixels', ...
    'BackgroundColor',[0.702 0.702 0.702], ...
    'Callback','editroi(''draw'',''contour'')', ...
    'CData',but.contour, ...
    'Position',[67 140 33 25], ...
    'Style','togglebutton', ...
    'TooltipString','Contour', ...
    'Tag','butContour', ...
    'UserData','drawbutton');

uicontrol('Parent',h0, ...
    'Units','pixels', ...
    'BackgroundColor',[0.702 0.702 0.702], ...
    'Callback','editroi(''movenodes'')', ...
    'CData',but.move, ...
    'Position',[106 140 33 25], ...
    'Style','togglebutton', ...
    'TooltipString','Select/move', ...
    'Tag','butMove', ...
    'UserData','drawbutton');

uicontrol('Parent',h0, ...
    'Units','pixels', ...
    'BackgroundColor',[0.702 0.702 0.702], ...
    'Callback','editroi(''editnodes'')', ...
    'CData',but.edit, ...
    'Position',[139 140 33 25], ...
    'Style','togglebutton', ...
    'TooltipString','Edit nodes', ...
    'Tag','butEdit', ...
    'UserData','drawbutton');

uicontrol('Parent',h0, ...
    'Units','pixels', ...
    'BackgroundColor',[0.702 0.702 0.702], ...
    'Callback','editroi(''rotate'')', ...
    'CData',but.rotate, ...
    'Position',[172 140 33 25], ...
    'Style','togglebutton', ...
    'TooltipString','Rotate', ...
    'Tag','butRotate', ...
    'UserData','drawbutton');

uicontrol('Parent',h0, ...
    'Units','pixels', ...
    'BackgroundColor',[0.702 0.702 0.702], ...
    'Callback','editroi(''resizenodes'')', ...
    'CData',but.resize, ...
    'Position',[205 140 33 25], ...
    'Style','togglebutton', ...
    'TooltipString','Resize', ...
    'Tag','butResize', ...
    'UserData','drawbutton');

uicontrol('Parent',h0, ...
    'Units','pixels', ...
    'BackgroundColor',[0.702 0.702 0.702], ...
    'Callback','editroi(''copy'')', ...
    'CData',but.copy, ...
    'Position',[238 140 33 25], ...
    'Style','togglebutton', ...
    'TooltipString','Copy', ...
    'Tag','butCopy', ...
    'UserData','drawbutton');
%	'String','Copy', ...

uicontrol('Parent',h0, ...
    'Units','pixels', ...
    'BackgroundColor',[0.702 0.702 0.702], ...
    'Callback','editroi(''mirror'')', ...
    'CData',but.mirror, ...
    'Position',[271 140 33 25], ...
    'Style','togglebutton', ...
    'TooltipString','Mirror', ...
    'Tag','butMirror', ...
    'UserData','drawbutton');

%h1 = uicontrol('Parent',h0, ...
%	'Units','pixels', ...
%	'BackgroundColor',[0.702 0.702 0.702], ...
%	'CData',but.plot, ...
%	'Position',[217 175 33 25], ...
%	'Style','pushbutton', ...
%	'TooltipString','Time study', ...
%	'Tag','butPlot');
%
%h1 = uicontrol('Parent',h0, ...
%	'Units','pixels', ...
%	'BackgroundColor',[0.702 0.702 0.702], ...
%	'CData',but.info, ...
%	'Position',[250 175 33 25], ...
%	'Style','pushbutton', ...
%	'TooltipString','Info', ...
%	'Tag','butInfo');
%

set(h0,'Position',[screensize(3:4)-[360 300] 360 220]);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Funktion til udregning af punkter paa en ellipse naar de to
%% braendpunkter samt laengden af hovedaksen er kendte.
%%
%% xf1, xf2 : de to braendpunkter
%% a        : halv laengde af hovedakse
%% Kenneth Geisshirt, 1999
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function f = periferi(x, xf1, xf2, a)

f = sqrt((x(1)-xf1(1))^2+(x(2)-xf1(2))^2) ...
    + sqrt((x(1)-xf2(1))^2+(x(2)-xf2(2))^2) ...
    + 2*a;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Funktion til udregning af statistik p? billede-sekvenser.
%% Se evt. funktionen Plot4DFile.
%%
%%
%% Kenneth Geisshirt, 1999
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function PlotMultiFrame(files)

wb=waitbar(0, 'Loading and calculating...');

% Faa fat i regionerne
Data=get(GetMainFigure, 'UserData');
regioncount=size(Data.regionname, 1);

% reset
vsum=zeros(regioncount, length(files));
count=zeros(regioncount,length(files));
scale=zeros(length(files));
offset=zeros(length(files));

t=1;
for m=1:length(files)
    str=files{m};
    name=str(1:length(str)-4); % Faa fat i navnene - uden efternavn

    hdr=ReadAnalyzeHdr(name);
    pre=hdr.pre;
    dim=hdr.dim;
    siz=hdr.siz;
    lim=hdr.lim;
    scale(m)=hdr.scale;
    offset(m)=hdr.offset;
    origin=hdr.origin;

    if all(origin==0)
        origin=origin+1;
    end
    for z=1:dim(3)
        relslice=(z-origin(3));
        [img,hdr]=ReadAnalyzeImg(name, sprintf('%d:', z));
        img=reshape(img, dim(1), dim(2));
        img=(img-offset(m))*scale(m);
        img=flipud(img');
        for region=1:regioncount
            waitbar(t/(dim(3)*regioncount*length(files)));
            mask=flipud(GetSliceMask(relslice, region, size(img), siz, origin));
            i=find(mask);
            count(region,m)=count(region,m)+length(i);
            vsum(region, m)=vsum(region, m)+sum(img(i));
            t=t+1;
        end
    end
    time(m,1)=m;
end

delete(wb);    % fjern status bar
tt=[];
for m=1:length(files)
    for region=1:regioncount
        if count(region,m)>0
            vsum(region,m)=vsum(region,m)/count(region,m);
            tt=[tt region];
            tt=unique(tt);
        end
    end
end


h0=figure('Name', 'Multi frame Mean Plot');
AddPlotMenu(h0);

ah=axes;
set(ah,'Color',[0.7 0.7 0.7], ...
    'XGrid','on', ...
    'YGrid','on');
xlabel('Frame');
ylabel('Mean value');
title('Multi frame','Interpreter','none');

%i=find(count>0);
%if ~isempty(i)
hl=[];
for region=1:size(tt,2)
    h=line(time(:,1)', vsum(tt(region),:),...
        'Color',GetRegionColor(region), ...
        'Marker','o',...
        'LineStyle', 'none');
    hl=[hl h];
end
legend(hl, char(Data.regionname(tt)));
% Generate data for save-menu function
savedata.top=[{'Time'} Data.regionname(tt)'];
savedata.left={};
savedata.data=[time(:,1) vsum(tt,:)'];
set(h0,'UserData',savedata);
%else
%  h=findobj('Tag','mnuSavePlot');
%  set(h,'Enable','off');
%end




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Function til at kombinere flere regioner, s?ledes at de udg?r et
%% f?lles s?t af regioner.
%%
%% Claus Madsen 2000
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function combineRegion(current)

global ROIcurrentregion
true = 1 == 1;
false = 2 == 1;

Data=get(GetMainFigure,'UserData');
j = 1;


vertex = Data.slicepolys.vertex;
relslice =  Data.slicepolys.relslice;
region = Data.slicepolys.region;
mode = Data.slicepolys.mode;
slicedist = Data.slicedist;

j(1) = 1;
j(2) = 1;
j(3) = 1;
j(4) = 1;
j(5) = 1;
j(6) = 1;

InsideAdd = [];
InsideXor = [];
InsideRemove = [];
OutsideAdd = [];
OutsideXor = [];
OutsideRemove = [];

for i=1:length(region)
    if region(i) == ROIcurrentregion
        if strcmp('InsideAdd',mode(i))
            InsideAdd.region(j(1)) = ROIcurrentregion;
            InsideAdd.vertex{j(1)} = Data.slicepolys.vertex{i};
            InsideAdd.relslice(j(1)) = Data.slicepolys.relslice(i);
            InsideAdd.mode{j(1)} = 'InsideAdd';
            InsideAdd.slicedist = Data.slicedist;
            InsideAdd.regionname = Data.regionname{ROIcurrentregion};
            tmp_relslice(j(1)) = Data.slicepolys.relslice(i);
            j(1) = j(1)+1;
        end;

        if strcmp('InsideXor',mode(i))
            InsideXor.region(j(2)) = ROIcurrentregion;
            InsideXor.vertex{j(2)} = Data.slicepolys.vertex{i}
            InsideXor.relslice(j(2)) = Data.slicepolys.relslice(i);
            InsideXor.mode{j(2)} = 'InsideXor';
            InsideXor.slicedist = Data.slicedist;
            InsideXor.regionname(j(2)) = Data.regionname(ROIcurrentregion);
            tmp_relslice(j(2)) = Data.slicepolys.relslice(i);
            j(2) = j(2)+1;
        end;

        if strcmp('InsideRemove',mode(i))
            InsideRemove.region(j(3)) = ROIcurrentregion;
            InsideRemove.vertex{j(3)} = Data.slicepolys.vertex{i};
            InsideRemove.relslice(j(3)) = Data.slicepolys.relslice(i);
            InsideRemove.mode{j(3)} = 'InsideRemove';
            InsideRemove.slicedist = Data.slicedist;
            InsideRemove.regionname(ROIcurrentregion) = Data.regionname(ROIcurrentregion);
            tmp_relslice(j(3)) = Data.slicepolys.relslice(i);
            j(3) = j(3)+1;
        end;

        if strcmp('OutsideAdd',mode(i))
            OutsideAdd.region(j(4)) = ROIcurrentregion;
            OutsideAdd.vertex{j(4)} = Data.slicepolys.vertex{i};
            OutsideAdd.relslice(j(4)) = Data.slicepolys.relslice(i);
            OutsideAdd.mode{j(4)} = 'OutsideAdd';
            OutsideAdd.slicedist = Data.slicedist;
            OutsideAdd.regionname(ROIcurrentregion) = Data.regionname(ROIcurrentregion);
            tmp_relslice(j(4)) = Data.slicepolys.relslice(i);
            j(4) = j(4)+1;
        end;

        if strcmp('OutsideXor',mode(i))
            OutsideXor.region(j(5)) = ROIcurrentregion;
            OutsideXor.vertex{j(5)} = Data.slicepolys.vertex{i};
            OutsideXor.relslice(j(5)) = Data.slicepolys.relslice(i);
            OutsideXor.mode{j(5)} = 'OutsideXor';
            OutsideXor.slicedist = Data.slicedist;
            OutsideXor.regionname(ROIcurrentregion) = Data.regionname(ROIcurrentregion);
            tmp_relslice(j(5)) = Data.slicepolys.relslice(i);
            j(5) = j(5)+1;
        end;

        if strcmp('OutsideRemove',mode(i))
            OutsideRemove.region(j(6)) = ROIcurrentregion;
            OutsideRemove.vertex{j(6)} = Data.slicepolys.vertex{i}
            OutsideRemove.relslice(j(6)) = Data.slicepolys.relslice(i);
            OutsideRemove.mode{j(6)} = 'OutsideRemove';
            OutsideRemove.slicedist = Data.slicedist;
            OutsideRemove.regionname(ROIcurrentregion) = Data.regionname(ROIcurrentregion);
            tmp_relslice(j(6)) = Data.slicepolys.relslice(i);
            j(6) = j(6)+1;
        end;
    end
end;

if not(isempty(InsideAdd))
    InsideAdd = checkROI(InsideAdd);
    VOI=Roi2Voi(InsideAdd);
    NewROI = Voi2Roi(VOI, Data.origin, Data.siz, Data.dim);

    %
    % Nu blive det en lille smule besv?rligt. De nye regioner skal
    % kun inds?tte p? skiver hvor der ikke for er en region.
    %
    for i=1:length(NewROI.region)
        Idx=NewROI.relslice(i)==tmp_relslice;

        if not(any(Idx))
            AddRoi(NewROI.vertex{i},'InsideAdd',NewROI.relslice(i), ROIcurrentregion);
        end
    end

end

if not(isempty(InsideXor))
    InsideXor = checkROI(InsideXor);
    VOI=Roi2Voi(InsideXor);
    NewROI = Voi2Roi(VOI, Data.origin, Data.siz, Data.dim);

    %
    % Nu blive det en lille smule besv?rligt. De nye regioner skal
    % kun inds?tte p? skiver hvor der ikke for er en region.
    %
end

if not(isempty(InsideRemove))
    InsideRemove = checkROI(InsideRemove);
    VOI=Roi2Voi(InsideRemove);
    NewROI = Voi2Roi(VOI, Data.origin, Data.siz, Data.dim);

    %
    % Nu blive det en lille smule besv?rligt. De nye regioner skal
    % kun inds?tte p? skiver hvor der ikke for er en region.
    %
    for i=1:length(NewROI.region)
        Idx=NewROI.relslice(i)==Data.slicepolys.relslice;

        if not(any(Idx))
            AddRoi(NewROI.vertex{i},'InsideRemove',NewROI.relslice(i), ROIcurrentregion);
        end
    end

end

if not(isempty(OutsideAdd))
    OutsideAdd = checkROI(OutsideAdd);
    VOI=Roi2Voi(OutsideAdd);
    NewROI = Voi2Roi(VOI, Data.origin, Data.siz, Data.dim);

    %
    % Nu blive det en lille smule besv?rligt. De nye regioner skal
    % kun inds?tte p? skiver hvor der ikke for er en region.
    %
    for i=1:length(NewROI.region)
        Idx=NewROI.relslice(i)==Data.slicepolys.relslice;

        if not(any(Idx))
            AddRoi(NewROI.vertex{i},'OutsideAdd',NewROI.relslice(i), ROIcurrentregion);
        end
    end
end

if not(isempty(OutsideXor))
    OutsideXor = checkROI(OutsideXor);
    VOI=Roi2Voi(OutsideXor);
    NewROI = Voi2Roi(VOI, Data.origin, Data.siz, Data.dim);

    %
    % Nu blive det en lille smule besv?rligt. De nye regioner skal
    % kun inds?tte p? skiver hvor der ikke for er en region.
    %
    for i=1:length(NewROI.region)
        Idx=NewROI.relslice(i)==Data.slicepolys.relslice;

        if not(any(Idx))
            AddRoi(NewROI.vertex{i},'OutsideXor',NewROI.relslice(i), ROIcurrentregion);
        end
    end
end

if not(isempty(OutsideRemove))
    OutsideRemove = checkROI(OutsideRemove);
    VOI=Roi2Voi(OutsideRemove);
    NewROI = Voi2Roi(VOI, Data.origin, Data.siz, Data.dim);

    %
    % Nu blive det en lille smule besv?rligt. De nye regioner skal
    % kun inds?tte p? skiver hvor der ikke for er en region.
    %
    for i=1:length(NewROI.region)
        Idx=NewROI.relslice(i)==Data.slicepolys.relslice;

        if not(any(Idx))
            AddRoi(NewROI.vertex{i},'OutsideRemove',NewROI.relslice(i), ROIcurrentregion);
        end
    end
end


function i=showyaxis(hfig)
if nargin==1
    g = hfig;
else
    g = gcbf;
end
a=get(g,'UserData');
if a.showtallarich
    showtallarich(g);
else
    showvoxel(g);
end


%
%
%
function showvoxel(g)
a=get(g,'UserData');
for i=1:length(a.yaxis)
    try
        delete(a.yaxis(i));
    catch
    end
end
a.yaxis = [];

ax=findobj(g,'Tag','roll');
axes(ax);
p=get(ax,'Position');
sl=findobj(g,'Tag','Slider1');
ycount=(p(4)/p(3))/a.aspect;
y=get(sl,'Value')*(a.ylen/a.imgheigth-ycount);
j= 1;
for i=floor(y):ceil(y+ycount)
    a.yaxis(j)= text(p(1)/(p(1)-p(3))*25,(i-a.origin(3))*a.siz(3), num2str(i),'color',[0 0 0],'rotation',90);
    j = j + 1;
end

a.showtallarich = 0;
warning('off');
set(g,'UserData',a);
warning('on');
if not(isempty(a.sidewindow))
    plotslice('chVisualLines',y,y+ycount,a.sidewindow)
end


%
%
%
function showtallarich(g,axeshandle)
a=get(g,'UserData');

for i=1:length(a.yaxis)
    try
        delete(a.yaxis(i));
    catch
    end
end
a.yaxis = [];

ax=findobj(g,'tag','roll');
axes(ax);
p=get(ax,'Position');
sl=findobj(g,'Tag','Slider1');
ycount=(p(4)/p(3))/a.aspect;
y=get(sl,'Value')*(a.ylen/a.imgheigth-ycount);
j = 1;
for i=floor(y):ceil(y+ycount)
    a.yaxis(j) = text(p(1)/(p(1)-p(3))*25,(i-a.origin(3))*a.siz(3),num2str(a.siz(3)*(i-a.origin(3))),'color',[0 0 0],'rotation',90);
    j = j + 1;
end
a.showtallarich = 1;
warning('off');
set(g,'UserData',a);
warning('on');

if not(isempty(a.sidewindow))
    plotslice('chVisualLines',y,y+ycount,a.sidewindow);
end;
