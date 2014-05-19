function project=loadSeg_nogui(project,TaskIndex,MethodIndex,varargin)
% This method is called by the pipeline program. 
% It loads three segmented files into the project structure.
% It checks if the loaded files are the same size and dimension as the
% loaded MR-image (a requirement).
%
% By Thomas Rask 140104, NRU
%

ImageIndex=1;

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
            disp(['Cant read headerfile: ',HdrStr],'Error');                
            return;
        end

        if ~(SEGhdr.dim==MRhdr.dim)
            disp(['Dimensions in file: ',HdrStr,' does not match loaded MRI.'],'Error');
            return;
        end
        if max(abs(SEGhdr.siz(1:3)-MRhdr.siz(1:3)))>1e-4
            disp(['Voxel size in file: ',HdrStr,' does not match loaded MRI.'],'Error');
            return;
        end
        if ~(SEGhdr.origin==MRhdr.origin)
            disp(['Origin in file: ',HdrStr,' does not match loaded MRI. Use Fix Analyzeheader tool to set origin in either loaded or segmentation file.'],'Error');
            return;
        end
        project=logProject(['Copying: ',Name,'.* to project directory...'],project,TaskIndex,MethodIndex);       
        [status,message]=copyfile([fullfile(Path,Name),'.*'],project.sysinfo.workspace);
        if ~status
            project=logProject(['Copying of: ',Name,'.* not completed!'],project,TaskIndex,MethodIndex);                   
            disp(['Copying files: ',fullfile(Path,Name),'.* to project directory, following error was recieved: ',message],'Error');
            return;
        else
            project.taskDone{TaskIndex}.userdata.segout{ImageIndex,i}.path=project.sysinfo.workspace;
            project.taskDone{TaskIndex}.userdata.segout{ImageIndex,i}.name=[Name,'.img'];
        end        
    else
        disp(['Cant find file: ',HdrStr],'Error');
        return
    end
end

project.taskDone{TaskIndex}.userdata.segout{ImageIndex,1}.info='Segmented Gray Matter';
project.taskDone{TaskIndex}.userdata.segout{ImageIndex,2}.info='Segmented White Matter';
project.taskDone{TaskIndex}.userdata.segout{ImageIndex,3}.info='Segmented CSF';
