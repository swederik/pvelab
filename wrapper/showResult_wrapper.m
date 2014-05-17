function project=showResult_wrapper(project,TaskIndex,MethodIndex,varargin)
% showResult_Wrapper function is a wrapper that show results in the display window
%   when the SHOW buttom is pressed. Images are given in 'project.taskDone{TaskIndex}.show{imageIndex,ModalityIndex}'
%   If more than one image exist the Display window is splited up in sub images.
%
%   NOTE: If inpufiles==outfiles then inputfiles is shown!!
%
% Input:
%   project     : Structure containing all information of actual pipeline
%   TaskIndex   : Index to active task in the project structure
%   MethodIndex : Index to used method in a TaskIndex in the project structure
%   varargin    : Abitrary number of input arguments. (NOT USED)
%
% Output:
%   project     : Return updated project       
%
% Uses special functions:
%   logProject:
% ____________________________________________
% T. Dyrby and T. Rask, 250503, NRU
%SW version: 111103TD,TR

%If a special Task to be shown
if(~isempty(project.taskDone{TaskIndex}.command))       
    MethodIndex=project.taskDone{TaskIndex}.command{2};
    TaskIndex=project.taskDone{TaskIndex}.command{1};
end

%Below to easly solve a problem ...280303TD
if(length(MethodIndex)>1)
    MethodIndex=MethodIndex{1};
end

%____ initialise
noModalities=length(project.pipeline.imageModality);
ImageIndex=1;

%______ Check if task is done
if(project.pipeline.statusTask(TaskIndex)~=2) %2='DONE'
    project=logProject('Show results: Task not done.',project,TaskIndex,MethodIndex);
    return
end

%______ Check if handle to displayWin exist
if(~ishandle(project.handles.h_display))
    %_______ Log info
    project=logProject('No handle to displaywin.',project,TaskIndex,MethodIndex);    
    return
end

%________Create 2D show-image from generated analyzefiles in fields
%outputfiles and userdata and append to already existing show-files.

if ~isfield(project.taskDone{TaskIndex}.userdata,'showfilesCreated')
    project=logProject('Show: Creating 2D images from output files...',project,TaskIndex,MethodIndex);
    project=show_saveResult(project,TaskIndex,MethodIndex);    
    project=Updateproject(project,TaskIndex,MethodIndex);
    project.taskDone{TaskIndex}.userdata.showfilesCreated=true;
end

showNumber=0;
howbig=size(project.taskDone{TaskIndex}.show);
for (i=1:howbig(2))
    if ~isempty(project.taskDone{TaskIndex}.show{ImageIndex,i}.name)
        showNumber=showNumber+1;
    end
end

if ~showNumber, return, end;

%____________________Create show GUI_________________________

%%_____ Get display size and pos.    
iniPos=get(project.handles.h_display,'position');

%_____ set variables
if isunix
nextbutIm=imread('showNext.bmp');
prevbutIm=imread('showPrev.bmp');    
else
nextbutIm=imread('winshowNext.bmp');
prevbutIm=imread('winshowPrev.bmp');    
end

high=26;
leng=28;
color=[252/255 252/255 254/255];
showInf.nowShown=1;
showInf.noPics=showNumber;
showInf.files=project.taskDone{TaskIndex}.show;
showInf.h_display=project.handles.h_display;

infotxt = uicontrol('parent',project.handles.h_mainfig,...
    'Style', 'text',...
    'String', sprintf(['File: ',showInf.files{ImageIndex,showInf.nowShown}.name,' \n','Info: ',showInf.files{ImageIndex,showInf.nowShown}.info]),...
    'units','pixels',...
    'BackgroundColor',color,...
    'TooltipString',sprintf(['File: ',showInf.files{ImageIndex,showInf.nowShown}.name,' \n','Info: ',showInf.files{ImageIndex,showInf.nowShown}.info]),...
    'Position', [iniPos(1), iniPos(2)+iniPos(4)-high-10, iniPos(3)/2-62, high+5],...
    'fontweight','bold',...
    'horizontalalignment','left',...
    'tag','infotxtShow');
keepTextInBox(infotxt);


houtof = uicontrol('parent',project.handles.h_mainfig,...
    'Style', 'text',...
    'String', ['Page 1/',num2str(showNumber)],...
    'units','pixels',...
    'BackgroundColor',color,...
    'Position', [iniPos(1)+iniPos(3)-80, iniPos(2)+iniPos(4)-high-10, 80, high+5],...
    'fontweight','bold',...
    'horizontalalignment','left',...
    'userdata', showInf,...
    'tag','outofShow');

hprev = uicontrol('parent',project.handles.h_mainfig,...
    'Style', 'pushbutton',...
    'units','pixels',...
    'Position', [iniPos(1)+iniPos(3)/2-leng-2, iniPos(2)+iniPos(4)-high, leng, high],...
    'tag','prevbutShow',...
    'TooltipString','Previous result image',...
    'Callback', {@prevBut,houtof},...
    'cdata',prevbutIm);
axis image;

hnext= uicontrol('parent',project.handles.h_mainfig,...
    'Style', 'pushbutton',...
    'units','pixels',...
    'Position', [iniPos(1)+iniPos(3)/2+2, iniPos(2)+iniPos(4)-high, leng, high],...
    'tag','nextbutShow',...
    'TooltipString','Next result image',...
    'Callback', {@nextBut,houtof},...
    'cdata',nextbutIm);

if (showInf.nowShown==showInf.noPics), set(hnext,'enable','off');,end;
if (showInf.nowShown==1), set(hprev,'enable','off');,end;


%_____ set position etc. of display
set(project.handles.h_display,...
    'nextplot','replace',...
    'units','pixels',...
    'position',[iniPos(1), iniPos(2), iniPos(3), iniPos(4)-high-10]);
axis ij;

path=showInf.files{ImageIndex,showInf.nowShown}.path;
showFilename=fullfile('',path,showInf.files{ImageIndex,showInf.nowShown}.name);

if(exist(showFilename))      
    axes(project.handles.h_display);
    [X]= imread(showFilename);     
    image(X), colormap('default'); 
    axis(gca,'off'); %when nextplot is set to replace, axis style is reset every time a new image is drawn
    axis image;
end      

%==========================Callback functions============================
function nextBut(h_object,event,h_infostore)
showInf=get(h_infostore,'userdata');
showInf.nowShown=showInf.nowShown+1; %take next pic

%_____ get image path
path=showInf.files{1,showInf.nowShown}.path;
showFilename=fullfile('',path,showInf.files{1,showInf.nowShown}.name);

%_____ show image if exists
if(exist(showFilename))
    %_____ select display as current axes
    axes(showInf.h_display);
    
    [X]= imread(showFilename);     
    image(X), colormap('default');     
    axis(gca,'off'); %when nextplot is set to replace, axis style is reset every time a new image is drawn
    axis image;
end

%____ Set enable for buttons
if (showInf.nowShown==showInf.noPics)
    set(h_object,'enable','off');
else
    set(h_object,'enable','on'); 
end
set(findobj('tag','prevbutShow'),'enable','on');

%_____ set text
set(h_infostore,'userdata',showInf,'string',['Page ',num2str(showInf.nowShown),'/',num2str(showInf.noPics)]);
stri=sprintf(['File: ',showInf.files{1,showInf.nowShown}.name,' \n','Info: ',showInf.files{1,showInf.nowShown}.info]);
set(findobj('tag','infotxtShow'),...
    'String',stri,...
    'TooltipString',stri);
keepTextInBox(findobj('tag','infotxtShow'));

return

%________________________Previous___________________________
function prevBut(h_object,event,h_infostore)
showInf=get(h_infostore,'userdata');
showInf.nowShown=showInf.nowShown-1; %take previous pic

%_____ get image path
path=showInf.files{1,showInf.nowShown}.path;
showFilename=fullfile('',path,showInf.files{1,showInf.nowShown}.name);

%_____ show image if exists
if(exist(showFilename))         
    %_____ select display as current axes
    axes(showInf.h_display);
    
    [X]= imread(showFilename);     
    image(X), colormap('default'); 
    axis(gca,'off'); %when nextplot is set to replace, axis style is reset every time a new image is drawn
    axis image;
end

%____ Set enable for buttons
if (showInf.nowShown==1)
    set(h_object,'enable','off');
else
    set(h_object,'enable','on'); 
end
set(findobj('tag','nextbutShow'),'enable','on');


%_____ set text
set(h_infostore,'userdata',showInf,'string',['Page ',num2str(showInf.nowShown),'/',num2str(showInf.noPics)]);
stri=sprintf(['File: ',showInf.files{1,showInf.nowShown}.name,' \n','Info: ',showInf.files{1,showInf.nowShown}.info]);
set(findobj('tag','infotxtShow'),...
    'visible','off',...
    'String',stri,...
    'TooltipString',stri);
keepTextInBox(findobj('tag','infotxtShow'));

return


%_______________________keepTextInBox______________________

function keepTextInBox(h)
theText=get(h,'string');
s1=theText(1,:);
s2=theText(2,:);
le=length(s1);
for num=1:le
    txtWidth=get(h,'extent');
    fieldWidth=get(h,'position');
    if (txtWidth(3)>fieldWidth(3))
        le=le-1;
        s1=s1(1:(le));
        s2=s2(1:(le));
    else
        if num==1, break; end
        if ~strcmp(s1((le-3):le),'    ')
            s1=[s1(1:(le-3)),'...'];
        end
        if ~strcmp(s2((le-3):le),'    ')
            s2=[s2(1:(le-3)),'...'];
        end
        set(h,'string',sprintf([s1,'\n',s2]));
        break;
    end
    set(h,'string',sprintf([s1,'\n',s2]));
end
set(h,'visible','on');
