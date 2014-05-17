function project=FileLoad3MR_wrapper(project,TaskIndex,MethodIndex,varargin)
% FileLoad_wrapper function let the user choose filename of brain images if none is given in the project.
%    If files are not in the Analyze format they are converted to one (NOT DONE YET).
%    It checks for equal filename and size of loaded brain images.
%    Number of brain modalities to be loaded is given in 'project.pipeline.imageModality'.
%
% NOTE: The wrapper function do not load data it only checks the existence and the correctness of a file
%       and store it in the 'project.DoneTask{taskIndex}.inputfiles'.
%
% Input:
%   project     : Structure containing all information of actual pipeline
%   TaskIndex   : Index to active task in the project structure
%   MethodIndex : Index to used method in a TaskIndex in the project structure
%   varargin    : Abitrary number of input arguments. (NOT USED)
%
% Output:
%   project     : Return updated project
%
% Uses special functions:
%   logProject
%   ReadAnalyzeHdr
% ____________________________________________
% T. Dyrby, 120303, NRU
%
%SW version: 11112005MC

% TO DO:
%-OK 200503TD: Check using Imageindex and ImageModality
%- Implement function to read DICOM and convert to Analyze
%- Implement function to read SIMPEL (Hvidovre) and convert to Analyze
% -OK 180808TD: Setup Matlab path for loadede files

% TO DO:
%-OK 09092003MC: add DICOM support, store some DICOM fields in info field

%______ Initialise
%__________ Image information
project.pipeline.imageModality={'PET','T1-W','T2-W','PD-W'}; %Name and order of image modalities to be loaded
noModalities=length(project.pipeline.imageModality);
ImageIndex=project.pipeline.imageIndex(1);

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
for ModalityIndex=1:noModalities
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

%______ Check if files already are loaded
for ModalityIndex=1:noModalities
    %     filename=fullfile('',project.taskDone{TaskIndex}.inputfiles{ImageIndex,ModalityIndex}.path,project.taskDone{TaskIndex}.inputfiles{ImageIndex,ModalityIndex}.name);
    %     if(exist(filename))
    %         imagefile{ModalityIndex}=filename;
    %     else
    imagefile{ModalityIndex}='';
    %     end
end

%________ Load both Structural and Functional images
for i=1:noModalities
    % Check if image already exist...
    if(~isempty(imagefile{i}) && exist(imagefile{i},'file')==2)
        msg=sprintf('Error: No Reload of %s image!!',project.taskDone{TaskIndex}.command{i});
        continue %Reload
    end
    
    % Choose image file...
    while 1   %If not loaded
        [NEWname,NEWpath]=uigetfile(...
            {   '*.*',  'All Files (*.*)';...
            '*.dcm;*.img','Image files (*.img,*.dcm)'; ...
            '*.img',  'Analyze-files (*.img)'; ...
            '*.dcm','DICOM-files (*.dcm)'} ...
            ,sprintf('Load a %s file',project.taskDone{TaskIndex}.command{i}));
        
        %Check if a file is selected
        if(NEWname==0)
            msg=sprintf('Error: No image files are load: %s ',project.taskDone{TaskIndex}.command{i});
            [project,msg]=logProject(msg,project,TaskIndex,MethodIndex);
            project.taskDone{TaskIndex}.error{end+1}=msg;
            return
        else
            if(NEWpath~=0)
                addpath(NEWpath);
                project.sysinfo.tmp_workspace{end+1}=NEWpath;%To be removed on exit
                cd(NEWpath);%ChangeDir
                
                %Log info
                project=logProject(sprintf('ChangeDir:%s',pwd),project,TaskIndex,MethodIndex);
            end
            break%A file is selected
        end
    end%while
    
    % Need conversion to Analyze...
    [file_pathstr,file_name,file_ext] = fileparts(NEWname);
    
    switch file_ext
        case '.img'
            project=logProject('Imagefile: Analyze',project,TaskIndex,MethodIndex);
            imagefile{i}=[NEWpath,NEWname];
            [bla1,rawName,bla2]=fileparts(imagefile{i});
            outFile=fullfile(NEWpath,rawName);
            [status,message,messageid]=copyfile([outFile,'.dat'],project.sysinfo.workspace);
            [status,message,messageid]=copyfile([outFile,'.hdr'],project.sysinfo.workspace);
            [status,message,messageid]=copyfile([outFile,'.img'],project.sysinfo.workspace);
            imagefile{i}=fullfile(project.sysinfo.workspace,NEWname);
        case '.nii'
            project=logProject('Imagefile: Nifti->Analyze, see Matlab command window for details...',project,TaskIndex,MethodIndex);
            tmpimagefile=[NEWpath,NEWname];
            [status,message,messageid]=copyfile(tmpimagefile,project.sysinfo.workspace);
            %Register copied Nifti file in project structure
            project.taskDone{TaskIndex}.userdata.niiinputfile{ImageIndex,i}.path=project.sysinfo.workspace;
            project.taskDone{TaskIndex}.userdata.niiinputfile{ImageIndex,i}.name=NEWname;
            project.taskDone{TaskIndex}.userdata.niiinputfile{ImageIndex,i}.info='Nifti input file (before conversion to Analyze)';
            %
            fprintf('Converting Nifti->Analyze %s\n',tmpimagefile);
            Nifti2Analyze(fullfile(project.sysinfo.workspace,NEWname),16);
            %
            [pn,fn,ext]=fileparts(NEWname);
            imagefile{i}=fullfile(project.sysinfo.workspace,[fn '.img']);
        otherwise
            project=logProject('Imagefile: Dicom->Analyze, see Matlab command window for details...',project,TaskIndex,MethodIndex);
            path0=NEWpath;
            path1=project.sysinfo.systemdir;
            pathout=[project.sysinfo.mainworkspace,filesep];
            if isdir([pathout,'tmp'])
                rmdir([pathout,'tmp'],'s');
            end
            cd (pathout)
            if length(pathout)<2
                cd ([path0 filesep]);
                pathout=cd;
            end
            path2=[path1,filesep,'IBB_wrapper',filesep,'d2a'];
            cd (path2);
            if ismac
                cmdline=['"' path2,filesep,'d2amac"',addendum,' "',path0(1:end-1),'" "',pathout(1:end-1),'"'];
            else
                cmdline=['"' path2,filesep,'d2a"',addendum,' "',path0(1:end-1),'" "',pathout(1:end-1),'"'];
            end
            result=unix(cmdline);
            if not(result==0)
                [project,msg]=logProject('Error in Dicom to Analyze module.',project,TaskIndex,MethodIndex);
                project.taskDone{TaskIndex}.error{end+1}=msg;
                return
            end
            %Getting file info
            fid=fopen([pathout,'0000.dat']);
            TR='0';
            TE='0';
            B0='0';
            PN='Unknown';
            SD='Unknown';
            RI='0';
            RS='1';
            FA='0';
            if not(fid==-1),
                while not (feof(fid)),
                    s=fgetl(fid);
                    if strncmp(s,'Patient name : ',15),
                        PN=s(16:end);
                    end
                    if strncmp(s,'Magnetic field : ',17),
                        B0=s(18:end);
                    end
                    if strncmp(s,'Study date : ',13),
                        SD=s(14:end);
                    end
                    if strncmp(s,'TR : ',5),
                        TR=s(6:end);
                    end
                    if strncmp(s,'TE : ',5),
                        TE=s(6:end);
                    end
                    if strncmp(s,'Rescale intercept : ',20),
                        RI=s(21:end);
                    end
                    if strncmp(s,'Rescale slope : ',16),
                        RS=s(17:end);
                    end
                    if strncmp(s,'Flip angle : ',13),
                        FA=s(14:end);
                    end
                end
                fclose(fid);
            end
            project.taskDone{TaskIndex}.outputfiles{ImageIndex,i}.info.patientName=PN;
            project.taskDone{TaskIndex}.outputfiles{ImageIndex,i}.info.studyDate=SD;
            project.taskDone{TaskIndex}.outputfiles{ImageIndex,i}.info.TR=TR;
            project.taskDone{TaskIndex}.outputfiles{ImageIndex,i}.info.TE=TE;
            project.taskDone{TaskIndex}.outputfiles{ImageIndex,i}.info.rescaleIntercept=RI;
            project.taskDone{TaskIndex}.outputfiles{ImageIndex,i}.info.rescaleSlope=RS;
            project.taskDone{TaskIndex}.outputfiles{ImageIndex,i}.info.flipAngle=FA;
            project.taskDone{TaskIndex}.outputfiles{ImageIndex,i}.info.magneticField=B0;
            project.taskDone{TaskIndex}.outputfiles{ImageIndex,i}.moveToWorkspace=1; %Checked in checkOut
            newfn=['file' num2str(i-1)];
            imagefile{i}=[pathout,newfn,'.img'];
            movefile([pathout,'0000.img'],[pathout,newfn,'.img']);
            movefile([pathout,'0000.hdr'],[pathout,newfn,'.hdr']);
            movefile([pathout,'0000.dat'],[pathout,newfn,'.dat']);
            %delete([pathout,'0*.*']);
            cd ([path0]);
    end%switch ext
    %Register Analyze input file in project structure
    [pn,fn,ext]=fileparts(imagefile{i});
    project.taskDone{TaskIndex}.userdata.anainputfile{ImageIndex,i}.path=project.sysinfo.workspace;
    project.taskDone{TaskIndex}.userdata.anainputfile{ImageIndex,i}.name=[fn ext];
    project.taskDone{TaskIndex}.userdata.anainputfile{ImageIndex,i}.info='Analyze input file (after conversion to Analyze)';
end%end for

%_______ Check which is structural image (high resolution) and functional image (low resolution)
for i=1:noModalities
    hdr{i}=ReadAnalyzeHdr(imagefile{i});
end

%________ Error check: same name
%if(strcmp(hdr{1}.name,hdr{2}.name))
%    [project,msg]=logProject('Error: Equal names',project,TaskIndex,MethodIndex);
%    project.taskDone{TaskIndex}.error{end+1}=msg;
%    return
%end

%________ Error check: same size
%if(prod(hdr{1}.siz)==prod(hdr{2}.siz))
%    [project,msg]=logProject('Error: Equal size',project,TaskIndex,MethodIndex);
%    project.taskDone{TaskIndex}.error{end+1}=msg;
%    return
%end

%Looking for the PET
PETindex=1;
%for(i=1:noModalities)
%    if(prod(hdr{i}.siz)<prod(hdr{PETindex}.siz))%compare size of voxel dimensions [mm]
%        PETindex=i;
%    end
%end

%Looking for the T1W
T1Windex=2;
for i=2:noModalities
    if isfield(project.taskDone{TaskIndex}.outputfiles{ImageIndex,i}.info,TR)
        if isfield(project.taskDone{TaskIndex}.outputfiles{ImageIndex,T1Windex}.info,TR)
            if project.taskDone{TaskIndex}.outputfiles{ImageIndex,i}.info.TR<project.taskDone{TaskIndex}.outputfiles{ImageIndex,T1Windex}.info.TR
                T1Windex=i;
            end
        end
    end
end

%Looking for the T2W
T2Windex=3;
for i=2:noModalities
    if isfield(project.taskDone{TaskIndex}.outputfiles{ImageIndex,i}.info,TE)
        if isfield(project.taskDone{TaskIndex}.outputfiles{ImageIndex,T2Windex}.info,TE)
            if project.taskDone{TaskIndex}.outputfiles{ImageIndex,i}.info.TE>project.taskDone{TaskIndex}.outputfiles{ImageIndex,T2Windex}.info.TE
                T2Windex=i;
            end
        end
    end
end

PDWindex=4;

%Looking for the PDW
if (PETindex~=1) && (T1Windex~=1) && (T2Windex~=1)
    PDWindex=1;
end

if (PETindex~=2) && (T1Windex~=2) && (T2Windex~=2)
    PDWindex=2;
end

if (PETindex~=3) && (T1Windex~=3) && (T2Windex~=3)
    PDWindex=3;
end

%Sorting images...
info1=project.taskDone{TaskIndex}.outputfiles{ImageIndex,PETindex}.info;
info2=project.taskDone{TaskIndex}.outputfiles{ImageIndex,T1Windex}.info;
info3=project.taskDone{TaskIndex}.outputfiles{ImageIndex,T2Windex}.info;
info4=project.taskDone{TaskIndex}.outputfiles{ImageIndex,PDWindex}.info;
project.taskDone{TaskIndex}.outputfiles{ImageIndex,1}.info=info1;
project.taskDone{TaskIndex}.outputfiles{ImageIndex,2}.info=info2;
project.taskDone{TaskIndex}.outputfiles{ImageIndex,3}.info=info3;
project.taskDone{TaskIndex}.outputfiles{ImageIndex,4}.info=info4;
temp1=imagefile{PETindex};
temp2=imagefile{T1Windex};
temp3=imagefile{T2Windex};
temp4=imagefile{PDWindex};
imagefile{1}=temp1;
imagefile{2}=temp2;
imagefile{3}=temp3;
imagefile{4}=temp4;

%_______ Get filenames
for i=1:noModalities
    [file_pathstr,file_name,file_ext] = fileparts(imagefile{i});
    project.taskDone{TaskIndex}.outputfiles{ImageIndex,i}.name=[file_name,file_ext];
    project.taskDone{TaskIndex}.outputfiles{ImageIndex,i}.path=file_pathstr;
end

%Create warning if problem-files are loaded
WarnStr='';
for i=1:noModalities
    hdr{i}=ReadAnalyzeHdr(imagefile{i});
    if hdr{i}.pre==32
        WarnStr=sprintf([WarnStr,project.taskDone{TaskIndex}.outputfiles{ImageIndex,i}.name,' is a 32bit file. SPM2 is not compatible with this file. \n']);
    end
    if all(hdr{i}.origin==1)
        WarnStr=sprintf([WarnStr,project.taskDone{TaskIndex}.outputfiles{ImageIndex,i}.name,' has origin set to [1,1,1]. SPM2 needs either a correct origin or a zero origin to work. Use the Fix Analyze-header tool to reset origin to zero. \n']);
    end
end
if ~isempty(WarnStr)
    h=warndlg(WarnStr,'Warning!');
    waitfor(h);
end

%_____ Create project if it does not exist
project=pip_createProject(project,TaskIndex,MethodIndex,0);

%Move output from task 1 (other than original files) to project workdir
%Files marked with a 'moveToWorkspace' field are moved.
for t=1:length(project.pipeline.imageModality)
    outStruc=project.taskDone{1}.outputfiles{ImageIndex,t};
    [bla1,rawName,bla2]=fileparts(outStruc.name);
    outFile=fullfile('',outStruc.path,rawName);
    if isfield(outStruc,'moveToWorkspace')
        [status,message,messageid]=movefile([outFile,'.dat'],project.sysinfo.workspace);
        [status,message,messageid]=movefile([outFile,'.hdr'],project.sysinfo.workspace);
        [status,message,messageid]=movefile([outFile,'.img'],project.sysinfo.workspace);
        if status
            outStruc.path=project.sysinfo.workspace;
            outStruc=rmfield(outStruc,'moveToWorkspace');
        end;
        project.taskDone{1}.outputfiles{ImageIndex,t}=outStruc;
    end;
end;

