function ZoomClick(tag)
% Axis Click callback for zoom functionality in Slice3
  ax=get(gcbo,'parent');
  point=get(ax,'currentpoint');
  obj=findobj('tag',tag,'parent',ax);
  if isobj(obj)
    set(obj,'xdata',point(1,1),'ydata',point(1,2));
  end