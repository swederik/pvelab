function taskGUI(h_mainfig,TaskIndex,varargin)
% taskGUI function makes buttons, popups ect. for the selected task
%   Called each time a task is selcted/pressed.
% 
% Input:
%   h_mainfig   : Handle to main figure of the pipeline program (mainGUI)
%   TaskIndex   : Index to active task in the project structure
%   varargin    : Abitrary number of input arguments. (NOT USED)
%
% Output:
%
% Uses special functions:
%   detailsGUI
%   text2bitmapGUI (under unix only)
%____________________________________________
% M. Twadark and T. Dyrby, 300703, NRU
%SW version: 080803TD

% - OK 080803TD: Add call for configurator_wrapper, when OPTIONS is pressed


%____ Load data stored in mainfig
project=get(h_mainfig,'UserData');
data=project.handles.data;

figuresize=get(h_mainfig,'position');       %returns position & size [x y 400 300]
leftframewidth=data.leftframewidth;
rightframewidth=data.rightframewidth;

%____ if resize situation, else save selected task index
if(TaskIndex==0)
    TaskIndex=project.handles.data.SelectedTaskIndexGUI;
else
    project.handles.data.SelectedTaskIndexGUI=TaskIndex;
    set(h_mainfig,'UserData',project);
end

%______ Tag's for each UIcontrol in a given task
str_TaskIndex=[num2str(TaskIndex)];

tag_task='task';
tag_method='method';
tag_configurator='options';
tag_information='information';
tag_show='show';
tag_details='details';

%______ Clear display
clearDisplay(project.handles.h_display,project.handles.data);

%______ RUN button, check if exist      
%Load project from mainfig   
project_task=sprintf('get(findobj(''Tag'',''%s''),''userdata'')',get(project.handles.h_mainfig,'Tag'));
MethodIndex=sprintf('get(findobj(''Tag'',''%s''),''Value'')',tag_method);

%Write a litle script for tooltip!!!
%TooltipFunc=sprintf(')

if(findobj('tag',tag_task))
    set(findobj('tag',tag_task),...
        'HorizontalAlignment','left',...
        'position',[leftframewidth-47-40-3 figuresize(4)-120 65+3 26],...
        'String',['   ' 'Run'],...
        'TooltipString','run selected method',...
        'Enable','on',...
        'Callback',{@UIbuttonRUN_callback, (project_task),(str_TaskIndex),(MethodIndex),leftframewidth});
else
    uicontrol('parent',h_mainfig,...
        'HorizontalAlignment','left',...
        'style','pushbutton',...
        'units','pixels',...
        'fontsize',data.textsize,...
        'fontname','fixedwidth',...
        'position',[leftframewidth-47-40-3 figuresize(4)-120 65+3 26],...
        'String',['   ' 'Run'],...
        'TooltipString','run selected method',...
        'Enable','on',...
        'Callback',{@UIbuttonRUN_callback, (project_task),(str_TaskIndex),(MethodIndex),leftframewidth},...
        'tag',tag_task,...
        'cdata',data.runButton_win);   
end
	

%______Pop-up Methods, check if exist
MethodList=[];
[Task,Methods]=size(project.pipeline.taskSetup);
for(i=1:Methods)
    if(~length(project.pipeline.taskSetup{TaskIndex,i}));
        continue
    end
    MethodList{i}=project.pipeline.taskSetup{TaskIndex,i}.method;
end

defaultMethod=project.pipeline.userPipeline(TaskIndex);%Init w. user-order method given in project

%Check if selected method index is OK!
if(defaultMethod>length(MethodList))
    project.pipeline.userPipeline(TaskIndex)=1;
    defaultMethod=1;
    project=logProject('WARNING: Default method index > available methods in task: 1 is set as default!!',project,TaskIndex,1);
end
    
%Use to enable disable configurator button
%   callbackFunc_configBut=sprintf('configurator_wrapperAvailabel(%s,%s,%s,%s)',project_task,str_TaskIndex,MethodIndex,tag_configurator)%   

if(findobj('tag',tag_method))
    set(findobj('tag',tag_method),...
        'position',[25 figuresize(4)-85 leftframewidth-47 26],...
        'String',MethodList,...
        'TooltipString','select method',...
        'Value',defaultMethod,...
        'Enable','on',...
        'Callback',{@UIbuttonPopUp_callback,(project_task),(str_TaskIndex),(MethodIndex)});
else
    uicontrol('parent',h_mainfig,...
        'style','popupmenu',...
        'units','pixels',...
        'fontsize',data.textsize,...
        'fontname','fixedwidth',...
        'position',[25 figuresize(4)-85 leftframewidth-47 26],...
        'String',MethodList,...
        'tag',tag_method,...
        'Enable','on',...
        'TooltipString','select method',...
        'Value',defaultMethod,...
        'Callback', {@UIbuttonPopUp_callback,(project_task),(str_TaskIndex),(MethodIndex)});
end

%______ INFO box, check if exist          
if(findobj('tag',tag_information))
    hand1=findobj('tag',tag_information);
    hand2=findobj('tag','infoSlider');
    set(hand1,'position',[25 figuresize(4)-428+20 140 200-20],...
        'string',project.pipeline.taskSetup{TaskIndex,defaultMethod}.description);
    set(hand2,'position',[27+140 figuresize(4)-428+25 10 200-25]);
    setSlider(hand2,hand1);

else
    infohan=uicontrol('parent',h_mainfig,...
        'style','text',...
        'units','pixels',...
        'fontsize',data.textsize,...
        'fontname','fixedwidth',...
        'position',[25 figuresize(4)-428+20 140 200-20],...
        'HorizontalAlignment','left',...
        'BackgroundColor',[252/255 252/255 254/255],...
        'tag',tag_information,...
        'string',project.pipeline.taskSetup{TaskIndex,defaultMethod}.description); 
    
    slidhan=uicontrol('parent',h_mainfig,'tag','infoSlider','Style','slider','position',[27+140 figuresize(4)-428+25 10 200-25]);
    setSlider(slidhan,infohan);
end

%______ OPTIONS button  
%__Check if a configurator_wrapper is available
if(isempty(project.pipeline.taskSetup{TaskIndex,project.pipeline.userPipeline(TaskIndex)}.configurator_wrapper))
    EnableDisable='off';
else
    EnableDisable='on'; 
end

if(findobj('tag',tag_configurator))
    set(findobj('tag',tag_configurator),...
        'HorizontalAlignment','left',...
        'position',[25 figuresize(4)-120 75 26],...
        'String',['     ' 'Options'],...
        'Enable',EnableDisable,...
        'Callback',{@UIbuttonOptions_callback, (project_task),(str_TaskIndex),(MethodIndex)});         
else
    uicontrol('parent',h_mainfig,...
        'HorizontalAlignment','left',...
        'style','pushbutton',...
        'units','pixels',...
        'fontsize',data.textsize,...
        'fontname','fixedwidth',...
        'position',[25 figuresize(4)-120 75 26],...
        'String',['     ' 'Options'],...
        'Callback',{@UIbuttonOptions_callback, (project_task),(str_TaskIndex),(MethodIndex)},...
        'tag',tag_configurator,...
        'Enable',EnableDisable,...
        'TooltipString','configure method',...
        'cdata',data.optionButton_win);   
end

%______ SHOW button, check if exist
%Delete old results...
delete(findobj('tag','Result_subfig'));

if(project.pipeline.statusTask(TaskIndex)==2)%2=DONE       
    EnableDisable='on';
    %Show results...
else
    EnableDisable='off';
end

 %EnableDisable='on'
if(findobj('tag',tag_show))
    set(findobj('tag',tag_show),...
        'HorizontalAlignment','left',...
        'position',[leftframewidth-90 figuresize(4)-165 68 26],...
        'String',['     ' 'Show'],...
        'Enable',EnableDisable,...
        'Callback',{@UIbuttonShow_callback, (project_task),(str_TaskIndex),MethodIndex});         
else
    uicontrol('parent',h_mainfig,...
        'HorizontalAlignment','left',...
        'style','pushbutton',...
        'units','pixels',...
        'fontsize',data.textsize,...
        'fontname','fixedwidth',...
        'position',[leftframewidth-90 figuresize(4)-165 68 26],...
        'String',['     ' 'Show'],...
        'Callback',{@UIbuttonShow_callback, (project_task),(str_TaskIndex),MethodIndex},...
        'tag',tag_show,...
        'Enable',EnableDisable,...
        'TooltipString','display current data',...
        'cdata',data.showButton_win);    
end



%_______ DETAIL button
if(project.pipeline.statusTask(TaskIndex)==2)%2=DONE    
    EnableDisable='on';
    %Show results...
else
    EnableDisable='off';
end

if(findobj('tag',tag_details))
    set(findobj('tag',tag_details),...
        'HorizontalAlignment','left',...
        'position',[leftframewidth-90 figuresize(4)-200 68 26],...
        'String',['      ' 'Details'],...
        'Enable',EnableDisable,...
        'Callback',{@UIbuttonDetails_callback, (project_task),(str_TaskIndex),MethodIndex});         
else
    uicontrol('parent',h_mainfig,...
        'HorizontalAlignment','left',...
        'style','pushbutton',...
        'units','pixels',...
        'fontsize',data.textsize,...
        'fontname','fixedwidth',...
        'position',[leftframewidth-90 figuresize(4)-200 68 26],...
        'String',['      ' 'Details'],...
        'Callback',{@UIbuttonDetails_callback, (project_task),(str_TaskIndex),MethodIndex},...
        'tag',tag_details,...
        'Enable',EnableDisable,...
        'TooltipString','list method parameters',...
        'cdata',data.detailsButton_win);
end

%drawnow
if isunix, refresh(h_mainfig);, end;

%--------------------------------------------------------------------
function UIbuttonPopUp_callback(h, eventdata, str_project,str_TaskIndex,str_MethodIndex,varargin) 
% PopUp-menue for the available Methods has changed!
% Update ...userPipeline in project if user selects an other method in a pipeline
% Updates informationbox with a description of the selected method
% Checks if OPTION button should be enable/disable if configurator erapper exist
%______________________________________________________________
% M. Twadark and T. Dyrby, 010503, NRU
%SW version: 250803TD


TaskIndex=eval(str_TaskIndex);
project=eval(str_project);
MethodIndex=eval(str_MethodIndex);

% %______ Clear display
clearDisplay(project.handles.h_display,project.handles.data);

% %Delete old results...
% delete(findobj('tag','Result_subfig'));
% axes(project.handles.h_display);
% cla, axis(gca,'off');


%______ Update ...userPipeline in project
New_MethodIndex=get(h,'Value');% Get selected Method in PopUp menue
project.pipeline.userPipeline(TaskIndex)=New_MethodIndex;

Updateproject(project,TaskIndex,New_MethodIndex);

%______ Update Information box for selected Method
tag_information='information';
hand1=findobj(project.handles.h_mainfig,'tag',tag_information);
hand2=findobj(project.handles.h_mainfig,'tag','infoSlider');
set(hand1,'string',project.pipeline.taskSetup{TaskIndex,New_MethodIndex}.description);

%reinitialize slider
setSlider(hand2,hand1);

%_____ Options button enable/disable if configurator wrapper exist
if(isempty(project.pipeline.taskSetup{TaskIndex,New_MethodIndex}.configurator_wrapper))
    set(findobj('tag','options'),'enable','off');
else
    set(findobj('tag','options'),'enable','on');
end


%--------------------------------------------------------------------
function UIbuttonRUN_callback(h, eventdata, str_project,str_TaskIndex,str_MethodIndex,varargin)
% RUN button has been pressed!
%
%______________________________________________________________
% M. Twadark and T. Dyrby, 010503, NRU
%SW version: 010603TD

 
TaskIndex=eval(str_TaskIndex);
project=eval(str_project);
MethodIndex=eval(str_MethodIndex);

%______ Clear display
%Delete old results...
clearDisplay(project.handles.h_display,project.handles.data);

% delete(findobj('tag','Result_subfig'));
% axes(project.handles.h_display);
% cla, axis(gca,'off');

%______ RUN method for given task
wrapperFucn=project.pipeline.taskSetup{end,1}.function_wrapper;%Get main_wrapper
callbackFunc_task=sprintf('%s(project,TaskIndex,MethodIndex)',wrapperFucn);%
project=eval(callbackFunc_task);

%_____ update show button
if(project.pipeline.statusTask(TaskIndex)==2)%2=DONE       
    EnableDisable='on';
    %Show results...
else
    EnableDisable='off';
end

%_____ Enable/disable SHOW
set(findobj('tag','show'),...
    'Enable',EnableDisable);

%_____ Enable/disable DETAILS
set(findobj('tag','details'),...
    'Enable',EnableDisable);

 
function UIbuttonShow_callback(h, eventdata, str_project,str_TaskIndex,str_MethodIndex,varargin)
% View button has been pressed. Show results...if exist!
%
% 
%______________________________________________________________
% T. Dyrby, 010503, NRU
%SW version: 030603TD

TaskIndex=eval(str_TaskIndex);
project=eval(str_project);
MethodIndex=eval(str_MethodIndex);

%______ Clear display
%Delete old results...
clearDisplay(project.handles.h_display,project.handles.data);
% delete(findobj('tag','Result_subfig'));
% axes(project.handles.h_display);
% cla, axis(gca,'off');

%____ Find results to show
%Search for method in project
[NoTask,NoMethods]=size(project.pipeline.taskSetup);
for(i=1:NoTask)
    if(strcmp(lower(project.pipeline.taskSetup{i,1}.task),'others'));
        ViewTaskIndex=i;
        for(ii=1:NoMethods)
            if(strcmp(lower(project.pipeline.taskSetup{ViewTaskIndex,ii}.method),'show results'));
                ViewMethodIndex=ii;
                break
            end        
        end            
        break
    end        
end

%______ Show method for given task
wrapperFucn=project.pipeline.taskSetup{end,1}.function_wrapper;%Get main_wrapper
project_task=sprintf('get(findobj(''Tag'',''%s''),''UserData'')',get(project.handles.h_mainfig,'Tag'));
callbackFunc_task=sprintf('%s(%s,%s,%s,%s,%s)',wrapperFucn,project_task,num2str(ViewTaskIndex),num2str(ViewMethodIndex),...
    num2str(TaskIndex),num2str(MethodIndex));%
eval(callbackFunc_task);


%--------------------------------------------------------------------
function UIbuttonOptions_callback(h, eventdata, str_project,str_TaskIndex,str_MethodIndex,varargin)
% Options button has been pressed!
%
% ONLY FOR TEST
%______________________________________________________________
% M. Twardak and T. Dyrby, 040803, NRU
%SW version: 040803TD

TaskIndex=eval(str_TaskIndex);
project=eval(str_project);
MethodIndex=eval(str_MethodIndex);

%_____ Start configurator setup through mainWrapper
wrapperFucn=project.pipeline.taskSetup{end,1}.function_wrapper;%Get main_wrapper

% Save all configuration setup temporary in 'back' in project
[config_TaskIndex,config_MethodIndex]=size(project.pipeline.taskSetup);
project.pipeline.taskSetup{config_TaskIndex,config_MethodIndex}=project.pipeline.taskSetup{TaskIndex,MethodIndex};

%No tasks required for a configurator
project.pipeline.taskSetup{config_TaskIndex,config_MethodIndex}.require_taskindex{1}=[];
%Start configurator wrapper
feval(wrapperFucn,project,config_TaskIndex,config_MethodIndex,'configurator',TaskIndex,MethodIndex);


function UIbuttonDetails_callback(h, eventdata, str_project,str_TaskIndex,str_MethodIndex,varargin)
% Details button has been pressed. Show details about the success of a task...if they exist!
%
% 
%______________________________________________________________
% T. Dyrby, 030703, NRU
%SW version: 030703TS, NRU

TaskIndex=eval(str_TaskIndex);
project=eval(str_project);
MethodIndex=eval(str_MethodIndex);

%_____ Must be placed into the Setup file and called as a wrapper!!!
detailsGUI(project,TaskIndex,MethodIndex);

