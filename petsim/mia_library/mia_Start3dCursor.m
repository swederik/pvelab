function FigDataIn = mia_Start3dCursor(imaVOLin,pixsize,colormaptype,minpix, maxpix)
% function FigDataIn = mia_Start3dCursor(imaVOLin,pixsize,colormaptype,minpix, maxpix)
%
% Setup 3 figures showing the 3 orthogonal slices
%
% Matlab library function for mia_gui utility. 
% DEOEC PET Center/LB 2002


scrsz = get(0,'ScreenSize');
X0=round(size(imaVOLin,1)/2);Y0=round(size(imaVOLin,2)/2);Z0=round(size(imaVOLin,3)/2);
%FigHandlerZ = figure('position',[100 200 imzoom*size(imaVOLin,1)*pixsize(1) imzoom*size(imaVOLin,2)*pixsize(2)]);
PlotLeft =  scrsz(3)/32; PlotBottom =  scrsz(4)/4;
PlotHeight = scrsz(4)/2;
PlotBAspectRatio = [size(imaVOLin,2)*pixsize(2) size(imaVOLin,1)*pixsize(1) 1];
PlotWidth = PlotHeight*PlotBAspectRatio(1)/PlotBAspectRatio(2); 
FigHandlerZ = figure('position',[PlotLeft PlotBottom PlotWidth PlotHeight], ...
    'menubar','none','NumberTitle','off','name','Axial slice',...
    'DeleteFcn','mia_Stop3dCursor','doubleBuffer','on');

map = colormap(colormaptype);
ImaHandlerZ = imagesc(imaVOLin(:,:,Z0),[minpix maxpix]);
axesHandleZ = get(ImaHandlerZ, 'Parent');
set(axesHandleZ,'PlotBoxAspectRatio',PlotBAspectRatio);
axis off;
%colorbar;
%pause(1);


PlotBAspectRatio = [size(imaVOLin,2)*pixsize(2) size(imaVOLin,3)*pixsize(3) 1];
%PlotLeft =  scrsz(3)/3; PlotBottom =  scrsz(4)/8;
PlotLeft =  PlotLeft + PlotWidth; PlotBottom =  scrsz(4)/8;
PlotWidth = PlotHeight*PlotBAspectRatio(1)/PlotBAspectRatio(2);
% if the imaVOL contains WB investigation the Coronal and Saggital figures size
% need to reduce
if PlotLeft + PlotWidth > scrsz(4)
    PlotHeight = PlotHeight/2;
    PlotWidth = PlotHeight*PlotBAspectRatio(1)/PlotBAspectRatio(2);
    WidthFactor = 1;
else
    WidthFactor = 1.5;
end
FigHandlerY = figure('position',[PlotLeft PlotBottom  PlotWidth PlotHeight] , ...
    'menubar','none','NumberTitle','off','name','Coronal slice', ...
    'DeleteFcn','mia_Stop3dCursor','doubleBuffer','on');

map = colormap(colormaptype);
%ImaHandlerY = imagesc(rot90(squeeze(imaVOLin(:,Y0,:))));
ImaHandlerY = imagesc(rot90(squeeze(imaVOLin(Y0,:,:))),[minpix maxpix]);
axesHandleY = get(ImaHandlerY, 'Parent');
set(axesHandleY,'PlotBoxAspectRatio',PlotBAspectRatio);
% set wider the figure to fit the mia_Xpixval plotting
FigPos = get(FigHandlerY,'position'); 
set(FigHandlerY,'position',[FigPos(1) FigPos(2) FigPos(3)*WidthFactor FigPos(4)]); 
%colorbar;
%pause(1);
axis off;

PlotBAspectRatio = [size(imaVOLin,1)*pixsize(1) size(imaVOLin,3)*pixsize(3) 1];
%PlotLeft =  scrsz(3)/2; PlotBottom =  scrsz(4)/2;
PlotLeft = PlotLeft + PlotWidth; PlotBottom =  scrsz(4)/4;
PlotWidth = PlotHeight*PlotBAspectRatio(1)/PlotBAspectRatio(2);
if PlotLeft + PlotWidth > scrsz(4)
    PlotLeft = scrsz(3) - 1.5*PlotWidth;
    PlotBottom =  scrsz(4) - 1.5*PlotHeight;
end
FigHandlerX = figure('position',[PlotLeft PlotBottom PlotWidth PlotHeight], ...
    'menubar','none','NumberTitle','off','name','Sagital slice', ...
    'DeleteFcn','mia_Stop3dCursor','doubleBuffer','on');
map = colormap(colormaptype);
%ImaHandlerX = imagesc(rot90(squeeze(imaVOLin(X0,:,:))));
ImaHandlerX = imagesc(rot90(squeeze(imaVOLin(:,X0,:))),[minpix maxpix]);

axesHandleX = get(ImaHandlerX, 'Parent');
set(axesHandleX,'PlotBoxAspectRatio',PlotBAspectRatio);
% set wider the figure to fit the mia_Xpixval plotting

FigPos = get(FigHandlerX,'position'); 
set(FigHandlerX,'position',[FigPos(1) FigPos(2) FigPos(3)*WidthFactor FigPos(4)]); 
%colorbar;
axis off;

set(ImaHandlerX,'EraseMode','none');
set(ImaHandlerY,'EraseMode','none');
set(ImaHandlerZ,'EraseMode','none');
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
mia_Xpixval(FigHandlerX,'on');
mia_Ypixval(FigHandlerY,'on');
mia_Zpixval(FigHandlerZ,'on');
%
%draw the positioning line
%
axesHandleX = get(FigDataIn.ImaHandlerX, 'Parent');
axesHandleY = get(FigDataIn.ImaHandlerY, 'Parent');
axesHandleZ = get(FigDataIn.ImaHandlerZ, 'Parent');
Xyrange = get(axesHandleX,'Ylim');
Xxrange = get(axesHandleX,'Xlim');
Yyrange = get(axesHandleY,'Ylim');
Yxrange = get(axesHandleY,'Xlim');
Zyrange = get(axesHandleZ,'Ylim');
Zxrange = get(axesHandleZ,'Xlim');
LineWidthCur = 2;
%lines in saggital slice
ImVolume.Xxline=line('Parent', axesHandleX,'color', [0 1 1],'EraseMode','xor', ....
    'LineWidth',LineWidthCur,'Xdata',[ImVolume.Y ImVolume.Y],'Ydata',[0 Yxrange(2)], ...
    'ButtonDownFcn','mia_Xpixval(''ButtonDownOnImage'')');
ImVolume.Xyline=line('Parent', axesHandleX,'color', [0 1 1],'EraseMode','xor', ...
    'LineWidth',LineWidthCur,'Xdata',[0 Xxrange(2)],'Ydata', [ImVolume.Z ImVolume.Z], ...
    'ButtonDownFcn','mia_Xpixval(''ButtonDownOnImage'')');

%lines in axial slice
ImVolume.Zxline=line('Parent', axesHandleZ,'color', [0 1 1],'EraseMode','xor', ....
    'LineWidth',LineWidthCur,'Xdata',[ImVolume.X ImVolume.X],'Ydata',[0 Zyrange(2)], ...
    'ButtonDownFcn','mia_Zpixval(''ButtonDownOnImage'')');
ImVolume.Zyline=line('Parent', axesHandleZ,'color', [0 1 1],'EraseMode','xor', ...
    'LineWidth',LineWidthCur,'Xdata',[0 Zxrange(2)],'Ydata', [ImVolume.Y ImVolume.Y], ...
    'ButtonDownFcn','mia_Zpixval(''ButtonDownOnImage'')');

%lines in coronal slice
ImVolume.Yxline=line('Parent', axesHandleY,'color', [0 1 1],'EraseMode','xor', ....
    'LineWidth',LineWidthCur,'Xdata',[ImVolume.X ImVolume.X],'Ydata',[0 Xxrange(2)], ...
    'ButtonDownFcn','mia_Ypixval(''ButtonDownOnImage'')');
ImVolume.Yyline=line('Parent', axesHandleY,'color', [0 1 1],'EraseMode','xor', ...
    'LineWidth',LineWidthCur,'Xdata',[0 Xxrange(2)],'Ydata', [ImVolume.Z ImVolume.Z], ...
    'ButtonDownFcn','mia_Ypixval(''ButtonDownOnImage'')');

set(FigDataIn.ImaHandlerX,'UserData',ImVolume);


 