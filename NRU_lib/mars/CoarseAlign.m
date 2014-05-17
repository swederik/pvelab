function CoarseAlign(arg1);
% Returns an A matrix to Coreg
  ud=get(gcbf,'userdata');
  %set(gcbf,'closerequestfcn','closereq')
  delete(gcbf);
  if nargin==1
    ud.A=diag([1 1 1 1]);
  end
  Slice3('CoarseAlign',ud.parent,ud.A)
  