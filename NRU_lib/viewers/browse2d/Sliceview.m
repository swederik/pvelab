function fig=Sliceview(arg1,arg2,arg3,arg4,arg5);
% 
% Sliceview(arg1,arg2,arg3,arg4,arg5);
%
% simple, slice-based Analyze-viewer
% 
% Used by browse2d
% 
% PW, NRU, jan/feb 2001
%
  if nargin > 0
    switch arg1
      
     case 'Load'
      % initial load
      if not(exist('arg5'))
	arg5=[];
      end
      fig=SetupWindow(arg2,arg3,arg4,arg5);
      
     case 'UpdateZ'
      UpdateZ
      
     case 'UpdateXY'
      UpdateXY
      
     case 'Close'
      Close
      
     case 'Colormap'
      Colormap
      
     case 'Resetscale'
      Resetscale
      
      
    end
  end
  
  
function fig=SetupWindow(filename,frameno,nametag,point)
  if exist([filename '.hdr'])==2 & exist([filename '.img'])==2
    hdr=ReadAnalyzeHdr(filename);
    hdr.name=filename;
    if all(hdr.origin==0)
      hdr.origin=hdr.origin+1;
    end
    if hdr.scale==0
      hdr.scale=1;
    end
    xax=([1:hdr.dim(1)]-hdr.origin(1))*hdr.siz(1);
    yax=([1:hdr.dim(2)]-hdr.origin(2))*hdr.siz(2);
    zax=([1:hdr.dim(3)]-hdr.origin(3))*hdr.siz(3);
    if isempty(point)
      zval=mean(zax);
      xval=mean(xax);
      yval=mean(yax);
    else
      zval=point(3);
      xval=point(1);
      yval=point(2);
    end
    hdr.LoadFrame=frameno;
    
   %_______________________________________________________________
    %Color scaling indsat af Thomas Rask 171103
    img_tmp=ReadAnalyzeImg(hdr.name); %Load Image    
    [Min,Max,imgType]=findLim(img_tmp,'peak');
    if strcmp(imgType,'PET')
        ud.cmap=hot(64);
    else
        ud.cmap=gray(64);
    end
    
    clear('img_temp'); %clean up
    %_______________________________________________________________
   
    [img,img_raw]=ReadSlice(hdr,zval,Min,Max);
    
    fig=figure('numbertitle','off','name',[filename ' ' nametag], ...
        'closerequestfcn','Sliceview(''Close'')');
    ax=axes;
    PlotImg(ax,xax,yax,img)

    set(fig,'colormap',ud.cmap); %Set colormap. Added by TR060104

    Setcross(fig,[xval yval]);
    Width=(1-0.025-0.1);
    uicontrol('style','slider','units','normalized','position',[0 0 0.025 1],...
	      'min',min(zax),'max',max(zax),'value',zval, ...
	      'callback','Sliceview(''UpdateZ'')');
    uicontrol('style','text','units','normalized','position',...
	      [0.025 0.97 Width/5 0.03],'HorizontalAlignment','left',...
	      'string','Pos (mm):','fontweight','bold')
    uicontrol('style','text','units','normalized','position',...
	      [0.025+Width/5 0.97 4*Width/10 0.03],'HorizontalAlignment','left',...
	      'string','Coordinates: ','tag','Coordlabel_mm')
    uicontrol('style','text','units','normalized','position',...
	      [0.025 0.94 Width/5 0.03],'HorizontalAlignment','left',...
	      'string','Pos (vox):','fontweight','bold')
    uicontrol('style','text','units','normalized','position',...
	      [0.025+Width/5 0.94 4*Width/10 0.03],'HorizontalAlignment','left',...
	      'string','Coordinates: ','tag','Coordlabel_vox')		    
    uicontrol('style','text','units','normalized','position',...
	      [0.025+Width*0.6 0.94 Width/10 0.06],'HorizontalAlignment','right',...
	      'string','Value:','fontweight','bold')
    uicontrol('style','text','units','normalized','position',...
	      [0.025+Width*0.7 0.94 2*Width/10 0.06],'HorizontalAlignment','right',...
	      'string','Coordinates: ','tag','xyzValue')
    
    ax1=axes('position',[0.9 0.05 0.1 0.9],'tag','Colors');
    A=[1:64;1:64]';
    cax=linspace(Min,Max,64);
    im=image([1 2],cax,A);
    set(ax1,'tag','Colors','ydir','normal','buttondownfcn', ...
	    'Sliceview(''Colormap'')','xticklabel',[]);
    set(im,'tag','Colors','buttondownfcn','Sliceview(''Colormap'')');
    ud.hdr=hdr;
    ud.Friends=[];
    ud.defaultLim=[Min Max]; %171103TR
    ud.xax=xax;
    ud.yax=yax;
    ud.zax=zax;
    ud.lastpress='';
    ud.min=Min;%hdr.lim(2);
    ud.max=Max;%hdr.lim(1);
    ud.xyz=[xval yval zval];
    ud.rawimg=img_raw;
    set(fig,'userdata',ud);
    SetPosLabel(fig,ud.xyz,ud.hdr);
    SetValueLabel(fig);
    uicontrol('style','pushbutton','units','normalized',...
	      'position',[0.9 0 0.1 0.05],'string','Reset',...
	      'callback','Sliceview(''Resetscale'')');
    
  else
    disp(['Analyze dataset ' filename ' misses .hdr or .img']);
  end
  
function UpdateXYZ
  Firstfig=gcbf;
  udF=get(Firstfig,'userdata');
  figs=[Firstfig udF.Friends];
  zval=udF.xyz(3);
  NewPoint=udF.xyz(1:2);
  for j=1:length(figs)
    if isobj(figs(j))
      ud=get(figs(j),'userdata');
      ud.xyz=udF.xyz;
      slider=findobj('style','slider','parent',figs(j));
      Setslider(slider,zval);
      ax=findobj('type','axes','parent',figs(j),'tag','');
      [img,img_raw]=ReadSlice(ud.hdr,zval,ud.min,ud.max);
      ud.rawimg=img_raw;
      PlotImg(ax,ud.xax,ud.yax,img);
      %title(['axial slice at z=' num2str(get(slider,'value')) ' mm'])
      xlabel('x/[mm]');
      ylabel('y/[mm]');  
      Setcross(figs(j),NewPoint);
      set(figs(j),'userdata',ud)
      SetPosLabel(figs(j),udF.xyz,ud.hdr)
      SetValueLabel(figs(j));
    end
  end  
  
  
function SetPosLabel(handle,xyz,hdr)
  vox=round((xyz./hdr.siz')+hdr.origin');
  box1=findobj('parent',handle,'tag','Coordlabel_mm','style','text');
  box2=findobj('parent',handle,'tag','Coordlabel_vox','style','text');
  set(box1,'string',['[ ' num2str(xyz(1)) ...
		    ' , ' num2str(xyz(2)) ...
		    ' , ' num2str(xyz(3)) ' ]'])
  set(box2,'string',['[ ' num2str(vox(1)) ...
		     ' , ' num2str(vox(2)) ...
		     ' , ' num2str(vox(3)) ' ]'])
  
function SetValueLabel(handle)
  valbox=findobj('parent',handle,'tag','xyzValue','style','text');
  ud=get(handle,'userdata');
    value=interp2(ud.xax,ud.yax,ud.rawimg,ud.xyz(1),ud.xyz(2),'nearest');
  set(valbox,'string',num2str(value));
		    
function UpdateZ
  Firstfig=gcbf;
  udF=get(Firstfig,'userdata');
  udF.xyz(3)=get(findobj('parent',Firstfig,'style','slider'),'value');
%  figs=[Firstfig udF.Friends];
%  val=get(findobj('parent',Firstfig,'style','slider'),'value');
%  for j=1:length(figs)
%    ud=get(figs(j),'userdata');
%    slider=findobj('style','slider','parent',figs(j));
%    Setslider(slider,val);
%    ax=findobj('type','axes','parent',figs(j),'tag','');
%    img=ReadSlice(ud.hdr,val,ud.min,ud.max);
%    PlotImg(ax,ud.xax,ud.yax,img);
%    title(['axial slice at z=' num2str(get(slider,'value')) ' mm'])
%    xlabel('x/[mm]');
%    ylabel('y/[mm]');   
%  end
  set(Firstfig,'userdata',udF)
  UpdateXYZ
  
function UpdateXY
  Firstfig=gcbf;
  udF=get(Firstfig,'userdata');
  %figs=[Firstfig udF.Friends];
  ax=get(gcbo,'parent');
  NewPoint=get(ax,'currentpoint');
  NewPoint=[NewPoint(1,1) NewPoint(1,2)];
  %for j=1:length(figs)
  %  Setcross(figs(j),NewPoint);
  %end 
  udF.xyz(1)=NewPoint(1);
  udF.xyz(2)=NewPoint(2);
  set(Firstfig,'userdata',udF)
  UpdateXYZ

function Setcross(fig,point)
  lines=findobj(fig,'type','line');
  ax=findobj(fig,'type','axes','tag','');
  delete(lines)
  xlim=get(ax,'xlim');
  ylim=get(ax,'ylim');
  Point(1)=max(xlim(1),point(1));
  Point(1)=min(xlim(2),Point(1));
  Point(2)=max(ylim(1),point(2));
  Point(2)=min(ylim(2),Point(2));
  axes(ax)
  hold on
  lin1=line([Point(1) Point(1)],ylim);
  lin2=line(xlim,[Point(2) Point(2)]);
  set(lin1,'buttondownfcn','Sliceview(''UpdateXY'')','color','white');
  set(lin2,'buttondownfcn','Sliceview(''UpdateXY'')','color','white');
  if not(all(Point==point))
    disp(['Warning: crosshair truncated on dataset ' ...
	  get(fig,'name')]);
  end
  hold off
  
function Setslider(handle,value);
  Min=get(handle,'min');
  Max=get(handle,'max');
  val=max(Min,value);
  val=min(Max,val);
  set(handle,'value',val);
  if not(val==value)
    disp(['Warning: slider value truncated on dataset ' ...
	  get(get(handle,'parent'),'name')]);
  end
  
function [img,img_raw]=ReadSlice(hdr,zval,Min,Max)
  zax=([1:hdr.dim(3)]-hdr.origin(3))*hdr.siz(3);    
  
  [tmp,zval]=min(abs(zax-zval));
  img_raw=ReadAnalyzeImg(hdr.name,[num2str(round(zval)) ',' num2str(hdr.LoadFrame)])';
  img=img_raw;
  img(img<Min)=Min;
  img(img>Max)=Max;
  %img=(img-hdr.offset)*hdr.scale;
  img=1+63*(img-Min)/(Max-Min);
  
function PlotImg(ax,xax,yax,img)
  axes(ax);
  % Is an image here?
  oldimg=findobj('parent',ax,'type','image');
  if not(isempty(oldimg))
    set(oldimg,'cdata',img)
  else
    oldimg=image(xax,yax,img);
    set(ax,'ydir','normal');
    axis image
  end
  set(oldimg,'buttondownfcn','Sliceview(''UpdateXY'')');
  
function Close
  ud=get(gcbo,'userdata');
  for j=1:length(ud.Friends);
    if isobj(ud.Friends(j))
      udj=get(ud.Friends(j),'userdata');
      udj.Friends(udj.Friends==gcbo)=[];
      set(ud.Friends(j),'userdata',udj)
    end
  end
  set(gcbo,'closerequestfcn','closereq');
  close(gcbo)
  
  
    
function Colormap
  
  ud=get(gcbf,'userdata');
  
  press = get(gcbf,'SelectionType');
  if strcmp(press,'open')
    if strcmp(ud.lastpress,'normal')
      [tmp map] = cmapsel(' ',get(gcf,'colormap')); 
      set(gcbf,'colormap',map);
    elseif strcmp(ud.lastpress,'alt')
      res={};
      res=inputdlg({char({'Enter limits for colormap:', ...
			  '', ...
			  'Minimum:'}), ...
		    'Maximum'}, ...
		   'Colormap Limits', 1, ...
		   {num2str(ud.min), num2str(ud.max)});
      if not(isempty(res))
	min_ = str2num(res{1});
	max_ = str2num(res{2});
    if (min_<=max_) %(min_>=ud.hdr.lim(2)) & (max_<=ud.hdr.lim(1)) & (min_<=max_) DISABLED by TR060104 because of trouble with 32bit pics...
	  ud.min=min_;
	  ud.max=max_;
	  set(gcbf,'userdata',ud);
	  UpdateZ;
	  UpdateCmax
	else
	  disp('Warning: Selected colormap limits illegal!');
	end 
      end
    end
  end
  ud.lastpress=press;
  set(gcbf,'userdata',ud);

function Resetscale
  ud=get(gcbf,'userdata');
  ud.min=ud.defaultLim(1);
  ud.max=ud.defaultLim(2);
  set(gcbf,'Userdata',ud);
  UpdateZ
  
function UpdateCmax
  ax=findobj('type','axes','tag','Colors','parent',gcbf);
  axes(ax);
  ud=get(gcbf,'userdata');
  set(ax,'ylim',[ud.min ud.max]);
  img=findobj('parent',ax,'type','image');
  set(img,'ydata',linspace(ud.min,ud.max,64));
  
  