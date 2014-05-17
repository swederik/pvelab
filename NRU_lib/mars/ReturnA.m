function ReturnA;
% Returns an homogenous transformation matrix to Coreg
  
  ud=get(gcbf,'userdata');
  %set(gcbf,'closerequestfcn','closereq')
  delete(gcbf);
  Coreg('ReturnA',ud.A,ud.TransStep,ud.AngStep)
  