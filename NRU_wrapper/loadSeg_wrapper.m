function project=loadSeg_wrapper(project,TaskIndex,MethodIndex,varargin)
% This method is called by the pipeline program. 
% It loads three segmented files into the project structure.
% It checks if the loaded files are the same size and dimension as the
% loaded MR-image (a requirement).
%
% By Thomas Rask 140104, NRU
%

%_______create GUI
color=[252/255 252/255 254/255];
Pos=project.handles.data.figuresize;
fWidth=300;
fHight=250;
Pos(1)=Pos(1)+Pos(3)/2-fWidth/2;
Pos(2)=Pos(2)+Pos(4)/2-fHight/2;
Pos(3)=fWidth;
Pos(4)=fHight;
hFig=figure('tag','loadSeg_wrapper_fig','position',Pos,'name','Load segmentation','menubar','none','resize','off','numberTitle','off','Color',color);%,'visible','off');
set(hFig,'userdata',project);

%Frame
frHight=fHight-55;
frPos=[6,fHight-frHight-5,fWidth-10,frHight];
uicontrol('parent',hFig,'style','frame','position',frPos,'BackgroundColor',color)

%Filefields
uicontrol('parent',hFig,'style','text','position',[15,fHight-43,260,20],...
    'string','Gray matter file (eg. blabla_seg1.img):',...
    'HorizontalAlignment','left','BackgroundColor',color);
felt1=uicontrol('parent',hFig,'style','edit','position',[18,fHight-60,210,20],...
    'string','Not selected','HorizontalAlignment','left','tag','felt1');
uicontrol('parent',hFig,'style','pushbutton','position',[230,fHight-60,52,20],...
    'string','Browse','callback',@Browse_callback,'userdata',felt1);


uicontrol('parent',hFig,'style','text','position',[15,fHight-43-50,260,20],...
    'string','White matter file (eg. blabla_seg2.img):',...
    'HorizontalAlignment','left','BackgroundColor',color);
felt2=uicontrol('parent',hFig,'style','edit','position',[18,fHight-60-50,210,20],...
    'string','Not selected','HorizontalAlignment','left','tag','felt2');
uicontrol('parent',hFig,'style','pushbutton','position',[230,fHight-60-50,52,20],...
    'string','Browse','callback',@Browse_callback,'userdata',felt2);

uicontrol('parent',hFig,'style','text','position',[15,fHight-43-100,260,20],...
    'string','CSF++ file (eg. blabla_seg3.img):',...
    'HorizontalAlignment','left','BackgroundColor',color);
felt3=uicontrol('parent',hFig,'style','edit','position',[18,fHight-60-100,210,20],...
    'string','Not selected','HorizontalAlignment','left','tag','felt3');
uicontrol('parent',hFig,'style','pushbutton','position',[230,fHight-60-100,52,20],...
    'string','Browse','callback',@Browse_callback,'userdata',felt3);

%Buttons
bHight=fHight-frHight-30;
Inf.TaskIndex=TaskIndex;
Inf.MethodIndex=MethodIndex;
Inf.felt1=felt1;
Inf.felt2=felt2;
Inf.felt3=felt3;
butOk=uicontrol('parent',hFig,'style','pushbutton','position',[75,15,70,bHight],'string','Ok','userdata',Inf,'callback',@Ok_callback);
butCan=uicontrol('parent',hFig,'style','pushbutton','position',[155,15,70,bHight],'string','Cancel','userdata',Inf,'callback',@Cancel_callback);


%Get changed project and out
uiwait(hFig);
project=get(hFig,'userdata');
delete(hFig);

function Ok_callback(Handle,varargin)
%_____Retrieve info
Inf=get(Handle,'userdata');
TaskIndex=Inf.TaskIndex;
MethodIndex=Inf.MethodIndex;
felt1=Inf.felt1;
felt2=Inf.felt2;
felt3=Inf.felt3;
ImageIndex=1;

hFig=get(Handle,'parent');
project=get(hFig,'userdata');

%_____Make changes to project

%Check if headers are alright
MRfile=fullfile(project.taskDone{TaskIndex}.inputfiles{1,2}.path,project.taskDone{TaskIndex}.inputfiles{ImageIndex,2}.name);
MRhdr=ReadAnalyzeHdr(MRfile);
for i=1:3
    Str=get(eval(['felt',num2str(i)]),'string');
    [Path,Name]=fileparts(Str);
    HdrStr=fullfile(Path,[Name,'.hdr']);
    if exist(HdrStr)==2
        try
            SEGhdr=ReadAnalyzeHdr(HdrStr);
        catch
            warndlg(['Cant read headerfile: ',HdrStr],'Error');                
            return;
        end

        if ~(SEGhdr.dim==MRhdr.dim)
            warndlg(['Dimensions in file: ',HdrStr,' does not match loaded MRI.'],'Error');
            return;
        end
        if max(abs(SEGhdr.siz(1:3)-MRhdr.siz(1:3)))>1e-4
            warndlg(['Voxel size in file: ',HdrStr,' does not match loaded MRI.'],'Error');
            return;
        end
        if ~(SEGhdr.origin==MRhdr.origin)
            warndlg(['Origin in file: ',HdrStr,' does not match loaded MRI. Use Fix Analyzeheader tool to set origin in either loaded or segmentation file.'],'Error');
            return;
        end
        project=logProject(['Copying: ',Name,'.* to project directory...'],project,TaskIndex,MethodIndex);       
        [status,message]=copyfile([fullfile(Path,Name),'.*'],project.sysinfo.workspace);
        if ~status
            project=logProject(['Copying of: ',Name,'.* not completed!'],project,TaskIndex,MethodIndex);                   
            warndlg(['Copying files: ',fullfile(Path,Name),'.* to project directory, following error was recieved: ',message],'Error');
            return;
        else
            project.taskDone{TaskIndex}.userdata.segout{ImageIndex,i}.path=project.sysinfo.workspace;
            project.taskDone{TaskIndex}.userdata.segout{ImageIndex,i}.name=[Name,'.img'];
        end        
    else
        warndlg(['Cant find file: ',HdrStr],'Error');
        return
    end
end

project.taskDone{TaskIndex}.userdata.segout{ImageIndex,1}.info='Segmented Gray Matter';
project.taskDone{TaskIndex}.userdata.segout{ImageIndex,2}.info='Segmented White Matter';
project.taskDone{TaskIndex}.userdata.segout{ImageIndex,3}.info='Segmented CSF';

set(hFig,'userdata',project);
uiresume(hFig);


function Cancel_callback(Handle,varargin)
%_____Retrieve info
Inf=get(Handle,'userdata');
TaskIndex=Inf.TaskIndex;
MethodIndex=Inf.MethodIndex;
hFig=get(Handle,'parent');
project=get(hFig,'userdata');

%_____Make changes to project
    msg='User abort, cancel pressed...';
    project=logProject(msg,project,TaskIndex,MethodIndex);
    project.taskDone{TaskIndex}.error{end+1}=msg;

set(hFig,'userdata',project);
uiresume(hFig);

function Browse_callback(Handle,varargin)
Felt=get(Handle,'userdata');
[FileName,PathName] = uigetfile('*.img','Select the Analyze img-file');
if ~(FileName==0)
  pos=findstr(FileName,'_seg');
  if isempty(pos)
    set(Felt,'string',fullfile(PathName,FileName));
  else
    for i=1:3
      h=findobj('tag',sprintf('felt%i',i));
      if ~isempty(findstr(get(h(1),'String'),'Not selected'))
	set(h(1),'String',fullfile(PathName,sprintf('%s_seg%i',FileName(1:pos(1)-1),i)));
      end	
    end
  end  
end

