function []=ShowImageColorbarFcn(Inp)
%
%
if (nargin ~= 1),
   fprintf('ShowImageColorbarFcn is called without argument\n');
   exit(1);
end;
%
if ((Inp == 1) | (Inp == 2)),
   % Min/max value changed
   h=get(gcf,'Children');
   h_colorbar=-1;
   for ii=1:length(h),
      if (isstr(get(h(ii),'UserData')) == 1) &...
            (strcmp(get(h(ii),'UserData'),'ColorbarVal') == 1),
         h_colorbar = h(ii);
      end;   
   end;
   
   if (h_colorbar ~= -1),
      LimValueTxt=get(h_colorbar,'String');
      
      PosProc=strfind(LimValueTxt,'%');
      if (length(PosProc) ~= 0)
	 ProcChange=1;
	 for k=1:length(PosProc)
	    LimValueTxt(PosProc(k))=' ';
	 end;   
      else
	 ProcChange=0;
      end; 
      
      LimValue=str2num(LimValueTxt);
      delete(h_colorbar);
   
      Limits=get(gca,'CLim');

      %aendring af limits i user_data
      if (Inp == 2)
	 if (ProcChange == 1)
	    Limits(1)=Limits(1)*LimValue/100;
	 else
            Limits(1) = LimValue;
	 end;
      else
	 if (ProcChange == 1)
	    Limits(2)=Limits(2)*LimValue/100;
	 else
            Limits(2) = LimValue;
	 end;
      end;
      set(gca,'CLim',Limits);
      colorbar
      
   end; 
     
end;     
