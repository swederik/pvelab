function project=loadAir_wrapper(project,TaskIndex,MethodIndex,varargin);
% loadAir_wrapper is launched by the pipeline program when the method is
% run under the registration task. Its purpose is to load an already
% existing AIR-file into the project structure.
%
% SW version 090104TR
%

ImageIndex=1;

%Get airfile
[filename, pathname] = uigetfile(...
    {'*.air',  'AIR-files (*.m)'; ...
    '*.*',  'All Files (*.*)'}, ...
    'Pick an AIR-file');

if filename==0
    msg='User abort: Cancel selected.';
    project=logProject(msg,project,TaskIndex,MethodIndex);
    project.taskDone{TaskIndex}.error{end+1}=msg;
    return
end

wholefile=fullfile(pathname,filename);

%Read airfile
[A,Struct]=ReadAir(wholefile);

%Set strings for display in dialog
DimO=[num2str(Struct.hdrO.dim(1)),'x',num2str(Struct.hdrO.dim(2)),'x',num2str(Struct.hdrO.dim(3))];
DimI=[num2str(Struct.hdrI.dim(1)),'x',num2str(Struct.hdrI.dim(2)),'x',num2str(Struct.hdrI.dim(3))];

line1=sprintf('%10.2f %10.2f %10.2f %10.2f',A(1,1),A(1,2),A(1,3),A(1,4));
line2=sprintf('%10.2f %10.2f %10.2f %10.2f',A(2,1),A(2,2),A(2,3),A(2,4));
line3=sprintf('%10.2f %10.2f %10.2f %10.2f',A(3,1),A(3,2),A(3,3),A(3,4));
line4=sprintf('%10.2f %10.2f %10.2f %10.2f',A(4,1),A(4,2),A(4,3),A(4,4));


[Path,Struct.hdrO.name]=fileparts(Struct.hdrO.name);
[Path,Struct.hdrI.name]=fileparts(Struct.hdrI.name);

if isempty(Struct.hdrI.name)
    Struct.hdrI.name='not specified';
else
    Struct.hdrI.name=[Struct.hdrI.name,'.img'];
end

if isempty(Struct.hdrO.name)
    Struct.hdrO.name='not specified';
else
    Struct.hdrO.name=[Struct.hdrO.name,'.img'];
end

QStr=sprintf(['Reslice file (input): ',Struct.hdrI.name,' (dim: ',DimI,')\n',...
        'Standard file (output): ',Struct.hdrO.name,' (dim: ',DimO,')\n\n',...
        'Matrix in airfile:\n',...
        line1,'\n',...
        line2,'\n',...
        line3,'\n',...
        line4,'\n\n',...
        'Which transformation is the matrix performing?']);

%Try to find out transformation direction
pethdr=ReadAnalyzeHdr(...
    fullfile(project.taskDone{TaskIndex}.inputfiles{ImageIndex,1}.path,...
    project.taskDone{TaskIndex}.inputfiles{ImageIndex,1}.name));

if (pethdr.dim(1:3)==Struct.hdrI.dim(1:3))
    Direct='PET->MR';
elseif (pethdr.dim(1:3)==Struct.hdrO.dim(1:3))
    Direct='MR->PET';
else
    Direct='Cancel';
end

%Display question dialog
button = questdlg(QStr,...
'Select transformation','PET->MR','MR->PET','Cancel',Direct);
if strcmp(button,'PET->MR')
    project=logProject(['Copying ',filename,' to project directory.'],project,TaskIndex,MethodIndex);    
    [howgo]=copyfile(wholefile,project.sysinfo.workspace);
    project.taskDone{TaskIndex}.userdata.AIRfile{ImageIndex,1}.path=project.sysinfo.workspace;
    project.taskDone{TaskIndex}.userdata.AIRfile{ImageIndex,1}.name=filename;
elseif strcmp(button,'MR->PET')
    project=logProject(['Copying ',filename,' to project directory.'],project,TaskIndex,MethodIndex);
    [howgo]=copyfile(wholefile,project.sysinfo.workspace);
    project.taskDone{TaskIndex}.userdata.AIRfile{ImageIndex,2}.path=project.sysinfo.workspace;
    project.taskDone{TaskIndex}.userdata.AIRfile{ImageIndex,2}.name=filename;
elseif strcmp(button,'Cancel')
    msg='User abort: Cancel selected.';
    project=logProject(msg,project,TaskIndex,MethodIndex);
    project.taskDone{TaskIndex}.error{end+1}=msg;
    return
end