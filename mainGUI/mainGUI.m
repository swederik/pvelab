function project = mainGUI(project,TaskIndex,varargin) 
% mainGUI function that setup the GUI (userinterface) for
%   the pipeline program w. respect to the project.
%
% Input:
%   project     : Structure containing all information of actual pipeline
%   TaskIndex   : Index to active task in the project structure
%   varargin    : Abitrary number of input arguments. (NOT USED)
%
%                   ***************** test with figure at startup *********************
% Output:
%   project     : Return updated project       
%
% Uses special functions:
%   welcomeGUI
%   drawGUI
%   taskGUI
%   menuGUI
%____________________________________________
% M. Twadark and T. Dyrby, 010503, NRU
%SW version: 010603TD

%_____ Init main figure window-------------------, gray window color is 214/255 211/255 206/255 in 2000, 236/255 233/255 216/255 in winXP.
% New mainGUI the set the first task selecteble
if(isempty(TaskIndex))
    TaskIndex=1;
end

%____ If mainGUI exist
if(ishandle(project.handles.h_mainfig))
    h_mainfig=project.handles.h_mainfig;
    %Check if only do updata mainGUI
    if(findobj('tag','mainGUI')==h_mainfig)
        
        %____Update project by storing in mainGUI        
        set(h_mainfig,'UserData',project)
        
        drawGUI(h_mainfig,TaskIndex);         
        taskGUI(h_mainfig,TaskIndex);
        return
    end
else
    set(0,'Visible','off');
    project.handles.h_mainfig=figure('Visible','off');
    set(project.handles.h_mainfig,'off');
    h_mainfig=project.handles.h_mainfig;    
end

set(h_mainfig,'NumberTitle','off','Color',[192/255 192/255 192/255],'MenuBar','none','NextPlot','add','tag','mainGUI',...
    'Name',project.pipeline.taskSetup{end,1}.method_name,'Visible','off');  %'add' (default) 'replace' causes handle error

%___Importent to flush graphic
drawnow %michael: is it here?

%___ Set init. size of mainGUI
set(0,'Units','pixels');                %set this to be sure of units
set(0,'fixedwidthfontname','Helvetica');%set default font to courier Helvetica
resolution=get(0,'ScreenSize');         %returns [1 1 1024 768]
width=900;,heigth=600;                  %to make main window at startup approx 800x600
if resolution(3)>width
        Position(1)=(resolution(3)-width)/2;
        Position(3)=width;
else
        Position(1)=10;
        Position(3)=resolution(3)-20;
end
if resolution(4)>heigth
        Position(2)=(resolution(4)-heigth)/2;
        Position(4)=heigth;
    else
        Position(2)=40;
        Position(4)=resolution(4)-80;
    end
set(h_mainfig,'Position',Position);


%____ Make menus
menuGUI(project);
% Set callback fucntion because of subfunction: @Figure_CloseRequestFcn
set(findobj('tag','menuGUI_quit'),'Callback',{@Figure_CloseRequestFcn});


%____ Define size of frames and save settings 
figuresize=get(h_mainfig,'position');       %returns position & size [x y 400 300] 
leftframewidth=200;                   %left frame width is fixed, the right frame and bottom frame are resized to fit the figure
rightframewidth=figuresize(3)-leftframewidth-20; 

margen=5;                              %margen used in figure
buttonsize(1)=120;                     %buttonsize x stored in structure later, also specify in resize.m  
buttonsize(2)=24;                      %buttonsize y 
textsize=10;                           %'Fontsize' of all text and UIcontrols


%_____ Save infor of mainGUI
data.leftframewidth=leftframewidth;              
data.rightframewidth=rightframewidth;
data.figuresize=figuresize;
data.margen=margen;                             %margen used in figure
data.buttonsize=buttonsize;                     %buttonsize x stored in structure later, also specify in resize.m  
data.textsize=textsize;                         %fontsize
data.SelectedTaskIndexGUI=TaskIndex;

%____ Load images for fanestats into project structure (save load time)
data.faneSelectedNormal=imread('faneSelectedNormal.bmp');
data.faneSelectedNext=imread('faneSelectedNext.bmp');
data.faneSelectedOK=imread('faneSelectedOK.bmp');
data.faneSelectedError=imread('faneSelectedError.bmp');
     
data.fanePassiveNormal=imread('fanePassiveNormal.bmp');
data.fanePassiveNext=imread('fanePassiveNext.bmp');
data.fanePassiveOK=imread('fanePassiveOK.bmp');
data.fanePassiveError=imread('fanePassiveError.bmp');

data.runButton_unix=imread('run_unix.bmp');
data.optionButton_unix=imread('options_unix.bmp');
data.showButton_unix=imread('show_unix.bmp');
data.detailsButton_unix=imread('details_unix.bmp');
data.runButton_win=imread('run_win.bmp');
data.optionButton_win=imread('options_win.bmp');
data.showButton_win=imread('show_win.bmp');
data.detailsButton_win=imread('details_win.bmp');


%____ Init the axes field, which appears to contain the UIcontrols
if(isempty(findobj('Tag','windowX')))
    axes('CreateFcn',{@windowX_CreateFcn, figuresize, buttonsize, margen},'Tag','windowX');
end

%____ Create a (fane)button for each task in the project
[NoTasks,NoMethods]=size(project.pipeline.taskSetup);
stringbutton=[];
for(i=1:NoTasks-2)

    if(strcmp(lower(project.pipeline.taskSetup{i,1}.task),'others'))
        continue
    end
    stringbutton{i}=project.pipeline.taskSetup{i,1}.task;%Added 020603TD
    %%%str_length=length( stringbutton{i})
    %load bitmap der passer
    
    %Axes for Task 
    axeshandles(i)=axes; 
    set(axeshandles(i),'Units','pixels',...
        'position',[margen-1+(buttonsize(1)+2)*(i-1) -margen+figuresize(4)-buttonsize(2) buttonsize(1) buttonsize(2)],...
        'Tag',['axes_' num2str(i)]);

    imagehandles(i)=image(data.fanePassiveNormal);       %image1 shows passive button bitmap
    axis(gca,'off');
    
    %Text in Image of 
    texthandles(i)=text('String',stringbutton(i));
    set(texthandles(i),'units','pixels','position',[buttonsize(1)/2 buttonsize(2)/2],...
        'HorizontalAlignment','center','VerticalAlignment','middle','FontSize',textsize,'fontname','fixedwidth');   
    set(texthandles(i),'Tag',['text_' num2str(i)]);
    set(imagehandles(i),'Tag',['image_' num2str(i)]);   
    set(axeshandles(i),'Units','pixels',...
        'position',[margen-1+(buttonsize(1)+2)*(i-1) -margen+figuresize(4)-buttonsize(2) buttonsize(1) buttonsize(2)],...
        'Tag',['axes_' num2str(i)]);
    
    % Callback for button down
    str_ButtonDownFcn=sprintf('{@Button_ButtonDownFcn,findobj(''tag'',''mainGUI''),%s}',num2str(i));
    set(imagehandles(i),'ButtonDownFcn',eval(str_ButtonDownFcn)); 
    set(texthandles(i), 'ButtonDownFcn',eval(str_ButtonDownFcn)); 
end

%____Creates topline, below the Task buttons
axes('parent',h_mainfig,'tag','TopLine','units','pixels',...
    'position',[5 figuresize(4)-28 leftframewidth+rightframewidth+10 1],...
    'Box','on','TickLength',[0 0],'XTick',[],'YTick',[],'LineWidth',1.5,'color',[252/255 252/255 254/255])

%____ Create frame to logwin
axes('parent',h_mainfig,...
    'tag','log_axes',...
    'units','pixels',...    %axes to make logbar look nice
    'position',[margen-1 margen+25 figuresize(3)-2*margen+1 46+26],...
    'Box','on',...
    'TickLength',[0 0],...
    'XTick',[],...
    'YTick',[],...
    'LineWidth',1,...
    'color',[252/255 252/255 254/255]);

%____ Create listbox for log
project.handles.h_logwin=uicontrol('parent',h_mainfig,...
    'style','listbox',...
    'units','pixels',...
    'FontWeight','light',...
    'fontsize',textsize,...
    'fontname','fixedwidth',...
    'position',[margen margen+25 figuresize(3)-2*margen 45+26],...
    'HorizontalAlignment','left',...
    'BackgroundColor',[252/255 252/255 254/255],...
    'ListboxTop',1,...
    'Tag','log'); %Init log string  

msg_Log{1}='GUI started - select task';
%set(project.handles.h_logwin,'String',msg_Log)

%____Creates axes for Display frame to show
 project.handles.h_display=axes('parent',h_mainfig,...
     'tag','Result',...
     'units','pixels',...
     'position',[leftframewidth+25 133 rightframewidth-40 figuresize(4)-186],...
     'Box','on',...
     'TickLength',[0 0],...
     'XTick',[],...
     'YTick',[],...
     'LineWidth',1.5,...
     'color',[252/255 252/255 254/255]);
 axis(gca,'off');
%  ud.defPos=get(project.handles.h_display,'position'); %save default position in userdata
%  set(project.handles.h_display,'userdata',ud);
 
 %____ Create frame for working path 1
far=axes('parent',h_mainfig,...
    'tag','path_axes1',...
    'units','pixels',...    %axes to make logbar look nice
    'position',[margen-1 4 (figuresize(3)-10)/2 21],...
    'Box','on',...
    'TickLength',[0 0],...
    'XTick',[],...
    'YTick',[],...
    'LineWidth',1,...
    'color',[192/255 192/255 192/255]);

%____ Create frame for working path 2
mor=axes('parent',h_mainfig,...
    'tag','path_axes2',...
    'units','pixels',...    %axes to make logbar look nice
    'position',[margen-1+(figuresize(3)-10)/2 4 (figuresize(3)-10)/2 21],...
    'Box','on',...
    'TickLength',[0 0],...
    'XTick',[],...
    'YTick',[],...
    'LineWidth',1,...
    'color',[192/255 192/255 192/255]);

%____Creates text field to show project path in bottom of figure
text('parent',far,... 
        'units','pixels',...
        'fontsize',textsize,...
        'fontname','fixedwidth',...
        'position',[margen 12],...        
        'HorizontalAlignment','left',...
        'String','',...
        'Interpreter','none',...
        'tag','project_path');
    
text('parent',mor,...   
        'units','pixels',...
        'fontsize',textsize,...
        'fontname','fixedwidth',...
        'position',[margen 12],...
        'HorizontalAlignment','left',...
        'String','',...
        'Interpreter','none',...
        'tag','workspace_path'); 

%____Update project by storing in mainGUI
project.handles.data=data; %Save project into structure of mainGUI
set(h_mainfig,'UserData',project)

%_____ Wellcome image
welcomeGUI(figuresize);

%_____ Make figure visible 
set(h_mainfig,'Visible','on');

%_____ Init pipeline to given TaskIndex
drawGUI(h_mainfig,TaskIndex);

%______ Draw/update UIcontrol buttons
taskGUI(h_mainfig,TaskIndex);

%_____ Callbacks for mainGUI
set(h_mainfig,'CloseRequestFcn',{@Figure_CloseRequestFcn});

%set(h_mainfig,'WindowButtonUpFcn',{@checkForResize});

% ResizefcnCall=sprintf('resizeGUI(findobj(''tag'',''mainGUI''),0)');
set(h_mainfig,'ResizeFcn',{@checkForResize}); %strange thing caused creation of a UIcontrol to execute resize callback, so define this callback in the end of main!     

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function checkForResize(h_mainfig,event)
drawnow;
%project=get(h_mainfig,'userdata');
%actualSize=get(h_mainfig,'position');
%oldSize=project.handles.data.figuresize;
%if (oldSize(3)~=actualSize(3) | oldSize(4)~=actualSize(4))
    resizeGUI(h_mainfig);
%end
return

%--------------------------------------------------------------------
function windowX_CreateFcn(h, eventdata, figuresize, buttonsize, margen)
set(h,'Units','pixels','position',[margen margen+100 figuresize(3)-2*margen figuresize(4)-2*margen-buttonsize(2)-99],...
    'Box','on','TickLength',[0 0],'XTick',[],'YTick',[],'LineWidth',1.5,'color',[252/255 252/255 254/255]);

%--------------------------------------------------------------------
function Button_ButtonDownFcn(h,eventdata,h_mainfig,TaskIndex) %executes when step1 button is pressed. States are changed and stored. The figure updated by the use of drawGUI.m 
 
%  ResizefcnCall=sprintf('resizeGUI(findobj(''tag'',''mainGUI''),%s)',num2str(TaskIndex));
%  set(h_mainfig,'ResizeFcn',ResizefcnCall); 
 
 drawGUI(h_mainfig,TaskIndex); %calls drawGUI to make buttons, axes etc.
 taskGUI(h_mainfig,TaskIndex);
 
 
%----main figure termination------------------------------------------------------
function Figure_CloseRequestFcn(h,eventdata)
%Ask to save project before exist!!!! 020603TD

project=get(gcf,'userdata');

%warning off MATLAB:rmpath:DirNotFound;
%Restore Matlab path
pip_cleanMatlabpath(project.sysinfo.tmp_workspace);
% if(~isempty(project.sysinfo.tmp_workspace))
%     for(i=1:length(project.sysinfo.tmp_workspace))%NOTE: first dir is not removed is system dir
% %ONLY FOR TEST   (project.sysinfo.tmp_workspace{i})
%         if(exist(project.sysinfo.tmp_workspace{i})==7 & ~isempty(strfind(project.sysinfo.tmp_workspace{i},path)))
%             rmpath(project.sysinfo.tmp_workspace{i});%Clean-up Matlab path for old paths
%         end        
%     end    
% end

%___ Delete mainGUI
delete(gcf);
clear all;
