function project=loadGMROI_wrapper(project,TaskIndex,MethodIndex,varargin)
% This method is called by the pipeline program.
% It loads three segmented files into the project structure.
% It checks if the loaded files are the same size and dimension and if they
% are coregistered to the PET.
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
fHight=250;
Pos(1)=Pos(1)+Pos(3)/2-fWidth/2;
Pos(2)=Pos(2)+Pos(4)/2-fHight/2;
Pos(3)=fWidth;
Pos(4)=fHight;
hFig=figure('tag','loadGMROI_wrapper_fig','position',Pos,'name','Load labeled Brain','menubar','none','resize','off','numberTitle','off','Color',color);%,'visible','off');
set(hFig,'userdata',project);

%Frame
frHight=fHight-55;
frPos=[6,fHight-frHight-5,fWidth-10,frHight];
uicontrol('parent',hFig,'style','frame','position',frPos,'BackgroundColor',color)

%Filefields
uicontrol('parent',hFig,'style','text','position',[15,fHight-43,260,20],'string','GMROI file (eg. r_blabla_GMROI.img):','HorizontalAlignment','left','BackgroundColor',color);
felt1=uicontrol('parent',hFig,'style','edit','position',[18,fHight-60,210,20],'string','Not selected','HorizontalAlignment','left');
uicontrol('parent',hFig,'style','pushbutton','position',[230,fHight-60,52,20],'string','Browse','callback',@Browse_callback,'userdata',felt1);

uicontrol('parent',hFig,'style','text','position',[15,fHight-43-50,260,20],'string','ROI file (eg. LOBES_ROI.dat):','HorizontalAlignment','left','BackgroundColor',color);
felt2=uicontrol('parent',hFig,'style','edit','position',[18,fHight-60-50,210,20],'string','Not selected','HorizontalAlignment','left');
uicontrol('parent',hFig,'style','pushbutton','position',[230,fHight-60-50,52,20],'string','Browse','callback',@Browse_callback,'userdata',felt2);

uicontrol('parent',hFig,'style','text','position',[15,fHight-43-100,260,20],'string','PET file (eg. r_PET.img):','HorizontalAlignment','left','BackgroundColor',color);
felt3=uicontrol('parent',hFig,'style','edit','position',[18,fHight-60-100,210,20],'string','Not selected','HorizontalAlignment','left');
uicontrol('parent',hFig,'style','pushbutton','position',[230,fHight-60-100,52,20],'string','Browse','callback',@Browse_callback,'userdata',felt3);

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
end
for i=1:3
    Str=get(eval(['felt',num2str(i)]),'string');
    % Need conversion to Analyze...
    [file_pathstr,file_name,file_ext] = fileparts(Str);
    NEWPath=file_pathstr;
    
    if (strcmp(file_ext,'.img')==1)|(i==2)
        [Path,Name,EXT]=fileparts(Str);
        HdrStr=fullfile(Path,[Name,'.hdr']);
        if (exist(HdrStr)==2) | (i==2)
            if (i~=2)
                try
                    SEGhdr=ReadAnalyzeHdr(HdrStr);
                catch
                    warndlg(['Cant read headerfile: ',HdrStr],'Error');
                end
                
                if ~(SEGhdr.dim(1:3)==MRhdr.dim(1:3))
                    warndlg(['Dimensions in file: ',HdrStr,' does not match loaded GMROI.'],'Error');
                    return;
                end
                if any(abs(SEGhdr.siz-MRhdr.siz)>0.01)
                    warndlg(['Voxel size in file: ',HdrStr,' does not match loaded GMROI.'],'Error');
                    return;
                end
                if any(abs(SEGhdr.origin-MRhdr.origin)>0.01)
                    warndlg(['Origin in file: ',HdrStr,' does not match loaded GMROI. Use Fix Analyzeheader tool to set origin in either loaded or segmentation file.'],'Error');
                    return;
                end
            end
            pathout=project.sysinfo.workspace;
            if (i==1)
                project.taskDone{TaskIndex}.userdata.atlas.path=pathout;
                project.taskDone{TaskIndex}.userdata.atlas.name='r_volume_GMROI.img';
                project.taskDone{TaskIndex}.userdata.atlas.info='GMROI file';
                
                project.taskDone{TaskIndex}.outputfiles{ImageIndex,2}.path=pathout;
                project.taskDone{TaskIndex}.outputfiles{ImageIndex,2}.name='r_volume.img';
                project.taskDone{TaskIndex}.outputfiles{ImageIndex,2}.info='GMROI file';
                
                ffs=fullfile(Path,[Name,'.img']);
                [img,hdr]=ReadAnalyzeImg(ffs);
                hdr.lim=[255 0];
                hdr.path='';
                ffd=fullfile(pathout,'r_volume_GMROI.img');
                hdr.name=ffd;
                WriteAnalyzeImg(hdr,img);
                ffd=fullfile(pathout,'r_volume.img');
                hdr.name=ffd;
                WriteAnalyzeImg(hdr,img);
                ffd=fullfile(pathout,'r_volume_seg1.img');
                hdr.name=ffd;
                WriteAnalyzeImg(hdr,double((img>50)|(img==1))*255);
                ffd=fullfile(pathout,'r_volume_seg2.img');
                hdr.name=ffd;
                WriteAnalyzeImg(hdr,double(img==2)*255);
                ffd=fullfile(pathout,'r_volume_seg3.img');
                hdr.name=ffd;
                WriteAnalyzeImg(hdr,double(img==3)*255);

%                 ffd=fullfile(pathout,'r_volume_GMROI.img');
%                 if strcmp(ffs,ffd)==0
%                     copyfile(ffs,ffd);
%                 end
%                 
%                 ffd=fullfile(pathout,'r_volume.img');
%                 if strcmp(ffs,ffd)==0
%                     copyfile(ffs,ffd);
%                 end
%                 
%                 ffd=fullfile(pathout,'r_volume_seg1.img');
%                 if strcmp(ffs,ffd)==0
%                     copyfile(ffs,ffd);
%                 end
%                 
%                 ffd=fullfile(pathout,'r_volume_seg2.img');
%                 if strcmp(ffs,ffd)==0
%                     copyfile(ffs,ffd);
%                 end
%                 
%                 ffs=fullfile(Path,[Name,'.hdr']);
%                 ffd=fullfile(pathout,'r_volume_GMROI.hdr');
%                 if strcmp(ffs,ffd)==0
%                     copyfile(ffs,ffd);
%                 end
%                 
%                 ffs=fullfile(Path,[Name,'.hdr']);
%                 ffd=fullfile(pathout,'r_volume_seg1.hdr');
%                 if strcmp(ffs,ffd)==0
%                     copyfile(ffs,ffd);
%                 end
%                 
%                 ffs=fullfile(Path,[Name,'.hdr']);
%                 ffd=fullfile(pathout,'r_volume_seg2.hdr');
%                 if strcmp(ffs,ffd)==0
%                     copyfile(ffs,ffd);
%                 end
            end
            if (i==2)
                ffs=fullfile(Path,[Name,EXT]);
                ffd=fullfile(pathout,[Name,EXT]);
                if strcmp(ffs,ffd)==0
                    copyfile(ffs,ffd);
                end
                project.taskDone{TaskIndex}.userdata.map.path=pathout;
                project.taskDone{TaskIndex}.userdata.map.name=[Name,EXT];
                project.taskDone{TaskIndex}.userdata.map.info='ROI file';
                project.taskDone{TaskIndex}.userdata.sn.path=pathout;
                project.taskDone{TaskIndex}.userdata.sn.name='sn.mat';
                project.taskDone{TaskIndex}.userdata.sn.info='Normalization parameters file';
            end
            if (i==3)
                ffs=fullfile(Path,[Name,'.img']);
                ffd=fullfile(pathout,[Name,'.img']);
                if strcmp(ffs,ffd)==0
                    copyfile(ffs,ffd);
                end
                ffs=fullfile(Path,[Name,'.hdr']);
                ffd=fullfile(pathout,[Name,'.hdr']);
                if strcmp(ffs,ffd)==0
                    copyfile(ffs,ffd);
                end
                project.taskDone{TaskIndex}.outputfiles{ImageIndex,1}.path=pathout;
                project.taskDone{TaskIndex}.outputfiles{ImageIndex,1}.name=[Name,'.img'];
                project.taskDone{TaskIndex}.outputfiles{ImageIndex,1}.info='PET file';
            end
        else
            warndlg(['Cant find file: ',HdrStr],'Error');
        end
    else
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
        newfn=['File' num2str(i)];
        project.taskDone{TaskIndex}.userdata.segoutReslice{i}.path=pathout;
        project.taskDone{TaskIndex}.userdata.segoutReslice{i}.name=[newfn,'.img'];
        movefile([pathout,'0000.img'],[pathout,newfn,'.img']);
        movefile([pathout,'0000.hdr'],[pathout,newfn,'.hdr']);
        movefile([pathout,'0000.dat'],[pathout,newfn,'.dat']);
        cd ([path0]);
        HdrStr=fullfile(pathout,[newfn,'.hdr']);
        Name=newfn;
        Path=pathout;
        if (exist(HdrStr)==2)
            try
                SEGhdr=ReadAnalyzeHdr(HdrStr);
            catch
                warndlg(['Cant read headerfile: ',HdrStr],'Error');
            end
            
            if ~(SEGhdr.dim(1:3)==MRhdr.dim(1:3))
                warndlg(['Dimensions in file: ',HdrStr,' does not match loaded GMROI.'],'Error');
                return;
            end
            if any(abs(SEGhdr.siz-MRhdr.siz)>0.01)
                warndlg(['Voxel size in file: ',HdrStr,' does not match loaded GMROI.'],'Error');
                return;
            end
            if any(abs(SEGhdr.origin-MRhdr.origin)>0.01)
                warndlg(['Origin in file: ',HdrStr,' does not match loaded GMROI. Use Fix Analyzeheader tool to set origin in either loaded or segmentation file.'],'Error');
                return;
            end
            pathout=project.sysinfo.workspace;
            if (i==1)
                project.taskDone{TaskIndex}.userdata.atlas.path=pathout;
                project.taskDone{TaskIndex}.userdata.atlas.name='r_volume_GMROI.img';
                project.taskDone{TaskIndex}.userdata.atlas.info='GMROI file';
                
                project.taskDone{TaskIndex}.outputfiles{ImageIndex,2}.path=pathout;
                project.taskDone{TaskIndex}.outputfiles{ImageIndex,2}.name='r_volume.img';
                project.taskDone{TaskIndex}.outputfiles{ImageIndex,2}.info='GMROI file';
                
                ffs=fullfile(Path,[Name,'.img']);
                [img,hdr]=ReadAnalyzeImg(ffs);
                hdr.lim=[255 0];
                hdr.path='';
                ffd=fullfile(pathout,'r_volume_GMROI.img');
                hdr.name=ffd;
                WriteAnalyzeImg(hdr,img);
                ffd=fullfile(pathout,'r_volume.img');
                hdr.name=ffd;
                WriteAnalyzeImg(hdr,img);
                ffd=fullfile(pathout,'r_volume_seg1.img');
                hdr.name=ffd;
                WriteAnalyzeImg(hdr,double((img>50)|(img==1))*255);
                ffd=fullfile(pathout,'r_volume_seg2.img');
                hdr.name=ffd;
                WriteAnalyzeImg(hdr,double(img==2)*255);
                ffd=fullfile(pathout,'r_volume_seg3.img');
                hdr.name=ffd;
                WriteAnalyzeImg(hdr,double(img==3)*255);

%                 ffd=fullfile(pathout,'r_volume_GMROI.img');
%                 if strcmp(ffs,ffd)==0
%                     copyfile(ffs,ffd);
%                 end
%                 
%                 ffd=fullfile(pathout,'r_volume.img');
%                 if strcmp(ffs,ffd)==0
%                     copyfile(ffs,ffd);
%                 end
%                 
%                 ffd=fullfile(pathout,'r_volume_seg1.img');
%                 if strcmp(ffs,ffd)==0
%                     copyfile(ffs,ffd);
%                 end
%                 
%                 ffd=fullfile(pathout,'r_volume_seg2.img');
%                 if strcmp(ffs,ffd)==0
%                     copyfile(ffs,ffd);
%                 end
%                 
%                 ffs=fullfile(Path,[Name,'.hdr']);
%                 ffd=fullfile(pathout,'r_volume_GMROI.hdr');
%                 if strcmp(ffs,ffd)==0
%                     copyfile(ffs,ffd);
%                 end
%                 
%                 ffs=fullfile(Path,[Name,'.hdr']);
%                 ffd=fullfile(pathout,'r_volume_seg1.hdr');
%                 if strcmp(ffs,ffd)==0
%                     copyfile(ffs,ffd);
%                 end
%                 
%                 ffs=fullfile(Path,[Name,'.hdr']);
%                 ffd=fullfile(pathout,'r_volume_seg2.hdr');
%                 if strcmp(ffs,ffd)==0
%                     copyfile(ffs,ffd);
%                 end
            end
            if (i==3)
                ffs=fullfile(Path,[Name,'.img']);
                ffd=fullfile(pathout,[Name,'.img']);
                if strcmp(ffs,ffd)==0
                    copyfile(ffs,ffd);
                end
                ffs=fullfile(Path,[Name,'.hdr']);
                ffd=fullfile(pathout,[Name,'.hdr']);
                if strcmp(ffs,ffd)==0
                    copyfile(ffs,ffd);
                end
                project.taskDone{TaskIndex}.outputfiles{ImageIndex,1}.path=pathout;
                project.taskDone{TaskIndex}.outputfiles{ImageIndex,1}.name=[Name,'.img'];
                project.taskDone{TaskIndex}.outputfiles{ImageIndex,1}.info='PET file';
            end
        else
            warndlg(['Cant find file: ',HdrStr],'Error');
        end
    end
end

project.taskDone{1}.inputfiles{ImageIndex,1}=project.taskDone{TaskIndex}.outputfiles{ImageIndex,1};
project.taskDone{1}.inputfiles{ImageIndex,2}=project.taskDone{TaskIndex}.outputfiles{ImageIndex,2};

project.taskDone{TaskIndex}.inputfiles{ImageIndex,1}=project.taskDone{TaskIndex}.outputfiles{ImageIndex,1};
project.taskDone{TaskIndex}.inputfiles{ImageIndex,2}=project.taskDone{TaskIndex}.outputfiles{ImageIndex,2};

project.taskDone{TaskIndex}.show{1,1}.name='r_volume_GMROI.img';
project.taskDone{TaskIndex}.show{1,1}.path=project.sysinfo.workspace;
project.taskDone{TaskIndex}.show{1,1}.info='Labeled segmented image';

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
[FileName,PathName] = uigetfile({'*.*','All Files (*.*)';'*.dcm;*.img;*.dat;*.DAT','All supported files'},'Select the file');
if ~(FileName==0)
    cd(PathName);
    set(Felt,'string',fullfile(PathName,FileName));
end
