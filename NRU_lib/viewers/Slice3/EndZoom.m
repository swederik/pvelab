function EndZoom
% Ends the zoom mode of Slice3
  
  Kiddata=get(gcbf,'userdata');
  Daddata=get(Kiddata.Daddy,'userdata');
  x=get(findobj(gcbf,'tag','cursor'),'xdata');
  y=get(findobj(gcbf,'tag','cursor'),'ydata');
  coords=zeros(3,1);
  set(gcbf,'closerequestfcn','closereq');
  delete(gcbf);
  if Kiddata.locked==1
    coords(1)=x;
    coords(2)=y;
    coords(3)=Daddata.coords(3);
  elseif Kiddata.locked==2
    coords(1)=x;
    coords(2)=Daddata.coords(2);
    coords(3)=y;
  elseif Kiddata.locked==3
    coords(1)=Daddata.coords(1);
    coords(2)=x;
    coords(3)=y;
  end
  Daddata.coords=coords;
  Kiddata.coords=coords;
  coords=inv(Daddata.Transform)*[reshape(coords,3,1);1];
  coords=coords(1:3);
  set(gcbf,'userdata',Kiddata);
  if isfield(Daddata,'project')
    Slice3('UpdatePoint',Kiddata.Daddy,coords,Daddata.project);
  else
    Slice3('UpdatePoint',Kiddata.Daddy,coords);
  end
  figure(Kiddata.Daddy);
  