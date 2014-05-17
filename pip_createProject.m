function project=pip_createProject(project,TaskIndex,MethodIndex,varargin)
%
% Input:
%   project     : Structure containing all information of actual pipeline
%   TaskIndex   : Index to active task in the project structure
%   MethodIndex : Index to used method in a TaskIndex in the project structure
%   varargin    : promtUser4projectName=varargin{1}   1: User project name, 0: don't ask user (optional, default is 1)

%
% Output:
%   project     : Return updated project       
%
% Uses special functions:
%   logProject
%   drawGUI
% ____________________________________________
% T. Dyrby, 150104 DRCMR
%
%SW version: 150104, TD

ImageIndex=project.pipeline.imageIndex(1);
ModalityIndex=1;%Name after the first modality

% ____ Workspace and project file exist?
if(~isempty(project.sysinfo.workspace) & exist(project.sysinfo.workspace)==7)     
    if(~isempty(project.sysinfo.prjfile) & exist(project.sysinfo.prjfile)==2)        
        %Log info
        msg=sprintf('Project file and directory exist: %s%s%s',project.sysinfo.workspace,filesep,project.sysinfo.prjfile);
        project=logProject(msg,project,TaskIndex,MethodIndex);
        return
    end
end

%Set promtUser4projectName
if isempty(varargin{1})
    promtUser4projectName=1;%1: User project name, 0: don't ask user
else
    promtUser4projectName=varargin{1};
end

%Set default dirs
origPath=pwd;

Dirs.prjfile='';
Dirs.workspace='';
Dirs.sugName='';
Dirs.sugNo=0;
if isempty(project.sysinfo.mainworkspace)
    Dirs.mainworkspace=origPath;
else
    Dirs.mainworkspace=project.sysinfo.mainworkspace;
end
Dirs.fix=project.pipeline.taskSetup{end,1}.prefix;

if promtUser4projectName
%_________________________________create GUI______________________________________
%setup default dirs
Dirs.sugName='proj_';
Dirs.sugNo=1;
Dirs.workspace=[Dirs.mainworkspace,filesep,Dirs.fix,'_',Dirs.sugName,num2str(Dirs.sugNo)];
while exist(Dirs.workspace)==7
    Dirs.sugNo=Dirs.sugNo+1;
    Dirs.workspace=[Dirs.mainworkspace,filesep,Dirs.fix,'_',Dirs.sugName,num2str(Dirs.sugNo)];
end
Dirs.sugName=[Dirs.sugName,num2str(Dirs.sugNo)];
Dirs.prjfile=[Dirs.sugName,'.prj'];

color=[252/255 252/255 254/255];
Pos=project.handles.data.figuresize;
fWidth=300;
fHight=280;
Pos(1)=Pos(1)+Pos(3)/2-fWidth/2;
Pos(2)=Pos(2)+Pos(4)/2-fHight/2;
Pos(3)=fWidth;
Pos(4)=fHight;
    
hFig=figure('tag','CreateNewProject_fig','position',Pos,'name','Create new project','menubar','none','resize','off','numberTitle','off','Color',color);%,'visible','off');

%Frame
frHight=fHight-55;
frPos=[6,fHight-frHight-5,fWidth-10,frHight];
frPos2=[9,fHight-frHight+10,fWidth-16,frHight-145];
uicontrol('parent',hFig,'style','frame','position',frPos,'BackgroundColor',color)
uicontrol('parent',hFig,'style','frame','position',frPos2,'BackgroundColor',color)


%mainworkspace
uicontrol('parent',hFig,'style','text','position',[15,fHight-43,260,20],'string','Main workspace:','HorizontalAlignment','left','BackgroundColor',color);
h.felt1=uicontrol('parent',hFig,'style','edit','position',[18,fHight-60,210,20],'string',Dirs.mainworkspace,'HorizontalAlignment','left','callback',@Update_callback);
uicontrol('parent',hFig,'style','pushbutton','position',[230,fHight-60,52,20],'string','Browse','callback',@Browse_callback,'userdata',h.felt1);

uicontrol('parent',hFig,'style','text','position',[15,fHight-97,260,20],'string','Project name:','HorizontalAlignment','left','BackgroundColor',color);
h.felt2=uicontrol('parent',hFig,'style','edit','position',[18,fHight-115,100,20],'string',Dirs.sugName,'HorizontalAlignment','left','callback',@Update_callback);
h.txt1=uicontrol('parent',hFig,'style','text','position',[15,fHight-190,270,50],'TooltipString',['Project workspace: ',Dirs.workspace],'string',['Project workspace: ',Dirs.workspace],'HorizontalAlignment','left','BackgroundColor',color);
h.txt2=uicontrol('parent',hFig,'style','text','position',[15,fHight-205,270,20],'string',['Project filename: ',Dirs.prjfile],'HorizontalAlignment','left','BackgroundColor',color);


%Buttons
bHight=fHight-frHight-30;
butCan=uicontrol('parent',hFig,'style','pushbutton','position',[155,15,70,bHight],'string','Cancel','callback',@Cancel_callback);
butOk=uicontrol('parent',hFig,'style','pushbutton','position',[75,15,70,bHight],'string','Ok','callback',@Ok_callback);

%save all data in figure
ud.Dirs=Dirs;
ud.h=h;
set(hFig,'userdata',ud);

%Get changed project and out
uiwait(hFig);
%_________________________________end create GUI______________________________________
else
    %_____ No files loaded to make a workspace, therefore save project as template
    if(~isfield(project.taskDone{1},'outputfiles') | isempty(project.taskDone{1}.outputfiles) | isempty(project.taskDone{1}.outputfiles{ImageIndex,1}.name))
        %Log info
        project=logProject('Create project: No files loaded to make a unique project workspace, project not created!',project,TaskIndex,MethodIndex);     
        return;
    end
    
    %set Dirs from fileinfo
    [tmpPath,Dirs.sugName]=fileparts(project.taskDone{1}.outputfiles{ImageIndex,1}.name);
    Dirs.workspace=[Dirs.mainworkspace,filesep,Dirs.fix,'_',Dirs.sugName];
    Dirs.prjfile=[Dirs.sugName,'.prj'];
    while exist(Dirs.workspace)==7
        Dirs.sugNo=Dirs.sugNo+1;
        Dirs.sugNameEx=[Dirs.sugName,'_',num2str(Dirs.sugNo)];
        Dirs.workspace=[Dirs.mainworkspace,filesep,Dirs.fix,'_',Dirs.sugNameEx];
        Dirs.prjfile=[Dirs.sugNameEx,'.prj'];
    end
    
    if isfield(Dirs,'sugNameEx'), Dirs.sugName=Dirs.sugNameEx; end;

    try
        S=mkdir(Dirs.mainworkspace,[Dirs.fix,'_',Dirs.sugName]);
    catch
        project=logProject('Create project: Could not create project dir in main workspace! Please change main workspace.',project,TaskIndex,MethodIndex);     
        return;
    end        
end %promtUser4projectName

if exist('hFig')==1 & ishandle(hFig)
    ud=get(hFig,'userdata');
    Dirs=ud.Dirs;
    delete(hFig);
end

if ~isempty(Dirs.workspace) & exist(Dirs.workspace)==7
    project.sysinfo.prjfile=Dirs.prjfile;
    project.sysinfo.workspace=Dirs.workspace;
    project.sysinfo.mainworkspace=Dirs.mainworkspace;

    %Add to Matlab path
    addpath(project.sysinfo.workspace);
    project.sysinfo.tmp_workspace{end+1}=project.sysinfo.workspace;%Will be removed on exit    
    
    %Write Log
    msg=sprintf('Project file and directory created: %s%s%s',project.sysinfo.workspace,filesep,project.sysinfo.prjfile);
    project=logProject(msg,project,TaskIndex,MethodIndex);
    
    %__________ Update project and log file
    project=Updateproject(project,TaskIndex,MethodIndex);
    
    %______ Update MainGUI if mainfig exist
    if(ishandle(project.handles.h_mainfig)) 
        drawGUI(project.handles.h_mainfig,TaskIndex,MethodIndex);
    end
end


%____________________Callbacks__________________________

function Ok_callback(Handle,varargin)
hFig=get(Handle,'parent');
ud=get(hFig,'userdata');
Dirs=ud.Dirs;
h=ud.h;

%Check if mainworkspace exists
if ~(exist(Dirs.mainworkspace)==7)
    warndlg(['Please select a main workspace that exist!'],'Main workspace');
    return;
end
cd(Dirs.mainworkspace);

%check if selected dir exists
if ~(exist(Dirs.workspace)==7)
    try
    S=mkdir(Dirs.mainworkspace,[Dirs.fix,'_',Dirs.sugName]);
    %Check if project dir has been created
    if ~(exist(Dirs.workspace)==7)
        if strcmp(Dirs.sugName,['proj_',num2str(Dirs.sugNo)])
            warndlg(['Could not create project directory in main workspace, please try again!'],'Project workspace');
            Dirs.sugName='proj_';
            Dirs.sugNo=1;
            Dirs.workspace=[Dirs.mainworkspace,filesep,Dirs.fix,'_',Dirs.sugName,num2str(Dirs.sugNo)];
            while exist(Dirs.workspace)==7
                Dirs.sugNo=Dirs.sugNo+1;
                Dirs.workspace=[Dirs.mainworkspace,filesep,Dirs.fix,'_',Dirs.sugName,num2str(Dirs.sugNo)];
            end
            Dirs.sugName=['proj_',num2str(Dirs.sugNo)];
            set(h.felt2,'string',Dirs.sugName);
            ud.Dirs=Dirs;
            set(hFig,'userdata',ud);
            Update_callback(Handle)
        else
            warndlg(['Could not create project directory in main workspace, please try again with a different project name or main workspace!'],'Project workspace');
        end
        return;
    end
    catch
        warndlg(['Could not create project directory in main workspace, please try again with a different project name or main workspace!'],'Project workspace');
        return;
    end
else
    if strcmp(Dirs.sugName,['proj_',num2str(Dirs.sugNo)])
        warndlg(['Could not create project directory in main workspace, please try again!'],'Project workspace');
        Dirs.sugName='proj_';
        Dirs.sugNo=1;
        Dirs.workspace=[Dirs.mainworkspace,filesep,Dirs.fix,'_',Dirs.sugName,num2str(Dirs.sugNo)];
        while exist(Dirs.workspace)==7
            Dirs.sugNo=Dirs.sugNo+1;
            Dirs.workspace=[Dirs.mainworkspace,filesep,Dirs.fix,'_',Dirs.sugName,num2str(Dirs.sugNo)];
        end
        Dirs.sugName=['proj_',num2str(Dirs.sugNo)];
        set(h.felt2,'string',Dirs.sugName);
        ud.Dirs=Dirs;
        set(hFig,'userdata',ud);
        Update_callback(Handle)
    else
        warndlg(['Could not create project directory in main workspace, please try again with a different project name or main workspace!'],'Project workspace');
    end
    return;
end     
uiresume(hFig);

function Update_callback(Handle,varargin)
hFig=get(Handle,'parent');
ud=get(hFig,'userdata');
Dirs=ud.Dirs;
h=ud.h;
Dirs.sugName=get(h.felt2,'string');
Dirs.mainworkspace=get(h.felt1,'string');
ud.Dirs=Dirs;
set(hFig,'userdata',ud);
Show(Handle);

function Cancel_callback(Handle,varargin)
hFig=get(Handle,'parent');
Dirs.prjfile='';
Dirs.workspace='';
Dirs.sugName='';
ud.Dirs=Dirs;
set(hFig,'userdata',ud);
uiresume(hFig);

function Browse_callback(Handle,varargin)
Felt=get(Handle,'userdata');
PathName = uigetdir(pwd,'Select main workspace');
if ~(PathName==0)
    set(Felt,'string',PathName);
    Update_callback(Handle);
end

function Show(Handle)
hFig=get(Handle,'parent');
ud=get(hFig,'userdata');
Dirs=ud.Dirs;
h=ud.h;
Dirs.workspace=[Dirs.mainworkspace,filesep,Dirs.fix,'_',Dirs.sugName];
Dirs.prjfile=[Dirs.sugName,'.prj'];
set(h.txt1,'TooltipString',['Project workspace: ',Dirs.workspace],'string',['Project workspace: ',Dirs.workspace]);
set(h.txt2,'string',['Project filename: ',Dirs.prjfile]);
ud.Dirs=Dirs;
set(hFig,'userdata',ud);
