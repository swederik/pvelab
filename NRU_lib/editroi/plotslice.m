function fig=plotslice(arg1,arg2,arg3,arg4)
%
% Show sagital view.
%
% Author:
%    Claus Madsen, 170800
%
  
  
if strcmp(arg1,'init')
  arg2=  ReadAnalyzeHdr(arg2.filename);  
  arg2.imgtst = (ReadAnalyzeImg(arg2.name)-arg2.offset)*arg2.scale;   
  arg2.imgtst = reshape(arg2.imgtst,arg2.dim');    
  
  
  fig=figure('closeRequestFcn', 'plotslice(''close'') ',...
	     'position',[600 600 300 300],...
	     'colormap',gray(64),...
	     'name',arg2.name,...
	     'numbertitle','off',...
	     'menubar','none',...
	     'tag','plotslice');
  
  arg2.frame = 1;
  
  set(gca,'tag','plotslice_a','ydir','normal',...
	  'clim',arg4,...
	  'position',[.15 .15 .80 .85]);  
  imagesc(arg2.siz(2)*([1:arg2.dim(2)]'-arg2.origin(2)), arg2.siz(3)*([1:arg2.dim(3)]'-arg2.origin(3)),squeeze(arg2.imgtst(round(arg2.dim(1)/2),:,1+(arg2.frame-1)*arg2.dim(3):arg2.frame*arg2.dim(3)))'); 
  set(gca,'tag','plotslice_a','ydir','normal',...
	  'clim',arg4,...
	  'position',[.15 .3 .80 .69]);
  
  xlabel('y');
  ylabel('z');
  axis image   
  
  for i=1:arg2.dim(1)    
    minY = arg2.siz(2)*(1-arg2.origin(2));
    maxY = arg2.siz(2)*(arg2.dim(2)-arg2.origin(2));
    
    z = arg2.siz(3)*(i-arg2.origin(3));
    
    arg2.line(i) = line('xdata',[minY maxY],'ydata',[z z], ...
			'linestyle','-',...
			'marker','none',...
			'visible','off',...
			'color','green');     
  end
  
  uicontrol('style','frame',...
	    'units','normalized',...
	    'position',[.57 .04 .40 .16])
  
  uicontrol('style','slider',...
            'tag','slideX',...
            'units','normalized',...
            'min',arg2.siz(1)*(1-arg2.origin(1)),...
            'max',arg2.siz(1)*(arg2.dim(1)-arg2.origin(1)),...
            'sliderStep',[1/arg2.dim(2)  10/arg2.dim(2)],...
            'callback','plotslice(''newSlice'')',...  
	    'position',[.6 .05 .35 .05],...
            'value',round(arg2.siz(1)*(arg2.dim(1)/2-arg2.origin(1)))) 
      
      
  uicontrol('style','text',...
            'units','normalized',...
	    'position',[.6 .11 .35 .085],...
	    'string','Slice Nr. in x-direction');
  
        
  
  uicontrol('style','frame',...
	    'units','normalized',...
	    'position',[.04 .04 .52 .16])
  uicontrol('style','text',...
	    'units','normalized',...
	    'string','visible:',...
	    'position',[.05 .05 .3 .05]);
  
  uicontrol('style','text',...
	    'units','normalized',...
	    'string','visible and active:',...
	    'position',[.05 .11 .3 .05]);
      
  uicontrol('style','pushbutton',...
	    'units','normalized',...
	    'backgroundcolor','green',...
	    'tag','visible',...
	    'callback','plotslice(''visible'')',...
	    'position',[.35 .05 .2 .05]);
  
  uicontrol('style','pushbutton',...
	    'units','normalized',...	 
	    'backgroundcolor','red',...
	    'tag','active',...
	    'callback','plotslice(''active'')',...
	    'position',[.35 .11 .2 .05]);

  arg2.RollFig = arg3;
  arg2.active = [];
  set(fig,'userdata',arg2);
  
  
else
  switch arg1
   case 'newSlice'
    g = gcf;
    ud = get(gcf,'userdata');
    posX = get(findobj(gcf,'tag','slideX'),'value');
    x = round(posX/ud.siz(1) + ud.origin(1));
    slice = squeeze(ud.imgtst(x,:,1+(ud.frame-1)*ud.dim(3):ud.frame*ud.dim(3))); 
    set(findobj(findobj(gcf,'tag','plotslice_a'),'Type','image'),'cdata',slice','tag','Image')
    
   case 'chVisualLines'
    ud = get(findobj(arg4,'tag','plotslice'),'userdata');
    set(ud.line,'visible','off');
    if floor(arg2)<=0
      arg2=1;
    end
    for i=ceil(arg2):ceil(arg3)
      set(ud.line(i),'visible','on');
    end
    
   case 'NewPos'
    ud = get(findobj(arg3,'tag','plotslice'),'userdata');
    set(ud.line,'color',get(findobj(arg3,'tag','visible'),'backgroundcolor'))
    if arg2 <= 1
      arg2 = 1;
    end
    set(ud.line(ud.active),'color',get(findobj(arg3,'tag','active'),'backgroundcolor'))
    ud.active = arg2;
    set(arg3,'userdata',ud);
    
   case 'close'
    g = gcf;
    ud = get(gcf,'userdata');
    ud_roll = get(ud.RollFig,'userdata');
    ud_roll.sidewindow = [];
    
    %color = findobj(ud.RollFig,'tag','Colorbar');
    %colorUD = get(color,'userdata');
    %for i=1:length(colorUD.PlotHandle)
    %    if colorUD.PlotHandle(i) == findobj(g,'tag','plotslice_a')
    %        colorUD.PlotHandle(i) = [];
    %        set(color,'userdata',colorUD);
    %        break
    %    end
    %end

    set(ud.RollFig,'userdata',ud_roll)
    set(gcf,'CloseRequestFcn','closereq');
    close(gcf);
    
   case 'active'
    result = uisetcolor;
    if result ~= 0
      ud = get(gcf,'userdata');
      set(ud.line(ud.active),'color',result)
      set(findobj(gcf,'tag','active'),'backgroundcolor',result);
    end 
   
   case 'visible'
    result = uisetcolor;
    if result ~= 0
      ud = get(gcf,'userdata');
      set(ud.line,'color',result)
      set(ud.line(ud.active),'color',get(findobj(gcf,'tag','active'),'backgroundcolor'))
      set(findobj(gcf,'tag','visible'),'backgroundcolor',result);
    end
  end
   
end




