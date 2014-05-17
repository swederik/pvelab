function CheckKey_Slice3(tag)
% 
% Key-input checking callback for Slice3
%

  c=findobj(gcbf,'tag',tag);
  Char=get(gcbo,'CurrentKey');
  userdat=get(gcbf,'userdata');
  step=userdat.TransStep;
  if strcmp(Char,'add')
    step=step*2;
    userdat.TransStep=step;
  elseif strcmp(Char,'subtract')
    step=step/2;  
    userdat.TransStep=step;
  elseif strcmp(Char,'x');
    delete(gcbf);
  else
    for j=1:length(c)
      x=get(c(j),'xdata');
      y=get(c(j),'ydata');
      if not(isempty(Char))
	switch Char
	 case 'leftarrow'
	  x=x-step;
	  set(c(j),'xdata',x,'ydata',y)
	 case 'rightarrow'
	  x=x+step;
	  set(c(j),'xdata',x,'ydata',y)
	 case 'uparrow'
	  y=y+step;
	  set(c(j),'xdata',x,'ydata',y)
	 case 'downarrow'
	  y=y-step;
	  set(c(j),'xdata',x,'ydata',y)
	end
      end
    end
  end
  set(gcbf,'userdata',userdat);
 
  
  