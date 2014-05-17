function [mapout]=editcmap(arg1, arg2)
%EDITCMAP  dialog for editing a colormap
%  RES=EDITCMAP(MAP)  edits the colormap MAP and return it in RES. 
%     MAP must be a Nx3 array.
%  RES=EDITMAP(FIGURE)  edits the colormap in figure, and returns 
%     it in res.
%  EDITMAP(FIGURE)  edits the colormap in figure.

if nargin==0
  arg1=gcf;
end

if isempty(gcbf) | (~ischar(arg1))  %NOT a callback
  if (size(arg1,2)~=3) & any(size(arg1)~=[1 1])
    error('Input argument must be a scalar or a N by 3 vector');
  end
  dowait=nargout;
  if size(arg1,2)==1
    h=get(0,'Children');
    if all(h~=arg1)
      error('Invalid figure handle');
    end
    cmap=get(arg1,'ColorMap');
    MakeFigure(cmap,arg1,dowait);
  else
    MakeFigure(arg1,[],dowait);
  end
  if dowait
    fig=gcf;
    uiwait;
    h=get(0,'Children');
    if all(h~=fig)
      mapout=[];
    else
      mapout=get(fig,'ColorMap');
      close(fig);
    end
  end
else
%  disp(arg1)
  switch arg1
    case 'movecopy'
      a=get(gcbf,'UserData');
      cmap=get(gcbf,'ColorMap');
      p=get(gca,'CurrentPoint');
      if (p(1,1)>=0.5) & (p(1,2)>=-8)
	c=fix(p(1,1)+0.5);
	r=fix((p(1,2)+8)/16)*16;
	d=c+r;
	s=size(cmap,1);
	if (c<=16) & (d<=s) & (d~=a.to)
          set(a.patches(a.to),'CData',a.to);
          a.to=d;
          set(a.patches(d),'CData',a.from);
          set(gcbf,'UserData',a);
          set([a.marker2],'XData',[a.to a.to]);
	end
      end
    
    case 'startmovecopy'
      a=get(gcbf,'UserData');
      a.function='copy';
      set(gcbf,'WindowButtonMotionFcn','editcmap(''movecopy'')',...
               'WindowButtonUpFcn','editcmap(''btnup'')', ...
               'UserData',a);
      setptr(gcbf,'hand');
      
    case 'btnup'
      set(gcbf,'Pointer','arrow',...
               'WindowButtonMotionFcn','',...
               'WindowButtonUpFcn','');
      a=get(gcbf,'UserData');
      switch a.function
        case 'select'
        
        case 'copy'
	  cmap=get(gcbf,'ColorMap');
	  s=size(cmap,1);
	  set(a.patches(a.to),'CData',a.to);
	  p=get(gca,'CurrentPoint');
	  if (p(1,1)>=0.5) & (p(1,2)>=-8)
	    c=fix(p(1,1)+0.5);
	    r=fix((p(1,2)+8)/16)*16;
	    d=c+r;
	    if (c<=16) & (d<=s)
              cmap(d,:)=cmap(a.from,:);
              UpdateColors(cmap);
	    end
	  end	
	  
	case 'fade'
          a=get(gcbf,'UserData');
          c1=a.from;
          c2=a.to;
          sel=a.from;
	  p=get(gca,'CurrentPoint');
	  if (p(1,1)>=0.5) & (p(1,2)>=-8)
	    c=fix(p(1,1)+0.5);
	    r=fix((p(1,2)+8)/16)*16;
	    d=c+r;
	    s=size(a.patches,1);
	    if (c<=16) & (d<=s)
              switch a.flowalgo
                case 1
                  MakeHSVFlow(gcbf,c1,c2);
                case 2
                  MakeLogFlow(gcbf,c1,c2);
                case 3
                  MakeFlow(gcbf,c1,c2);
              end
%              figure(15);
%              subplot(2,2,1+fix((d-1)/16));
%              plot(cmap(c1:c2,1),'r');
%              hold('on');
%              plot(cmap(c1:c2,2),'g');
%              plot(cmap(c1:c2,3),'b-');
%              hold('off');
              sel=a.to;
            end
          end
          set(a.patches(1:sel-1),'LineWidth',0.5);
          set(a.patches(sel),'LineWidth',5);
          set(a.patches(sel+1:size(a.patches,1)),'LineWidth',0.5);
          
      end	
%****      
    case 'startmovefade'
      a=get(gcbf,'UserData');
      a.function='fade';
      set(gcbf,'Pointer','cross',...
               'WindowButtonMotionFcn','editcmap(''movefade'')',...
               'WindowButtonUpFcn','editcmap(''btnup'')',...
               'UserData',a);
      
    
    case 'movefade'
      a=get(gcbf,'UserData');
      p=get(gca,'CurrentPoint');
      if (p(1,1)>=0.5) & (p(1,2)>=-8)
	c=fix(p(1,1)+0.5);
	r=fix((p(1,2)+8)/16)*16;
	d=c+r;
	s=size(a.patches,1);
	if (c<=16) & (d<=s) & (d~=a.to)
          a.to=d;
          x1=min([a.from a.to]);
          x2=max([a.from a.to]);
          set(a.patches(1:x1-1),'LineWidth',0.5);
          set(a.patches(x1:x2),'LineWidth',5);
          set(a.patches(x2+1:size(a.patches,1)),'LineWidth',0.5);
          set([a.marker2],'XData',[a.to a.to]);
          set(gcbf,'UserData',a);
	end
      end
    

    case 'select'
      switch get(gcbf,'SelectionType')
        case 'normal'
          h=findobj(gcbf,'LineWidth',5);
          set(h,'LineWidth',0.5);
          set(gcbo,'LineWidth',5);
          a=get(gcbf,'UserData');
          a.from=get(gcbo,'CData');
          a.to=a.from;
          a.function='select';
          set(gcbf,'WindowButtonMotionFcn','editcmap(''startmovecopy'')',...
                   'WindowButtonUpFcn','editcmap(''btnup'')', ...
                   'UserData',a);
          set([a.marker1 a.marker2],'XData',[a.from a.from]);

        case 'extend'
%          set(gcbo,'LineWidth',5);

        case 'alt'
          a=get(gcbf,'UserData');
          a.to=get(gcbo,'CData');
          a.from=a.to;
          a.function='select';
          set([a.marker1 a.marker2],'XData',[a.from a.from]);
          x1=min([a.from a.to]);
          x2=max([a.from a.to]);
          set(a.patches(:),'LineWidth',0.5);
          set(a.patches(a.to),'LineWidth',5);
          set(gcbf,'WindowButtonMotionFcn','editcmap(''startmovefade'')',...
                   'WindowButtonUpFcn','editcmap(''btnup'')', ...
                   'UserData',a);
                             
          
        case 'open'
          c=get(gcbo,'CData');
          cmap=get(gcbf,'ColorMap');
          res=uisetcolor(cmap(c,:),'Edit Color');
          cmap(c,:)=res;
          UpdateColors(cmap);
      end

    case 'Ok'
      a=get(gcbf,'UserData');
      if a.wait
        uiresume;
      else
        close(gcbf);
      end      

    case 'Fading'
       if strcmp(get(gcbo,'Checked'),'off')
         h=findobj(gcbf,'Tag','mnuFadeItem');
         set(h,'Checked','off');
         set(gcbo,'Checked','on');
         a=get(gcbf,'UserData');
         a.flowalgo=arg2;
         set(gcbf,'UserData',a);
       end
       
     case 'Redim'
       cmap=get(gcbf,'ColorMap');
       len=size(cmap,1);
       res=inputdlg('New colormap length:','Colormap Length',1,{num2str(len)});
       if ~isempty(res)
         newlen=(str2num(res{1}));
         
         cmap2=[spline(1:len,cmap(:,1),[1:newlen]*len/newlen)' ...
                spline(1:len,cmap(:,2),[1:newlen]*len/newlen)' ...
                spline(1:len,cmap(:,3),[1:newlen]*len/newlen)'];
         cmap2(find(cmap2>1))=1;
         cmap2(find(cmap2<0))=0;
         UpdateColors(cmap2);         
       end

    case 'Resize'
      ResizeFigure(gcbf);
  end
end




%***************************
function MakeFigure(cmap,fig,dowait)

Data.from=1;
Data.to=1;
Data.patches=[];
Data.figure=fig;
Data.flowalgo=1;
Data.wait=dowait;

a = figure('Color',[0.701961 0.701961 0.701961], ...
	'Colormap',cmap, ...
	'Interruptible','off', ...
	'Name','Edit Colormap', ...
	'NumberTitle','off', ...
	'Units','pixels', ...
	'Position',[100 150 640 480], ...
	'ResizeFcn','editcmap(''Resize'')', ...
	'Tag','Fig1', ...
	'UserData',Data);

b=uimenu('Parent',a, ...
         'Tag', 'mnuFading', ...
         'Label','F&ading');
  c=uimenu('Parent',b, ...
           'CallBack','editcmap(''Fading'',1)', ...
           'Checked','on', ...
           'Tag','mnuFadeItem',...
           'Label','&HSV');
  c=uimenu('Parent',b, ...
           'CallBack','editcmap(''Fading'',3)', ...
           'Tag','mnuFadeItem',...
           'Label','&RGB');
  c=uimenu('Parent',b, ...
           'CallBack','editcmap(''Fading'',2)', ...
           'Tag','mnuFadeItem',...
           'Label','RGB &Constant Light');

b=uimenu('Parent',a, ...
         'Tag', 'mnuEdit', ...
         'Label','&Edit');
  c=uimenu('Parent',b, ...
           'CallBack','editcmap(''Redim'')', ...
           'Tag','mnuRedim',...
           'Label','&Length');


b = uicontrol('Parent',a, ...
	'Units','pixels', ...
	'BackgroundColor',[0.701961 0.701961 0.701961], ...
	'Callback','editcmap(''Ok'');', ...
	'FontUnits','pixels', ...
	'FontSize',14, ...
	'FontName','application', ...
	'FontWeight','demi', ...
	'Interruptible','off', ...
	'Position',[30 10 80 30], ...
	'String','Ok', ...
	'Tag','Ok');

b = uicontrol('Parent',a, ...
	'Units','pixels', ...
	'BackgroundColor',[0.701961 0.701961 0.701961], ...
	'Callback','close(gcbf);', ...
	'FontUnits','pixels', ...
	'FontSize',14, ...
	'FontName','application', ...
	'FontWeight','demi', ...
	'Interruptible','off', ...
	'Position',[140 10 80 30], ...
	'String','Cancel', ...
	'Tag','Cancel');

b = axes('Parent',a, ...
	'Units','pixels', ...
	'Box','on', ...
	'CameraUpVector',[0 1 0], ...
	'CameraUpVectorMode','manual', ...
	'Color',[1 1 1], ...
	'Interruptible','off', ...
	'Layer','top', ...
	'Position',[30 360 580 100], ...
	'XColor',[0 0 0], ...
	'XLim',[0.5 size(cmap,1)+0.5], ...
	'XLimMode','manual', ...
        'XTick',[], ...
	'YColor',[0 0 0], ...
	'YLimMode','manual', ...
	'YTickMode','manual', ...
	'YTick',[0:0.5:1], ...
	'ZColor',[0 0 0]);

image([1:size(cmap,1)],[-0.25 -0.5],[1:size(cmap,1)]);
set(b,'YDir','normal', ...
      'YLim',[-0.5 1], ...
      'YTick',[0:0.5:1], ...
      'XTick',[16:16:size(cmap,1)], ...
      'Tag','ColorPlot');

l=line(1:size(cmap,1),cmap(:,1));
set(l,'Color',[1 0 0],'Tag','rline');
Data.rline=l;
l=line(1:size(cmap,1),cmap(:,2));
set(l,'Color',[0 1 0],'Tag','gline');
Data.gline=l;
l=line(1:size(cmap,1),cmap(:,3));
set(l,'Color',[0 0 1],'Tag','bline');
Data.bline=l;
l=line([0 0],[-0.5 1]);
set(l,'Color',[0 0.5 0],'Tag','Marker1');
Data.marker1=l;
l=line([0 0],[-0.5 1]);
set(l,'Color',[0.5 0 0],'Tag','Marker1');
Data.marker2=l;


b = axes('Parent',a, ...
	'Units','pixels', ...
	'Box','on', ...
	'CameraUpVector',[0 1 0], ...
	'CameraUpVectorMode','manual', ...
	'Color',[1 1 1], ...
	'DrawMode','fast', ...
	'Interruptible','off', ...
	'Layer','top', ...
	'Position',[30 70 580 270], ...
	'Tag','PatchAxes', ...
	'XColor',[0 0 0], ...
	'XLimMode','manual', ...
	'XLim',[0.5 16.5],...
	'XTickMode','manual',...
	'XTick',[1:16],...
	'YColor',[0 0 0], ...
	'YLimMode','auto', ...
	'YDir','reverse', ...
	'YTickMode','manual',...
	'YTick',[0:16:512],...
	'ZColor',[0 0 0]);
x=[];
y=[];
c=[];
for n=1:size(cmap,1)
  r=fix((n-1)/16);
  c=(n-1-r*16);
  r=r*16-8;
  c=c+0.5;
  x=[x [c; c; c+1; c+1]];
  y=[y [r; r+16; r+16; r]];
  p=patch(x(:,n),y(:,n),n);
  set(p,'ButtonDownFcn','editcmap(''select'')',...
        'CDataMapping','direct', ...
        'EraseMode','normal');
  Data.patches=[Data.patches; p];
end

set(gca,'YLim',[min(min(y)) max(max(y))]);
set(a,'Userdata',Data);


%*****************************
function ResizeFigure(fig)


pos=get(fig,'Position');
posold=pos;
if pos(3)<250
  pos(3)=250;
end
if pos(4)<220
  pos(4)=220;
end
if any(pos~=posold)
  set(fig,'Position',pos);
end


h1=findobj(fig,'Tag','PatchAxes');
set(h1,'Position',[30 70 pos(3)-60 pos(4)-210]);
h2=findobj(fig,'Tag','ColorPlot');
set(h2,'Position',[30 pos(4)-120 pos(3)-60 100]);

%	'Position',[30 360 580 100], ...



%*****************************
function UpdateColors(cmap)


a=get(gcbf,'UserData');
oldmap=get(gcbf,'ColorMap');
len=size(cmap,1);

set(gcbf,'ColorMap',cmap);
set(a.figure,'ColorMap',cmap);

h=findobj(gcbf,'Tag','ColorPlot');
axes(h);

if any(size(oldmap)~=size(cmap))
  hi=findobj(h,'Type','image');
  set(hi,'CData',[1:len],'XData',[1:len]);
  set(h,'XLim',[0.5 len+0.5],'XTick',[16:16:len]);
  
  h2=findobj(gcbf,'Tag','PatchAxes');
  axes(h2);
  
  hp=findobj(h2,'Type','patch');
  delete(hp);
  Data=get(gcbf,'UserData');
  Data.patches=[];
  x=[];
  y=[];
  for n=1:len
    r=fix((n-1)/16);
    c=(n-1-r*16);
    r=r*16-8;
    c=c+0.5;
    x=[x [c; c; c+1; c+1]];
    y=[y [r; r+16; r+16; r]];
    p=patch(x(:,n),y(:,n),n);
    set(p,'ButtonDownFcn','editcmap(''select'')',...
          'CDataMapping','direct', ...
          'EraseMode','normal');
    Data.patches=[Data.patches; p];
  end
  set(gca,'YLim',[min(min(y)) max(max(y))]);
  set(gcbf,'UserData',Data);
  axes(h);
end

set(a.rline,'YData',cmap(:,1),'XData',[1:len]);
set(a.gline,'YData',cmap(:,2),'XData',[1:len]);
set(a.bline,'YData',cmap(:,3),'XData',[1:len]);


%***************************
function MakeFlow(fig,c1,c2);

if c1==c2
  return;
end

a=[c1 c2];
c1=min(a);
c2=max(a);

cmap=get(fig,'ColorMap');
r=c2-c1;
start=cmap(c1,:);
delta=cmap(c2,:)-cmap(c1,:);

for n=1:r
  cmap(c1+n,:)=start+n*delta/r;
end

UpdateColors(cmap);

%***************************
function MakeHSVFlow(fig,c1,c2);

if c1==c2
  return;
end

a=[c1 c2];
c1=min(a);
c2=max(a);

cmap=get(fig,'ColorMap');

HSV=rgb2hsv(cmap([c1 c2],:));

x=cos(HSV(:,1)*2*pi).*HSV(:,2);
y=sin(HSV(:,1)*2*pi).*HSV(:,2);

r=c2-c1;

for n=1:r
  x3=x(1)+(x(2)-x(1))*n/r;
  y3=y(1)+(y(2)-y(1))*n/r;
  S=sqrt(x3.^2+y3.^2);
  if S>0
    H=acos(x3./S)/(2*pi);
  else
    H=0;
  end
  if y3<0
    H=1-H;
  end
  V=HSV(1,3)+(HSV(2,3)-HSV(1,3))*n/r;
  cmap(c1+n,:)=hsv2rgb(H,S,V);
end

UpdateColors(cmap);


%******************************
function MakeLogFlow(fig,c1,c2);

if c1==c2
  return;
end

a=[c1 c2];
c1=min(a);
c2=max(a);
c=2;

cmap=get(fig,'ColorMap');
r=c2-c1;
start=exp(cmap(c1,:)*c);
delta=exp(cmap(c2,:)*c)-exp(cmap(c1,:)*c);

startV=max(cmap(c1,:));
deltaV=max(cmap(c2,:))-max(cmap(c1,:));

for n=1:r
  cmap(c1+n,:)=log(start+n*delta/r)/c;
  if max(cmap(c1+n,:))>0
    V=startV+n*deltaV/r;
    cmap(c1+n,:)=cmap(c1+n,:)*V/max(cmap(c1+n,:));
  end
end

UpdateColors(cmap);


