%method configurator, simple example 
function configurator(string,item)
color=[214/255 211/255 206/255];
figuresize=get(0,'ScreenSize');       %returns for example [1 1 1024 768]    
fig=figure('units','pixels','position',[figuresize(3)/2-200 figuresize(4)/2-200 400 400],'MenuBar','none','NumberTitle','off','Name',['Options: ' string ' ' item],'Color',color);
set(fig,'Resize','off');  %must be set after creation of figure, otherwise older versions of matlab may get confused
uicontrol('style','frame','units','pixels','position',[15 50 375 340],'BackgroundColor',color);                             %progressframe
uicontrol('style','text','units','pixels','position',[20 378 95 20],'String','Preprocessing','BackgroundColor',color);      %progressframe title
uicontrol('parent',fig,'style','text','units','pixels','position',[30 320 300 40],'HorizontalAlignment','left','BackgroundColor',color,'Tag','configuratortext','string','This example shows options design');    
 
%some UIcontrols to show example
uicontrol('parent',fig,'style','radiobutton','units','pixels','position',[30 280 200 40],'HorizontalAlignment','left','BackgroundColor',color,'string','Echo on');    
uicontrol('parent',fig,'style','radiobutton','units','pixels','position',[30 240 200 40],'HorizontalAlignment','left','BackgroundColor',color,'string','Warp lines' );    
uicontrol('parent',fig,'style','radiobutton','units','pixels','position',[30 200 200 40],'HorizontalAlignment','left','BackgroundColor',color,'string','Limit matrix width');    
 
uicontrol('parent',gcf,'style','pushbutton','units','pixels','position',[15 15 95 25],'HorizontalAlignment','left','string','Load defaults','Callback',{@UIbuttonDefault_callback});    
uicontrol('parent',gcf,'style','pushbutton','units','pixels','position',[260 15 60 25],'HorizontalAlignment','left','string','Apply','Callback',{@UIbuttonApply_callback});    
uicontrol('parent',gcf,'style','pushbutton','units','pixels','position',[330 15 60 25],'HorizontalAlignment','left','string','Cancel','Callback',{@UIbuttonApply_callback});    

%--------------------------------------------------------------------
function UIbuttonApply_callback(h, eventdata, handles, varargin)      
delete(gcf);

%--------------------------------------------------------------------
function UIbuttonDefault_callback(h, eventdata, handles, varargin)      


