function project=loadRPET_wrapper(project,TaskIndex,MethodIndex,varargin)
% This method is called by the pipeline program.
% It loads the coregistered PET file into the project structure.
% It checks if the loaded file is the same size and dimension and if it
% is coregistered to the Segmented.
%
% By Thomas Rask 140104, NRU
% Modified by Marco Comerci 11112005, IBB - CNR
%

flip=1;
addendum='';
if exist('spm','file')==2
    if ~strcmpi(spm('Ver'),'spm8')
        global defaults
        spm_defaults;
        flip=defaults.analyze.flip;
    end
end

if flip==0
    addendum=' -s';
end

%_______create GUI
color=[252/255 252/255 254/255];
Pos=project.handles.data.figuresize;
fWidth=300;
fHight=250;
Pos(1)=Pos(1)+Pos(3)/2-fWidth/2;
Pos(2)=Pos(2)+Pos(4)/2-fHight/2;
Pos(3)=fWidth;
Pos(4)=fHight;
hFig=figure('tag','loadRPET_wrapper_fig','position',Pos,'name','Load coregistered PET','menubar','none','resize','off','numberTitle','off','Color',color);%,'visible','off');
set(hFig,'userdata',project);

%Frame
frHight=fHight-55;
frPos=[6,fHight-frHight-5,fWidth-10,frHight];
uicontrol('parent',hFig,'style','frame','position',frPos,'BackgroundColor',color)

%Filefields
uicontrol('parent',hFig,'style','text','position',[15,fHight-43,260,20],'string','Coregistered PET (eg. r_PET.img):','HorizontalAlignment','left','BackgroundColor',color);
felt1=uicontrol('parent',hFig,'style','edit','position',[18,fHight-60,210,20],'string','Not selected','HorizontalAlignment','left');
uicontrol('parent',hFig,'style','pushbutton','position',[230,fHight-60,52,20],'string','Browse','callback',@Browse_callback,'userdata',felt1);

%Buttons
bHight=fHight-frHight-30;
Inf.TaskIndex=TaskIndex;
Inf.MethodIndex=MethodIndex;
Inf.felt1=felt1;
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
ImageIndex=1;

hFig=get(Handle,'parent');
project=get(hFig,'userdata');

%_____Make changes to project

%Check if headers are alright
MRfile=fullfile(project.taskDone{TaskIndex}.inputfiles{ImageIndex,2}.path,project.taskDone{TaskIndex}.inputfiles{ImageIndex,2}.name);
MRhdr=ReadAnalyzeHdr(MRfile);
for i=1:1
    Str=get(eval(['felt',num2str(i)]),'string');
    % Need conversion to Analyze...
    [file_pathstr,file_name,file_ext] = fileparts(Str);
    NEWPath=file_pathstr;
    
    switch file_ext
        case '.img'
            project=logProject('Imagefile: Analyze',project,TaskIndex,MethodIndex);
            [Path,Name]=fileparts(Str);
            HdrStr=fullfile(Path,[Name,'.hdr']);
            if exist(HdrStr)==2
                try
                    SEGhdr=ReadAnalyzeHdr(HdrStr);
                catch
                    warndlg(['Cant read headerfile: ',HdrStr],'Error');
                end
                
                if ~(SEGhdr.dim(1:3)==MRhdr.dim(1:3))
                    warndlg(['Dimensions in file: ',HdrStr,' does not match loaded MRI.'],'Error');
                    return;
                end
                if any(abs(SEGhdr.siz-MRhdr.siz)>0.01)
                    warndlg(['Voxel size in file: ',HdrStr,' does not match loaded MRI.'],'Error');
                    return;
                end
                if any(abs(SEGhdr.origin-MRhdr.origin)>0.01)
                    warndlg(['Origin in file: ',HdrStr,' does not match loaded MRI. Use Fix Analyzeheader tool to set origin in either loaded or segmentation file.'],'Error');
                    return;
                end
                project=logProject(['Copying: ',Name,'.* to project directory...'],project,TaskIndex,MethodIndex);
                [status,message]=copyfile([fullfile(Path,Name),'.*'],project.sysinfo.workspace);
                if ~status
                    project=logProject(['Copying of: ',Name,'.* not completed!'],project,TaskIndex,MethodIndex);
                    warndlg(['Copying files: ',fullfile(Path,Name),'.* to project directory, following error was received: ',message],'Error');
                else
                    project.taskDone{TaskIndex}.outputfiles{i}.path=project.sysinfo.workspace;
                    project.taskDone{TaskIndex}.outputfiles{i}.name=[Name,'.img'];
                end
            else
                warndlg(['Cant find file: ',HdrStr],'Error');
            end
        otherwise
            project=logProject('Imagefile: Dicom->Analyze, see Matlab command window for details...',project,TaskIndex,MethodIndex);
            path0=NEWPath;
            path1=project.sysinfo.systemdir;
            pathout=[project.sysinfo.workspace,filesep];
            cd (pathout)
            if length(pathout)<2
                cd ([path0 filesep]);
                pathout=cd;
            end
            path2=[path1,filesep,'IBB_wrapper',filesep,'d2a'];
            cd (path2);
            if ismac
                cmdline=['"' path2,filesep,'d2amac"',addendum,' "',path0,'" "',pathout(1:end-1),'"'];
            else
                cmdline=['"' path2,filesep,'d2a"',addendum,' "',path0,'" "',pathout(1:end-1),'"'];
            end
            result=unix(cmdline);
            if not(result==0)
                [project,msg]=logProject('Error in Dicom to Analyze module.',project,TaskIndex,MethodIndex);
                project.taskDone{TaskIndex}.error{end+1}=msg;
                return
            end
            newfn=['PET'];
            project.taskDone{TaskIndex}.outputfiles{i}.path=pathout;
            project.taskDone{TaskIndex}.outputfiles{i}.name=[newfn,'.img'];
            movefile([pathout,'0000.img'],[pathout,newfn,'.img']);
            movefile([pathout,'0000.hdr'],[pathout,newfn,'.hdr']);
            movefile([pathout,'0000.dat'],[pathout,newfn,'.dat']);
            cd ([path0]);
            HdrStr=fullfile(pathout,[newfn,'.hdr']);
            if exist(HdrStr)==2
                try
                    SEGhdr=ReadAnalyzeHdr(HdrStr);
                catch
                    warndlg(['Cant read headerfile: ',HdrStr],'Error');
                end
                
                if ~(SEGhdr.dim(1:3)==MRhdr.dim(1:3))
                    warndlg(['Dimensions in file: ',HdrStr,' does not match loaded MRI.'],'Error');
                    return;
                end
                if any(abs(SEGhdr.siz-MRhdr.siz)>0.01)
                    warndlg(['Voxel size in file: ',HdrStr,' does not match loaded MRI.'],'Error');
                    return;
                end
                if any(abs(SEGhdr.origin-MRhdr.origin)>0.01)
                    warndlg(['Origin in file: ',HdrStr,' does not match loaded MRI. Use Fix Analyzeheader tool to set origin in either loaded or segmentation file.'],'Error');
                    return;
                end
            else
                warndlg(['Cant find file: ',HdrStr],'Error');
            end
    end%switch ext
end

project.taskDone{TaskIndex}.outputfiles{1}.info='Coregistered PET';

project.taskDone{TaskIndex}.userdata.segoutReslice{1}.info='Coregistered segmented Gray Matter';
project.taskDone{TaskIndex}.userdata.segoutReslice{2}.info='Coregistered segmented White Matter';
project.taskDone{TaskIndex}.userdata.segoutReslice{3}.info='Coregistered segmented CSF';

project.taskDone{TaskIndex}.userdata.segoutReslice{1}.name=project.taskDone{TaskIndex-1}.userdata.segout{1}.name;
project.taskDone{TaskIndex}.userdata.segoutReslice{2}.name=project.taskDone{TaskIndex-1}.userdata.segout{2}.name;
project.taskDone{TaskIndex}.userdata.segoutReslice{3}.name=project.taskDone{TaskIndex-1}.userdata.segout{3}.name;

project.taskDone{TaskIndex}.userdata.segoutReslice{1}.path=project.taskDone{TaskIndex-1}.userdata.segout{1}.path;
project.taskDone{TaskIndex}.userdata.segoutReslice{2}.path=project.taskDone{TaskIndex-1}.userdata.segout{2}.path;
project.taskDone{TaskIndex}.userdata.segoutReslice{3}.path=project.taskDone{TaskIndex-1}.userdata.segout{3}.path;

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
[FileName,PathName] = uigetfile({'*.*','All Files (*.*)';'*.dcm;*.img','Image files (*.img,*.dcm)';'*.img','Analyze-files (*.img)';'*.dcm','DICOM-files (*.dcm)'},'Select the file');
if ~(FileName==0)
    set(Felt,'string',fullfile(PathName,FileName));
end
