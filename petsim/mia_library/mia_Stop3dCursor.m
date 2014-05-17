function mia_Stop3dCursor()
%
% destroy the 3 figures showing the 3 perpendicular slices
%
% Matlab library function for mia_gui utility. 
% DEOEC PET Center/LB 2003

figureHandle = gcbo;
FigDataIn = get(figureHandle,'Userdata');

if strcmp(get(figureHandle,'name'),'Axial slice');
    if ishandle(FigDataIn.FigHandlerX); delete(FigDataIn.FigHandlerX); end
    if ishandle(FigDataIn.FigHandlerY); delete(FigDataIn.FigHandlerY); end
elseif strcmp(get(figureHandle,'name'),'Coronal slice');
    if ishandle(FigDataIn.FigHandlerY); delete(FigDataIn.FigHandlerY); end
    if ishandle(FigDataIn.FigHandlerZ); delete(FigDataIn.FigHandlerZ); end
elseif strcmp(get(figureHandle,'name'),'Sagital slice');
    if ishandle(FigDataIn.FigHandlerZ); delete(FigDataIn.FigHandlerZ); end
    if ishandle(FigDataIn.FigHandlerY); delete(FigDataIn.FigHandlerY); end
end

figh = findobj('tag','mia_figure1');
if isempty(figh); return;end

handles = guidata(figh);
%handles = rmfield(handles,'D3CursorFigData');
set(handles.ThreeDcursortogglebutton,'value',0);

% save the guidata
guidata(figh,handles);