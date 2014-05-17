function CrossMove
% Reposition the 'crosshair' of Slice3 alignment window
  
  ud=get(gcbf,'userdata');
  ax=findobj(gcbf,'type','axes');
  oldcross=findobj(gcbf,'tag','Cross');
  newpoint=get(ax,'currentpoint');
  newpoint=newpoint(1,1:2);
  ud.centre=newpoint;
  xl=get(ax,'xlim');
  yl=get(ax,'ylim');
  h=plot(xl,[ud.centre(2) ud.centre(2)],'g:','linewidth',2,'tag','Cross');
  threscolor=get(oldcross(1),'color');
  set(h,'color',threscolor)
  h=plot([ud.centre(1) ud.centre(1)],yl,'g:','linewidth',2,'tag','Cross');
  set(h,'color',threscolor)
  delete(oldcross);
  set(gcbf,'userdata',ud);