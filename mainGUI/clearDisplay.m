function clearDisplay(h_display,data)
%____Delete show buttons
delete(findobj('tag','nextbutShow'));
delete(findobj('tag','prevbutShow'));
delete(findobj('tag','outofShow'));
delete(findobj('tag','infotxtShow'));


%____Creates axes for Display frame to show
set(h_display,...
     'Tag','Result',...
     'position',[data.leftframewidth+25 133 data.rightframewidth-40 data.figuresize(4)-186],...
     'units','pixels',...
     'Box','on',...
     'TickLength',[0 0],...
     'XTick',[],...
     'YTick',[],...
     'LineWidth',1.5,...
     'color',[252/255 252/255 254/255]);
 
 %____Clean and remove axes
axes(h_display);
cla, axis(h_display,'off');

return