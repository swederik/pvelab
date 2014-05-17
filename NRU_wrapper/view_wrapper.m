function project=view_wrapper(project,TaskIndex,MethodIndex,varargin)
% View wrapper for all viewers: Inspect, Browse3D and Browse2D
%
% Search for CO-registration matrix
%   Show output ifexist for selected task in mainGUI, if not exist
%       then return.
%
% Uses:
%   LoadAir
%____________________________________________
% By T. Dyrby, 170303, NRU
% and T. Rask 141103 NRU
%SW version: 141103TD,TR


%_______ Let user select which task to watch results from
% Show datasets for finished tasks or like...


%____ if exist Load output images from selected task in mainGui 
DefaultView= project.handles.data.SelectedTaskIndexGUI;%From loadfiles

%____ Check If actual task is DONE
if(project.pipeline.statusTask(DefaultView)~=2 | ~exist(project.taskDone{DefaultView}.outputfiles{1,1}.name))
    %Loginfo
    project=logProject('Select an other task....No ouputfiles available',project,TaskIndex,MethodIndex);
    return
end

files.A='';
%___ Search for an co-registration matrix in 'userdata'
if(isfield(project.taskDone{DefaultView}.userdata,'AIRfile'))
    comod=size(project.taskDone{DefaultView}.userdata.AIRfile); %Airfile is put as belonging to one of the modalities
    for i=1:comod(2)
        if (isfield(project.taskDone{DefaultView}.userdata.AIRfile{1,i},'name') & ~isempty(project.taskDone{DefaultView}.userdata.AIRfile{1,i}.name))
            files.A=fullfile('',project.taskDone{DefaultView}.userdata.AIRfile{1,i}.path,project.taskDone{DefaultView}.userdata.AIRfile{1,i}.name);
            files.fromModality=i;
        end
    end
end

h_viewer=[];
NOmodality=size(project.taskDone{DefaultView}.outputfiles);
funk=project.pipeline.taskSetup{TaskIndex,MethodIndex}.function_name;

for(ModalityIndex=1:NOmodality(2))
    
    %_______ Get files to be shown for actual task
    name=project.taskDone{DefaultView}.outputfiles{1,ModalityIndex}.name;
    path=project.taskDone{DefaultView}.outputfiles{1,ModalityIndex}.path;
    
    [PATHSTR,NAME,EXT] = fileparts(name);
    files.img{ModalityIndex}=fullfile('',path,[NAME,EXT]);
    files.hdr{ModalityIndex}=fullfile('',path,[NAME,'.hdr']);
        
    %_____Browse 2/3D
    if strcmp(lower(funk),'browse3d') | strcmp(lower(funk),'browse2d')
        h_viewer=feval(funk,'loaddata',h_viewer,files.img{ModalityIndex});
     
    %_____NRU Inspect
    elseif (strcmp(lower(funk),'nruinspect') & ModalityIndex==2)
        [viewer.imgMR,viewer.hdrMR]=LoadAnalyze(files.img{2},'single');
        [viewer.imgPET,viewer.hdrPET]=LoadAnalyze(files.img{1},'single');
        if isempty(viewer.imgPET), return; end;
        
        viewer.imgPET=double(reshape(viewer.imgPET,viewer.hdrPET.dim(1:3)')); %PET must be in doubles....
        viewer.imgMR=reshape(viewer.imgMR,viewer.hdrMR.dim(1:3)');
        
        if (isempty(files.A))
            viewer.A=diag([1 1 1 1]);
        else
            %If co-registration matrix exist then add       
            viewer.A=ReadAir(files.A);
            if files.fromModality==2
                viewer.A=inv(viewer.A);
            end
        end
        
        feval(funk,'loaddata',viewer);       
    end
end

