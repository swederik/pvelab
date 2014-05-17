function FigDataIn = Start3dCursor(imaVOLin,pixsize,colormaptype)
%
% setup the 3 figures showing the 3 perpendicular slices
%
imzoom = 1.5;
X0=round(size(imaVOLin,1)/2);Y0=round(size(imaVOLin,2)/2);Z0=round(size(imaVOLin,3)/2);
FigHandlerZ = figure('position',[100 200 imzoom*size(imaVOLin,1)*pixsize(1) imzoom*size(imaVOLin,2)*pixsize(2)]);
map = colormap(colormaptype);
if strcmp(colormaptype,'gray') 
    ImaHandlerZ = imshow(imaVOLin(:,:,Z0),'notruesize');
else
    ImaHandlerZ = imagesc(imaVOLin(:,:,Z0));
end
axesHandleZ = get(ImaHandlerZ, 'Parent');
set(axesHandleZ,'PlotBoxAspectRatio',[size(imaVOLin,1)*pixsize(1) size(imaVOLin,2)*pixsize(2) 1]);
colorbar;

FigHandlerY = figure('position',[500 200 imzoom*size(imaVOLin,1)*pixsize(1) imzoom*size(imaVOLin,3)*pixsize(3)]);
map = colormap(colormaptype);
if strcmp(colormaptype,'gray') 
    ImaHandlerY  = imshow(rot90(squeeze(imaVOLin(:,Y0,:))),'notruesize');
    axesHandleY = get(ImaHandlerY, 'Parent');
    set(axesHandleY,'DataAspectRatio',[pixsize(3) pixsize(1)  1]);
else
    ImaHandlerY = imagesc(rot90(squeeze(imaVOLin(:,Y0,:))));
    axesHandleY = get(ImaHandlerY, 'Parent');
    set(axesHandleY,'PlotBoxAspectRatio',[size(imaVOLin,1)*pixsize(1) size(imaVOLin,3)*pixsize(3)   1]);
end

colorbar;

FigHandlerX = figure('position',[600 100 imzoom*size(imaVOLin,2)*pixsize(2) imzoom*size(imaVOLin,3)*pixsize(3)]);
map = colormap(colormaptype);
if strcmp(colormaptype,'gray') 
    ImaHandlerX  = imshow(rot90(squeeze(imaVOLin(X0,:,:))),'notruesize');
    axesHandleX = get(ImaHandlerX, 'Parent');
    set(axesHandleX,'DataAspectRatio',[pixsize(3) pixsize(2)  1]);
else
    ImaHandlerX = imagesc(rot90(squeeze(imaVOLin(X0,:,:))));
    axesHandleX = get(ImaHandlerX, 'Parent');
set(axesHandleX,'PlotBoxAspectRatio',[ size(imaVOLin,2)*pixsize(2) size(imaVOLin,3)*pixsize(3)  1]);
end
colorbar;

set(ImaHandlerX,'EraseMode','xor');
set(ImaHandlerY,'EraseMode','xor');
set(ImaHandlerZ,'EraseMode','xor');
set(FigHandlerX,'name','Coronal slice');
set(FigHandlerY,'name','Sagital slice');
set(FigHandlerZ,'name','Axial slice');
FigDataIn.ImaHandlerX = ImaHandlerX;
FigDataIn.ImaHandlerY = ImaHandlerY;
FigDataIn.ImaHandlerZ = ImaHandlerZ;
FigDataIn.FigHandlerX = FigHandlerX;
FigDataIn.FigHandlerY = FigHandlerY;
FigDataIn.FigHandlerZ = FigHandlerZ;
FigDataIn.CData = imaVOLin;
ImVolume.X=X0;
ImVolume.Y=Y0;
ImVolume.Z=Z0;
ImVolume.Xxline='';
ImVolume.Xyline='';
ImVolume.Yxline='';
ImVolume.Yyline='';
ImVolume.Zxline='';
ImVolume.Zyline='';
ImVolume.PixInt=imaVOLin(X0,Y0,Z0);
set(FigHandlerZ,'userdata',FigDataIn);
set(FigHandlerY,'userdata',FigDataIn);
set(FigHandlerX,'userdata',FigDataIn);
set(ImaHandlerX,'userdata',ImVolume);
Xpixval(FigHandlerX,'on');
Ypixval(FigHandlerY,'on');
Zpixval(FigHandlerZ,'on');
%
%draw the positioning line
%
axesHandleX = get(FigDataIn.ImaHandlerX, 'Parent');
axesHandleY = get(FigDataIn.ImaHandlerY, 'Parent');
axesHandleZ = get(FigDataIn.ImaHandlerZ, 'Parent');
Xxrange = get(axesHandleX,'Ylim');
Xyrange = get(axesHandleX,'Xlim');
Yxrange = get(axesHandleY,'Ylim');
Yyrange = get(axesHandleY,'Xlim');
Zyrange = get(axesHandleZ,'Ylim');
Zxrange = get(axesHandleZ,'Xlim');
LineWidthCur = 3;
%lines in saggital slice
ImVolume.Xxline=line('Parent', axesHandleX,'color', [0 1 1],'EraseMode','xor', ....
    'LineWidth',LineWidthCur,'Xdata',[0 Xyrange(2)],'Ydata',[ImVolume.Z ImVolume.Z]);
ImVolume.Xyline=line('Parent', axesHandleX,'color', [0 1 1],'EraseMode','xor', ...
    'LineWidth',LineWidthCur,'Xdata',[ImVolume.Y ImVolume.Y],'Ydata', [0 Xxrange(2)]);
%lines in axial slice
ImVolume.Zxline=line('Parent', axesHandleZ,'color', [0 1 1],'EraseMode','xor', ....
    'LineWidth',LineWidthCur,'Xdata',[ImVolume.X ImVolume.X],'Ydata',[0 Zyrange(2)]);
ImVolume.Zyline=line('Parent', axesHandleZ,'color', [0 1 1],'EraseMode','xor', ...
    'LineWidth',LineWidthCur,'Xdata',[0 Zxrange(2)],'Ydata', [ImVolume.Y ImVolume.Y]);
set(FigDataIn.ImaHandlerX,'UserData',ImVolume);
%lines in coronal slice
ImVolume.Yxline=line('Parent', axesHandleY,'color', [0 1 1],'EraseMode','xor', ....
    'LineWidth',LineWidthCur,'Xdata',[0 Yyrange(2)],'Ydata',[ImVolume.Z ImVolume.Z]);
ImVolume.Yyline=line('Parent', axesHandleY,'color', [0 1 1],'EraseMode','xor', ...
    'LineWidth',LineWidthCur,'Xdata',[ImVolume.X ImVolume.X],'Ydata', [0 Yxrange(2)]);
set(FigDataIn.ImaHandlerX,'UserData',ImVolume);

 