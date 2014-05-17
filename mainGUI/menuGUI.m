function menuGUI(project)
% menuGUI function initialize and setup callbacks
%   for each menus given as methods in Task='Others' found
%   in the 'project.pipeline.taskSetup{TaskIndex='Others', MethodIndex}'
%
% Called when mainGUI is initalised.
%
% Input:
%   project : Structure containing all information of actual pipeline
%
% Output:
%
% Uses special functions:
%____________________________________________
% M. Twadark and T. Dyrby, 030603, NRU
%SW version: 100903TD


%____If menus already exist
if(findobj('tag','menuGUI'))
    %Menue already exist
    return
end

%____ Menu functions belongs only to task: 'Others'
[NoTasks,NoMethods]=size(project.pipeline.taskSetup);
for(i=1:NoTasks)
    if(~isfield(project.pipeline.taskSetup{i,1},'task'))
        continue
    end
    
    if(strcmp(lower(project.pipeline.taskSetup{i,1}.task),'others'))
        TaskIndex=i;
        break
    end
end

mainWrapperFcn=project.pipeline.taskSetup{end,1}.function_wrapper;

project_task=sprintf('get(findobj(''Tag'',''%s''),''UserData'')',get(project.handles.h_mainfig,'Tag'));

menu1 = uimenu('Label','File');
    MethodIndex=NoMethods-6;%New project
    CallBackFcn=sprintf('%s(%s,%s,%s)',mainWrapperFcn,project_task,num2str(TaskIndex),num2str(MethodIndex));
    msg=project.pipeline.taskSetup{TaskIndex,MethodIndex}.method_name;
    uimenu(menu1,...
        'Label',msg,...
        'Enable','on',...
        'Callback',CallBackFcn,...
        'tag','menueGUI');

    MethodIndex=NoMethods-7;%Load Project
    CallBackFcn=sprintf('%s(%s,%s,%s)',mainWrapperFcn,project_task,num2str(TaskIndex),num2str(MethodIndex));
    msg=project.pipeline.taskSetup{TaskIndex,MethodIndex}.method_name;
    uimenu(menu1,...
        'Label',msg,...
        'Enable','on',...
        'Callback',CallBackFcn,...
        'tag','menueGUI');
    
    MethodIndex=NoMethods-8;%Save project
    CallBackFcn=sprintf('%s(%s,%s,%s)',mainWrapperFcn,project_task,num2str(TaskIndex),num2str(MethodIndex));
    msg=project.pipeline.taskSetup{TaskIndex,MethodIndex}.method;
    uimenu(menu1,'Label',msg,'Enable','on','Callback',CallBackFcn,'tag','menueGUI');
    
    
    MethodIndex=NoMethods-0;%Set workspace
    CallBackFcn=sprintf('%s(%s,%s,%s)',mainWrapperFcn,project_task,num2str(TaskIndex),num2str(MethodIndex));
    msg=project.pipeline.taskSetup{TaskIndex,MethodIndex}.method;
    uimenu(menu1,'Label',msg,...
        'Separator','on',...
        'Enable','on',...
        'Callback',CallBackFcn,...
        'tag',['tag_',project.pipeline.taskSetup{TaskIndex,MethodIndex}.function_wrapper]);
        

    MethodIndex=NoMethods-3;%Load template
    CallBackFcn=sprintf('%s(%s,%s,%s)',mainWrapperFcn,project_task,num2str(TaskIndex),num2str(MethodIndex));
    msg=project.pipeline.taskSetup{TaskIndex,MethodIndex}.method;
    uimenu(menu1,'Label',msg,'Separator','on','Enable','on','Callback',CallBackFcn,'tag','menuGUI');

    MethodIndex=NoMethods-4;%Save template
    CallBackFcn=sprintf('%s(%s,%s,%s)',mainWrapperFcn,project_task,num2str(TaskIndex),num2str(MethodIndex));
    msg=project.pipeline.taskSetup{TaskIndex,MethodIndex}.method_name;
    uimenu(menu1,'Label',msg,'Enable','on','Callback',CallBackFcn,'tag','menuGUI');
    
    MethodIndex=NoMethods-1;%Load default settings
    CallBackFcn=sprintf('%s(%s,%s,%s)',mainWrapperFcn,project_task,num2str(TaskIndex),num2str(MethodIndex));
    msg=project.pipeline.taskSetup{TaskIndex,MethodIndex}.method_name;
    uimenu(menu1,'Label',msg,'Enable','on','Callback',CallBackFcn,'Separator','on','tag','menuGUI');
 
    %Quit
    uimenu(menu1,'Label','Quit','Separator','on','tag','menuGUI_quit');


menu2 = uimenu('Label','Start');
    MethodIndex=NoMethods-2;%Run project
    CallBackFcn=sprintf('%s(%s,%s,%s)',mainWrapperFcn,project_task,num2str(TaskIndex),num2str(MethodIndex));
    msg=project.pipeline.taskSetup{TaskIndex,MethodIndex}.method;
    uimenu(menu2,'Label',msg,'Enable','on','Callback',CallBackFcn,'tag','menuGUI');
    
    MethodIndex=NoMethods-2;%Run project/CONTINUE
    CallBackFcn=sprintf('%s(%s,%s,%s,''continue'')',mainWrapperFcn,project_task,num2str(TaskIndex),num2str(MethodIndex));
    msg='Continue project';
    uimenu(menu2,'Label',msg,'Enable','on','Callback',CallBackFcn,'tag','menuGUI');
    
 %%%%%%%%%%%%%%%%% User menu: Fields are automaticly created is a 'Others' are detected in the user setupfiles %%%%%%%%  
menu3 = uimenu('Label','Tools');
for(iMethodIndex=1:NoMethods-12)
    if(~isempty(project.pipeline.taskSetup{TaskIndex,iMethodIndex}.function_wrapper))
        CallBackFcn=sprintf('%s(%s,%s,%s)',mainWrapperFcn,project_task,num2str(TaskIndex),num2str(iMethodIndex));
        msg=project.pipeline.taskSetup{TaskIndex,iMethodIndex}.method;%Texst in menu
        uimenu(menu3,'Label',msg,'Enable','on','Callback',CallBackFcn,'tag','menuGUI');
    end
    
    %MethodIndex=1;%Tools menu:RCV
    %CallBackFcn=sprintf('%s(%s,%s,%s)',mainWrapperFcn,project_task,num2str(TaskIndex),num2str(MethodIndex));
    %msg=project.pipeline.taskSetup{TaskIndex,MethodIndex}.method;
    %uimenu(menu3,'Label',msg,'Enable','on','Callback',CallBackFcn,'tag','menuGUI');
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
     
menu4 = uimenu('Label','View');
    MethodIndex=NoMethods-10;%2D browse
    CallBackFcn=sprintf('%s(%s,%s,%s)',mainWrapperFcn,project_task,num2str(TaskIndex),num2str(MethodIndex));
    msg=project.pipeline.taskSetup{TaskIndex,MethodIndex}.method;
    uimenu(menu4,'Label',msg,'Enable','on','Callback',CallBackFcn,'tag','menuGUI');
    
    MethodIndex=NoMethods-11;%3D browse
    CallBackFcn=sprintf('%s(%s,%s,%s)',mainWrapperFcn,project_task,num2str(TaskIndex),num2str(MethodIndex));
    msg=project.pipeline.taskSetup{TaskIndex,MethodIndex}.method;
    uimenu(menu4,'Label',msg,'Enable','on','Callback',CallBackFcn,'tag','menuGUI');

    MethodIndex=NoMethods-9;%Inspect
    CallBackFcn=sprintf('%s(%s,%s,%s)',mainWrapperFcn,project_task,num2str(TaskIndex),num2str(MethodIndex));
    msg=project.pipeline.taskSetup{TaskIndex,MethodIndex}.method;
    uimenu(menu4,'Label',msg,'Enable','on','Callback',CallBackFcn,'tag','menuGUI');
    
menu5 = uimenu('Label','Help');
    boogie=uimenu(menu5,'Label','Documentation','Enable','on','tag','menuGUI');
    uimenu(menu5,'Label','About','Callback','msgbox(sprintf(''PVElab pipeline program, v. 2.2, released Feb. 2012.\n by Tim Dyrby, Marco Commerci, Michael Twardak, Thomas Rask,\n Bruno Alfano, Mario Quarantelli, and Claus Svarer.\nFinansed by PVEOut, EU 5th framework project #QLG3-CT-2000-000594\n Download instructions found at http://nru.dk/pveout''),''About The Pipeline Program'',''help'')');

    %__ Find number of task methods and get their documentation string, place string in documentation menu   
    loops=size(project.pipeline.taskSetup); %could be [8 13]
    for n=1:loops(1)     
        for m=1:loops(2) %instead we can use size(project.pipeline.taskSetup{m}) {y,x}
            if isempty(project.pipeline.taskSetup{n,m}) 
                %not interested 
            else  
                if isfield(project.pipeline.taskSetup{n,m},'task')
                    task=project.pipeline.taskSetup{n,m}.task;
                    if(~strcmp(lower(task),'others'))  
                        if isfield(project.pipeline.taskSetup{n,m},'method')
                            method=project.pipeline.taskSetup{n,m}.method;
                        else
                            method='';
                        end
                        if isfield(project.pipeline.taskSetup{n,m},'documentation')
                            documentation=project.pipeline.taskSetup{n,m}.documentation;
                        else
                            documentation='none';
                        end

                        %see if documentation string contains an URL starting with http or www  
                        %docstring=lower(documentation);
			docstring=documentation;
                        startURL=strfind(lower(docstring),'http://');
			if ~isempty(startURL)
			    str=docstring(startURL(1):length(docstring));
			    address=strtok(str);
                            HelpType=1;    % HTML reference
			else    
	                    startURL=strfind(lower(docstring),'file:/');
		            if ~isempty(startURL)
			       str=docstring(startURL(1):length(docstring));
			       address=strtok(str);
			       pipelinePath=fileparts(fileparts(which('menuGUI')));
			       docPath=[pipelinePath filesep 'documentation'];
                               address=[address(1:5) docPath filesep address(7:length(address))];
                               HelpType=2;    % File reference
			    else
			       address='';
                               HelpType=0;    % Ho help reference
		            end
			end

                        h=uimenu(menu5,'Parent',boogie,'label',[task ' - ' method ' : ' documentation],...
                            'Callback',['web ' address]);   
%                            'Callback',['web ' address ' -browser']);   
			if (HelpType==1)
			  set(h,'foregroundcolor','blue');
			elseif (HelpType==2)
			  set(h,'foregroundcolor','black');
			else
			  %set(h,'foregroundcolor',[0.5 0.5 0.5]);
			  set(h,'enable','off');
			end
                    end    
                end      
            end
        end
    end

function UIbuttonMENU_callback(h, eventdata, project,TaskIndex,MethodIndex,varargin)
% Function to save program lines...
%______________________________________________________________
% M. Twadark and T. Dyrby, 010503, NRU
%SW version: 010603TD

%______ RUN method for given task
wrapperFucn=project.pipeline.taskSetup{end,1}.function_wrapper;%Get main_wrapper
callbackFunc_task=sprintf('%s(project,TaskIndex,MethodIndex)',wrapperFucn);%
eval(callbackFunc_task);
