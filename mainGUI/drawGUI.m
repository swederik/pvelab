function drawGUI(h_mainfig,TaskIndex,varargin) 
% drawGUI function updates, w. respect to changes in the project, 
%   the contens of the GUI in the pipeline program.
%
% Input:
%   h_mainfig   : Handle to main figure of the pipeline program (mainGUI)
%   TaskIndex   : Index to active task in the project structure
%   varargin    : Abitrary number of input arguments. (NOT USED)
%
% Output:
%
% Uses special functions:
%       frameGUI
%       get_username
%____________________________________________
% M. Twadark and T. Dyrby, 010503, NRU
%SW version: 010603TD

%____ Load data stored in mainfig
project=get(h_mainfig,'UserData');

%_____ Update titlebar in mainFig
ImageIndex=project.pipeline.imageIndex(1);
noModalities=length(project.pipeline.imageModality);
if(~isfield(project.taskDone{TaskIndex},'username'))
    username=get_username;
else
    username=project.taskDone{TaskIndex}.username;
end

titleInfo=[project.pipeline.taskSetup{end,1}.method_name,' (',username,') - '];
space=['  |  '];
if(project.pipeline.statusTask(1)==2)%FileLoad is DONE    
    for(i=1:noModalities)
        if(i==noModalities)
            titleInfo=[titleInfo,project.taskDone{1}.outputfiles{ImageIndex,i}.name];
        else
            titleInfo=[titleInfo,project.taskDone{1}.outputfiles{ImageIndex,i}.name,space];            
        end
    end    
end 
set(project.handles.h_mainfig,'name',titleInfo);  



%_____ Update path in bottom of mainFig *** Hej Tim ***
if(~isempty(project.sysinfo.workspace) & ~isempty(project.sysinfo.prjfile))
        path_string=['Project: ',fullfile('',project.sysinfo.workspace,project.sysinfo.prjfile)];
else
    path_string='Project: Not started';
end
%____ Add workspace to bottom infoline
if(~isempty(project.sysinfo.mainworkspace))
    workspace_string=['main workspace: ',project.sysinfo.mainworkspace];
else
    workspace_string=['main workspace: Not given'];
end

set(findobj('tag','project_path'),'String',path_string);
set(findobj('tag','workspace_path'),'String',workspace_string);

%____ Check if workspace is loaded
taskSum=0;    
for i=1:(length(project.pipeline.statusTask)-2)
    taskSum=taskSum+project.pipeline.statusTask(i);
end

h_menuWrkSpc=findobj('tag',['tag_','setWorkspace_wrapper']);
if(taskSum==0 | project.pipeline.statusTask(1)==3)
    set(h_menuWrkSpc,'Enable','on');   
else
    set(h_menuWrkSpc,'Enable','off');    
end
 
%____ Pointer: WATCH:an task is Active, else ARROW (ready state)
% Only for task different from 'Others'
[NoTasks,NoMethods]=size(project.pipeline.taskSetup);
for(iNoTasks=1:NoTasks)
    if(strcmp(lower(project.pipeline.taskSetup{iNoTasks,1}.task),'others'))        
        break
    end
end

%____show system is working
q=find(project.pipeline.statusTask==1);
if(~isempty(q) & ~isempty(find(q~=iNoTasks)))
    set(gcf,'pointer','watch');%a Task is active
else
    set(gcf,'pointer','arrow');%Pipeline is ready
end


%____ if resize situation or 'others'-task, else save selected task index
if(isempty(TaskIndex) | TaskIndex==0 | strcmp(lower(project.pipeline.taskSetup{TaskIndex}.task),'others'))
    TaskIndex=project.handles.data.SelectedTaskIndexGUI;
else
    project.handles.data.SelectedTaskIndexGUI=TaskIndex;
    set(h_mainfig,'UserData',project);
end

%____ Tasks 'Others' do not belong to the pipeline
%if(strcmp(lower(project.pipeline.taskSetup{TaskIndex}.task),'others'))
%    TaskIndex=1; %
%end


data=project.handles.data;
leftframewidth=data.leftframewidth;
rightframewidth=data.rightframewidth;

%_____Write welcome info at startup
if(TaskIndex==0)
    figuresize=get(h_mainfig,'position');       %returns position & size [x y 400 300]

    uicontrol('style','text','units','pixels','position',[figuresize(3)/2-50 figuresize(4)/2-25 100 50],...
        'String',{'Welcome to','PVE Lab'},'fontsize',project.handles.data.textsize,'fontname','fixedwidth','BackgroundColor',[252/255 252/255 254/255]);        
    return
end

%_____ Draw frames
frameGUI(h_mainfig,TaskIndex);

%_____ Redraw topline below Task buttons
axes(findobj('tag','TopLine'));
   
%_____ Draw buttons for given task
axes(findobj('Tag',['axes_',num2str(TaskIndex)])); %making "current axes" makes it appear in front (selected)   

%_____ Set status for Passive fanes (tasks)
[NoTasks,NoMethods]=size(project.pipeline.taskSetup);
for(i=1:NoTasks-2)    
    switch project.pipeline.statusTask(i)
    case 0
        faneStatusFile=data.fanePassiveNormal;
    case 1
        faneStatusFile=data.fanePassiveNext;
    case 2
        faneStatusFile=data.fanePassiveOK;
    case 3
        faneStatusFile=data.fanePassiveError;
    otherwise
        faneStatusFile=data.fanePassiveError;
    end%switch
  
    set(findobj('Tag',['image_',num2str(i)]),'cdata',faneStatusFile);  %loads new bitmap into button image (selected bitmap)    
end

%_____ Set status for selected fane (tasks)
switch project.pipeline.statusTask(TaskIndex)
case 0
    faneStatusFile=data.faneSelectedNormal;
case 1
    faneStatusFile=data.faneSelectedNext;
case 2
    faneStatusFile=data.faneSelectedOK;
case 3
    faneStatusFile=data.faneSelectedError;
otherwise
    faneStatusFile=data.faneSelectedError;
end%switch

set(findobj('Tag',['image_',num2str(TaskIndex)]),'cdata',faneStatusFile);  %loads new bitmap into button image (selected bitmap)


if isunix, refresh(h_mainfig);, end;
%drawnow