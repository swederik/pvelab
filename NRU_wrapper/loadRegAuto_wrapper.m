function project=loadRegAuto_wrapper(project,TaskIndex,MethodIndex,varargin)
% This method is called by the pipeline program. 
% It loads the AIR co-registration file into the project structure
% The AIR file has to be defined with MR image as standard file and 
% PET image as alignment file
%
% By Claus Svarer 20071211, NRU
%

global PETpath

%_____Retrieve info
AIRfile=strrep(PETpath,'.img','.air');
ImageIndex=1;

%_____Make changes to project

if exist(AIRfile,'file')==2
  %Check if headers are alright
  PETfile=fullfile(project.taskDone{TaskIndex}.inputfiles{1,1}.path,project.taskDone{TaskIndex}.inputfiles{ImageIndex,1}.name);
  PEThdr=ReadAnalyzeHdr(PETfile);
  MRfile=fullfile(project.taskDone{TaskIndex}.inputfiles{1,2}.path,project.taskDone{TaskIndex}.inputfiles{ImageIndex,2}.name);
  MRhdr=ReadAnalyzeHdr(MRfile);
  [A,Struct]=ReadAir(AIRfile);

  
  if ~all(Struct.hdrI.dim(1:3)==PEThdr.dim(1:3))||~all(Struct.hdrO.dim(1:3)==MRhdr.dim(1:3))
     if ~all(Struct.hdrO.dim(1:3)==PEThdr.dim(1:3))||~all(Struct.hdrI.dim(1:3)==MRhdr.dim(1:3))
        warndlg(['Dimensions in file: ',PETfile,'or',MRfile,' does not match dimensions of reslice file in AIR file.'],'Error');
        return;
     else
        PetToMR=0;
     end
  else
     PetToMR=1;
  end
        
  project=logProject(['Copying: ',AIRfile,'.* to project directory...'],project,TaskIndex,MethodIndex);       
  [status,message]=copyfile(AIRfile,project.sysinfo.workspace);
  if ~status
    project=logProject(['Copying of: ',AIRfile,'.* not completed!'],project,TaskIndex,MethodIndex);                   
    warndlg(['Copying files: ',AIRfile,' to project directory, following error was recieved: ',message],'Error');
    return;
  else
    if (PetToMR==1)
      project.taskDone{TaskIndex}.userdata.AIRfile{ImageIndex,1}.path=project.sysinfo.workspace;
      [pn,fn,ext]=fileparts(AIRfile);
      project.taskDone{TaskIndex}.userdata.AIRfile{ImageIndex,1}.name=[fn ext];
    else
      project.taskDone{TaskIndex}.userdata.AIRfile{ImageIndex,2}.path=project.sysinfo.workspace;
      [pn,fn,ext]=fileparts(AIRfile);
      project.taskDone{TaskIndex}.userdata.AIRfile{ImageIndex,2}.name=[fn ext];
    end
  end        
else
  warndlg(['Cant find file: ',AIRfile],'Error');
  msg=['Cant find AIR file:',AIRfile];
  project=logProject(msg,project,TaskIndex,MethodIndex);
  project.taskDone{TaskIndex}.error{end+1}=msg;
  return
end

project.taskDone{TaskIndex}.userdata.AIRfile{ImageIndex,1}.info='AIRfile';
