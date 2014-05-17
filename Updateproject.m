function project=Updateproject(project,TaskIndex,MethodIndex,varargin)
% Update project by saving it to disc and load it into the data structure of the mainGUI found in 'project.handles.mainfig.
% Append log data to log file log file.
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
%____________________________________________
% T. Dyrby, 230503, NRU
%
%SW version: 230503TD

%______ Update project in structure of mainfig and save to disc
if(ishandle(project.handles.h_mainfig))
    
    set(project.handles.h_mainfig,'userdata',project);%Update structure    
    
    projectfile=fullfile('',project.sysinfo.workspace,project.sysinfo.prjfile);
    
    if(isempty(project.sysinfo.prjfile))
        msg=sprintf('CheckOut: No project exist as a filename');
        project=logProject(msg,project,TaskIndex,MethodIndex,'savelog');    
        return
    end
    %___ Don't save settings for mainGUI
    projectOrg=project;
    project.handles.data='';
    
    save(projectfile,'project','-MAT');  %save to disk
    
    %___ Restore original project
    project=projectOrg;
    
    msg=sprintf('CheckOut: Store project in h_mainfig and save %s.',project.sysinfo.workspace);
    project=logProject(msg,project,TaskIndex,MethodIndex,'savelog');
else
    if(isempty(project.sysinfo.prjfile))
        msg=sprintf('CheckOut: No project exist in mainfig or as a filename');
        project=logProject(msg,project,TaskIndex,MethodIndex,'savelog');    
        return
    end
    
    projectfile=fullfile('',project.sysinfo.workspace,project.sysinfo.prjfile);
    save(projectfile,'project','-MAT');  %save to disk
    
    msg=sprintf('CheckOut: Save project in %s.',project.sysinfo.workspace);
    project=logProject(msg,project,TaskIndex,MethodIndex,'savelog');    
end



