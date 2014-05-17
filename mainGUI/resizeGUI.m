function resizeGUI(h_mainfig,TaskIndex,varargin)    
% resizeGUI function resizes the GUI of the pipeline program.
%
% Input:
%   h_mainfig   : Handle to main figure of the pipeline program (mainGUI)
%   TaskIndex   : Index to active task in the project structure
%   varargin    : Abitrary number of input arguments. (NOT USED)
%
% Output:
%
% Uses special functions:
%   drawGUI
%   taskGUI
%____________________________________________
%SW version: 020603MT,TD, NRU
%

%____ Init of variables
project=get(h_mainfig,'UserData');
data=project.handles.data;
TaskIndex=data.SelectedTaskIndexGUI;

%_______ Update size of frames and then save.
figuresize=get(h_mainfig,'position'); %returns position & size [x y 400 300]   

%____Ensure minimum figure size 
if(figuresize(3)<750) %minimum width

    figuresize(3)=750;
    set(h_mainfig,'Position',[figuresize(1) figuresize(2) figuresize(3) figuresize(4)]); 
end
if(figuresize(4)<550) %minimum height
    figuresize(2)=figuresize(2)+(figuresize(4)-550);
    figuresize(4)=550;
    set(h_mainfig,'Position',[figuresize(1) figuresize(2) figuresize(3) figuresize(4)]); 
end


%____Update size info.
leftframewidth=data.leftframewidth;  %left frame width is fixed, the right frame and bottom frame are resized to fit the figure
rightframewidth=figuresize(3)-leftframewidth-20;

data.rightframewidth=rightframewidth;       
data.figuresize=figuresize; %update figuresize value just in case 

margen=data.margen;         %margen used in figure
buttonsize=data.buttonsize; %buttonsize x stored in structure later, also specify in resize.m  
textsize=data.textsize;     %fontsize


%_______ Scale and move the 4 step axes and the 2 window axes in figure so they fit----------------------------  
set(findobj('Tag','windowX'),...
    'Units','pixels',...
    'position',[margen margen+100 figuresize(3)-2*margen figuresize(4)-2*margen-buttonsize(2)-99],...
    'Box','on',...
    'TickLength',[0 0],...
    'LineWidth',1.5,...
    'color',[252/255 252/255 254/255]);

%____ Resize log listbox
set(project.handles.h_logwin,...
    'position',[margen margen+25 figuresize(3)-2*margen 45+26]); 

%____ Resize log frame (axes)
set(findobj('tag','log_axes'),...
    'position',[margen-1 margen+25 figuresize(3)-2*margen+1 46+26]);

%____ Resize path objects in bottom of figure
set(findobj('tag','path_axes1'),...
    'position',[margen-1 4 (figuresize(3)-10)/2 21]); 
set(findobj('tag','path_axes2'),...
    'position',[margen-1+(figuresize(3)-10)/2 4 (figuresize(3)-10)/2 21]);

%Clear and resize display
clearDisplay(project.handles.h_display,data);
                   
%____ Resize fane for tasks
[NoTasks,NoMethods]=size(project.pipeline.taskSetup);
for(i=1:NoTasks-2)   
    str_obj=sprintf('findobj(''tag'',''axes_%s'')',num2str(i));
    str_position=sprintf('[margen-1+(buttonsize(1)+2)*(%s-1) -margen+figuresize(4)-buttonsize(2) buttonsize(1) buttonsize(2)]',num2str(i));       
    set(eval(str_obj),...
        'Units','pixels',...
        'position',eval(str_position));           
end

%____ Upadate data stored in mainfig
project=get(h_mainfig,'UserData');
project.handles.data=data;
set(h_mainfig,'UserData',project)

%_____ Delete OLD frames
delete(findobj('Tag','infoFrame'));  %clear UIcontrols before drawing new ones. Only if currentbutton != pressedbutton      
delete(findobj('Tag','resultFrame'));  %clear UIcontrols before drawing new ones. Only if currentbutton != pressedbutton      
delete(findobj('Tag','methodFrame'));  %clear UIcontrols before drawing new ones. Only if currentbutton != pressedbutton      

%_____ Draws the content of the active button (for exapmple contents of load, registation, segmentation ... )
drawGUI(h_mainfig,TaskIndex);
taskGUI(h_mainfig,TaskIndex);

