function project=loadAll_wrapper(project,TaskIndex,MethodIndex,varargin)
% This method is called by the pipeline program.
% It loads three segmented files and a PET file into the project structure.
% It checks if the loaded files are the same size and dimension and if they
% are coregistered.
%
% By Thomas Rask 140104, NRU
% Modified by Marco Comerci 11112005, IBB - CNR
%

%______ Initialise
%__________ Image information
project.pipeline.imageModality={'PET','T1-W'}; %Name and order of image modalities to be loaded
noModalities=length(project.pipeline.imageModality);
project.pipeline.imageIndex=1; %(FOR FUTURE USE) Number of loaded different images
ImageIndex=1; %(FOR FUTURE USE) Number of loaded different images

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

%Create out,in and show filefields
for(ModalityIndex=1:noModalities)
    project.taskDone{TaskIndex}.inputfiles{ImageIndex,ModalityIndex}.path='';
    project.taskDone{TaskIndex}.inputfiles{ImageIndex,ModalityIndex}.name='' ;
    project.taskDone{TaskIndex}.inputfiles{ImageIndex,ModalityIndex}.info='';
    
    project.taskDone{TaskIndex}.outputfiles{ImageIndex,ModalityIndex}.path='';
    project.taskDone{TaskIndex}.outputfiles{ImageIndex,ModalityIndex}.name='';
    project.taskDone{TaskIndex}.outputfiles{ImageIndex,ModalityIndex}.info='';
    
    project.taskDone{TaskIndex}.show{ImageIndex,ModalityIndex}.name='';
    project.taskDone{TaskIndex}.show{ImageIndex,ModalityIndex}.path='';
    project.taskDone{TaskIndex}.show{ImageIndex,ModalityIndex}.info='';
end

%______ Load 'commands' of structural information
project.taskDone{TaskIndex}.command=project.pipeline.imageModality;

project.taskDone{1}.inputfiles{1,1}.name='Untitled';
project.taskDone{1}.inputfiles{1,2}.name='Untitled';

project.taskDone{1}.outputfiles{1,1}.name='Untitled';
project.taskDone{1}.outputfiles{1,2}.name='Untitled';

project.taskDone{1}.inputfiles{1,1}.path='';
project.taskDone{1}.inputfiles{1,2}.path='';

project.taskDone{1}.outputfiles{1,1}.path='';
project.taskDone{1}.outputfiles{1,2}.path='';

project.taskDone{1}.inputfiles{1,1}.info='';
project.taskDone{1}.inputfiles{1,2}.info='';

project.taskDone{1}.outputfiles{1,1}.info='';
project.taskDone{1}.outputfiles{1,2}.info='';

if strcmp(project.sysinfo.prjfile,'')
    project=checkOut(project,TaskIndex,MethodIndex,varargin);
end

%_______create GUI
color=[252/255 252/255 254/255];
Pos=project.handles.data.figuresize;
fWidth=300;
fHight=300;
Pos(1)=Pos(1)+Pos(3)/2-fWidth/2;
Pos(2)=Pos(2)+Pos(4)/2-fHight/2;
Pos(3)=fWidth;
Pos(4)=fHight;
hFig=figure('tag','loadAll_wrapper_fig','position',Pos,'name','Load coregistered PET and segmentation','menubar','none','resize','off','numberTitle','off','Color',color);%,'visible','off');
set(hFig,'userdata',project);

%Frame
frHight=fHight-55;
frPos=[6,fHight-frHight-5,fWidth-10,frHight];
uicontrol('parent',hFig,'style','frame','position',frPos,'BackgroundColor',color)

%Filefields
uicontrol('parent',hFig,'style','text','position',[15,fHight-43,260,20],'string','Gray matter file (eg. r_blabla_seg1.img):','HorizontalAlignment','left','BackgroundColor',color);
felt1=uicontrol('parent',hFig,'style','edit','position',[18,fHight-60,210,20],'string','Not selected','HorizontalAlignment','left');
uicontrol('parent',hFig,'style','pushbutton','position',[230,fHight-60,52,20],'string','Browse','callback',@Browse_callback,'userdata',felt1);

uicontrol('parent',hFig,'style','text','position',[15,fHight-43-40,260,20],'string','White matter file (eg. r_blabla_seg2.img):','HorizontalAlignment','left','BackgroundColor',color);
felt2=uicontrol('parent',hFig,'style','edit','position',[18,fHight-60-40,210,20],'string','Not selected','HorizontalAlignment','left');
uicontrol('parent',hFig,'style','pushbutton','position',[230,fHight-60-40,52,20],'string','Browse','callback',@Browse_callback,'userdata',felt2);

uicontrol('parent',hFig,'style','text','position',[15,fHight-43-80,260,20],'string','CSF++ file (eg. r_blabla_seg3.img):','HorizontalAlignment','left','BackgroundColor',color);
felt3=uicontrol('parent',hFig,'style','edit','position',[18,fHight-60-80,210,20],'string','Not selected','HorizontalAlignment','left');
uicontrol('parent',hFig,'style','pushbutton','position',[230,fHight-60-80,52,20],'string','Browse','callback',@Browse_callback,'userdata',felt3);

uicontrol('parent',hFig,'style','text','position',[15,fHight-43-120,260,20],'string','PET file (eg. r_PET.img):','HorizontalAlignment','left','BackgroundColor',color);
felt4=uicontrol('parent',hFig,'style','edit','position',[18,fHight-60-120,210,20],'string','Not selected','HorizontalAlignment','left');
uicontrol('parent',hFig,'style','pushbutton','position',[230,fHight-60-120,52,20],'string','Browse','callback',@Browse_callback,'userdata',felt4);

uicontrol('parent',hFig,'style','text','position',[15,fHight-43-160,260,20],'string','T1W file (eg. r_T1W.img, optional):','HorizontalAlignment','left','BackgroundColor',color);
felt5=uicontrol('parent',hFig,'style','edit','position',[18,fHight-60-160,210,20],'string','Not_selected','HorizontalAlignment','left');
uicontrol('parent',hFig,'style','pushbutton','position',[230,fHight-60-160,52,20],'string','Browse','callback',@Browse_callback,'userdata',felt5);

%Buttons
bHight=fHight-frHight-30;
Inf.TaskIndex=TaskIndex;
Inf.MethodIndex=MethodIndex;
Inf.felt1=felt1;
Inf.felt2=felt2;
Inf.felt3=felt3;
Inf.felt4=felt4;
Inf.felt5=felt5;
butOk=uicontrol('parent',hFig,'style','pushbutton','position',[75,15,70,bHight],'string','Ok','userdata',Inf,'callback',@Ok_callback);
butCan=uicontrol('parent',hFig,'style','pushbutton','position',[155,15,70,bHight],'string','Cancel','userdata',Inf,'callback',@Cancel_callback);

%Get changed project and out
uiwait(hFig);
project=get(hFig,'userdata');
set(project.handles.h_mainfig,'userdata',project);
delete(hFig);

function Ok_callback(Handle,varargin)
%_____Retrieve info
Inf=get(Handle,'userdata');
TaskIndex=Inf.TaskIndex;
MethodIndex=Inf.MethodIndex;
felt1=Inf.felt1;
felt2=Inf.felt2;
felt3=Inf.felt3;
felt4=Inf.felt4;
felt5=Inf.felt5;
ImageIndex=1;

hFig=get(Handle,'parent');
project=get(hFig,'userdata');

%_____Make changes to project

%Check if headers are alright
MRfile=get(felt1,'string');
[file_pathstr,file_name,file_ext] = fileparts(MRfile);
if strcmp(file_ext,'.img')==1
    MRhdr=ReadAnalyzeHdr(MRfile);
else
    if exist(MRfile)==2
        NEWPath=file_pathstr;
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
        MRhdr=ReadAnalyzeHdr(fullfile(pathout,'0000.img'));
    else
        warndlg(['Cant find file: ',MRfile],'Error');
        return
    end
end
for i=1:5
    Str=get(eval(['felt',num2str(i)]),'string');
    if strcmp(Str,'Not_selected')==1
        Str=get(felt1,'string');
    end
    % Need conversion to Analyze...
    [file_pathstr,file_name,file_ext] = fileparts(Str);
    NEWPath=file_pathstr;
    
    switch lower(file_ext)
        case '.img'
            project=logProject('Imagefile: Analyze',project,TaskIndex,MethodIndex);
            [Path,Name]=fileparts(Str);
            HdrStr=fullfile(Path,[Name,'.hdr']);
            if exist(HdrStr)==2
                try
                    SEGhdr=ReadAnalyzeHdr(HdrStr);
                catch
                    if (i<3)
                        warndlg(['Cant read headerfile: ',HdrStr],'Error');
                        return;
                    end
                end
                
                if ~(SEGhdr.dim(1:3)==MRhdr.dim(1:3))
                    warndlg(['Dimensions in file: ',HdrStr,' does not match loaded segmented.'],'Error');
                    return;
                end
                if any(abs(SEGhdr.siz-MRhdr.siz)>0.01)
                    warndlg(['Voxel size in file: ',HdrStr,' does not match loaded segmented.'],'Error');
                    return;
                end
                if any(abs(SEGhdr.origin-MRhdr.origin)>0.01)
                    warndlg(['Origin in file: ',HdrStr,' does not match loaded segmented. Use Fix Analyzeheader tool to set origin in either loaded or segmentation file.'],'Error');
                    return;
                end
                project=logProject(['Copying: ',Name,'.* to project directory...'],project,TaskIndex,MethodIndex);
                ffs=fullfile(Path,[Name,'.img']);
                ffd=fullfile(project.sysinfo.workspace,[Name,'.img']);
                if strcmp(ffs,ffd)==0
                    copyfile(ffs,ffd);
                end
                ffs=fullfile(Path,[Name,'.hdr']);
                ffd=fullfile(project.sysinfo.workspace,[Name,'.hdr']);
                if strcmp(ffs,ffd)==0
                    copyfile(ffs,ffd);
                end
                project.taskDone{TaskIndex}.userdata.segoutReslice{i}.path=project.sysinfo.workspace;
                project.taskDone{TaskIndex}.userdata.segoutReslice{i}.name=[Name,'.img'];
            else
                if (i<3)
                    warndlg(['Cant find file: ',HdrStr],'Error');
                    return
                end
            end
        otherwise
            if exist(Str)==2
                project=logProject('Imagefile: Dicom->Analyze, see Matlab command window for details...',project,TaskIndex,MethodIndex);
                path0=NEWPath;
                path1=project.sysinfo.systemdir;
                pathout=[project.sysinfo.workspace,filesep];
                cd (pathout)
                if length(pathout)<2
                    cd ([path0 filesep]);
                    pathout=cd;
                end
                pathout=[pathout filesep];
                path2=[path1,filesep,'IBB_wrapper',filesep,'d2a'];
                cd (path2);
                if ismac
                    cmdline=['"' path2,filesep,'d2amac"',addendum,' "',path0,'" "',pathout,'"'];
                else
                    cmdline=['"' path2,filesep,'d2a"',addendum,' "',path0,'" "',pathout,'"'];
                end
                result=unix(cmdline);
                if not(result==0)
                    [project,msg]=logProject('Warning: error in Dicom to Analyze module.',project,TaskIndex,MethodIndex);
                    project.taskDone{TaskIndex}.error{end+1}=msg;
                end
                newfn=['File' num2str(i)];
                project.taskDone{TaskIndex}.userdata.segoutReslice{i}.path=pathout;
                project.taskDone{TaskIndex}.userdata.segoutReslice{i}.name=[newfn,'.img'];
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
                        if (i~=3)
                            warndlg(['Dimensions in file: ',HdrStr,' does not match loaded segmented.'],'Error');
                            return;
                        end
                    end
                    if (i<3)
                        if any(abs(SEGhdr.siz-MRhdr.siz)>0.01)
                            warndlg(['Voxel size in file: ',HdrStr,' does not match loaded segmented.'],'Error');
                            return;
                        end
                        if any(abs(SEGhdr.origin-MRhdr.origin)>0.01)
                            warndlg(['Origin in file: ',HdrStr,' does not match loaded segmented. Use Fix Analyzeheader tool to set origin in either loaded or segmentation file.'],'Error');
                            return;
                        end
                    end
                else
                    warndlg(['Cant find file: ',HdrStr],'Error');
                end
            else
                warndlg(['Cant find file: ',Str],'Error');
            end
    end%switch ext
end

project.taskDone{TaskIndex}.userdata.segoutReslice{1}.info='Coregistered segmented Gray Matter';
project.taskDone{TaskIndex}.userdata.segoutReslice{2}.info='Coregistered segmented White Matter';
project.taskDone{TaskIndex}.userdata.segoutReslice{3}.info='Coregistered segmented CSF';
project.taskDone{TaskIndex}.outputfiles{ImageIndex,1}.path=project.sysinfo.workspace;
project.taskDone{TaskIndex}.outputfiles{ImageIndex,1}.name=project.taskDone{TaskIndex}.userdata.segoutReslice{4}.name;
project.taskDone{TaskIndex}.outputfiles{ImageIndex,1}.info='PET file';
project.taskDone{TaskIndex}.outputfiles{ImageIndex,2}.path=project.sysinfo.workspace;
project.taskDone{TaskIndex}.outputfiles{ImageIndex,2}.name=project.taskDone{TaskIndex}.userdata.segoutReslice{1}.name;
project.taskDone{TaskIndex}.outputfiles{ImageIndex,2}.info='T1W file';

fStr=fullfile(project.sysinfo.workspace,project.taskDone{TaskIndex}.userdata.segoutReslice{5}.name);
if exist(fStr)==2
    project.taskDone{TaskIndex}.outputfiles{ImageIndex,2}.name=project.taskDone{TaskIndex}.userdata.segoutReslice{5}.name;
end
project.taskDone{1}.inputfiles{ImageIndex,1}=project.taskDone{TaskIndex}.outputfiles{ImageIndex,1};
project.taskDone{1}.inputfiles{ImageIndex,2}=project.taskDone{TaskIndex}.outputfiles{ImageIndex,2};

project.taskDone{TaskIndex}.inputfiles{ImageIndex,1}=project.taskDone{TaskIndex}.outputfiles{ImageIndex,1};
project.taskDone{TaskIndex}.inputfiles{ImageIndex,2}=project.taskDone{TaskIndex}.outputfiles{ImageIndex,2};

project.taskDone{1}.outputfiles{ImageIndex,1}=project.taskDone{TaskIndex}.outputfiles{ImageIndex,1};
project.taskDone{1}.outputfiles{ImageIndex,2}=project.taskDone{TaskIndex}.outputfiles{ImageIndex,2};

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
[FileName,PathName] = uigetfile({'*.img','Analyze-files (*.img)';'*.dcm;*.img','Image files (*.img,*.dcm)';'*.dcm','DICOM-files (*.dcm)';'*.*','All Files (*.*)'},'Select the file');
if ~(FileName==0)
    cd(PathName);
    set(Felt,'string',fullfile(PathName,FileName));
end
