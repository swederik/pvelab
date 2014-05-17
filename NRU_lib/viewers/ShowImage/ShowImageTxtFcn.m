function []=ShowImageTxtFcn(Inp)
%
%
if (nargin ~= 1),
   fprintf('ShowImageTxtFcn is called without argument\n');
   exit(1);
end;
%
if (Inp == 0),
   % Write txt functions
   h=get(gcf,'Children');
   h_txt=-1;
   for ii=1:length(h),
      if (isstr(strcmp(get(h(ii),'UserData')) == 1) &...
	    (strcmp(get(h(ii),'UserData'),'h_WriteTxt') == 1),
         h_txt = h(ii);
      end;
      if (strcmp(get(h(ii),'Type'),'uimenu') == 1)
         if (strcmp(get(h(ii),'Label'),'Text') == 1)
            TextHand=h(ii);
         end;   
      end;
   end;
   h=get(TextHand,'Children');
   for ii=1:length(h),
      if (strcmp(get(h(ii),'Label'),'Size') == 1)
         h_size=h(ii);
      end;
   end;
   set(h_size,'UserData','OFF');
   if (h_txt ~= -1),
      Txt=get(h_txt,'String');
      delete(h_txt);
      h_axes=gca;
      h=text('Parent',h_axes,'position',[0.0 0.0 0.1],'string',Txt,...
	      'HorizontalAlignment','center',...
              'color',[1 0 0],'Selected','on','FontName','Times',...
	      'Interpreter','none');
      set(h,'ButtonDownFcn','ShowImageTxtFcn(1)'); % Change txt
   else
      fprintf('No editable text object found\n');
   end;   
elseif (Inp == 1),
   % Change txt functions
   h = get(gcf,'userdata'); 
   for ii=1:length(h),
      if (strcmp(get(h(ii),'Type'),'uimenu') == 1)
         if (strcmp(get(h(ii),'Label'),'Text') == 1)
            TextHand=h(ii);
         end;   
      end;
   end;
   h=get(TextHand,'Children');
   for ii=1:length(h),
      if (strcmp(get(h(ii),'Label'),'Size') == 1)
         h_size=h(ii);
      end;
      if (strcmp(get(h(ii),'Label'),'Font') == 1)
         h_font=h(ii);
      end;
      if (strcmp(get(h(ii),'Label'),'Color') == 1)
         h_color=h(ii);
      end;
   end;
   SizeUserData=get(h_size,'UserData');
   FontUserData=get(h_font,'UserData');
   ColorUserData=get(h_color,'UserData');
   if (strcmp(SizeUserData,'OFF') == 1)
      set(gcf,'WindowButtonMotionFcn',...
           'pos=get(gca,''CurrentPoint'');set(gco,''Position'',[pos(1,1:2) 0.1]);');
      set(gcf,'WindowButtonUpFcn',...
           'set(gcf,''WindowButtonMotionFcn'','''')');
      set(gco,'Color',ColorUserData);
      set(gco,'Selected','off');
   elseif (strcmp(SizeUserData,'DELETE') == 1)
      delete(gco);
   elseif (strcmp(SizeUserData,'FONT') == 1)
      if (strcmp(FontUserData,'Helvetica') == 1)
         set(gco,'FontName','Helvetica');
      elseif (strcmp(FontUserData,'Times') == 1)
         set(gco,'FontName','Times');
      elseif (strcmp(FontUserData,'Courier') == 1)
         set(gco,'FontName','Courier');
      elseif (strcmp(FontUserData,'Symbol') == 1)
         set(gco,'FontName','Symbol');
      end;   
   elseif (strcmp(SizeUserData,'COLOR') == 1)
      if (strcmp(ColorUserData,'white') == 1)
         set(gco,'Color','white');
      elseif (strcmp(ColorUserData,'red') == 1)
         set(gco,'Color','red');
      elseif (strcmp(ColorUserData,'yellow') == 1)
         set(gco,'Color','yellow');
      elseif (strcmp(ColorUserData,'green') == 1)
         set(gco,'Color','green');
      elseif (strcmp(ColorUserData,'blue') == 1)
         set(gco,'Color','blue');
      end   
   else
      ptrComma=strfind(SizeUserData,',');
      ValStr=SizeUserData(ptrComma+1:length(SizeUserData));
      Value=str2num(ValStr);
      set(gco,'FontSize',Value');
   end; 
elseif (Inp == 2),
   % Change txt size functions
   h=get(gcf,'Children');
   h_txt=-1;
   for ii=1:length(h),
      if (isstr(get(h(ii),'UserData')) == 1) &...
	    (strcmp(get(h(ii),'UserData'),'h_SizeTxt') == 1),
         h_txt = h(ii);
      end;
      if (strcmp(get(h(ii),'Type'),'uimenu') == 1)
         if (strcmp(get(h(ii),'Label'),'Text') == 1)
            TextHand=h(ii);
         end;   
      end;
   end;
   h=get(TextHand,'Children');
   for ii=1:length(h),
      if (strcmp(get(h(ii),'Label'),'Size') == 1)
         h_size=h(ii);
      end;
   end;
   if (h_txt ~= -1),
      Txt=get(h_txt,'String');
      delete(h_txt);
      Txt=['ON,' Txt];
      set(h_size,'UserData',Txt);
   else
      fprintf('No size object found\n');
   end;   
end;     
