function project=RCV_wrapper(project,TaskIndex,MethodIndex,varargin)
%
%____________________________________________
% M. Comerci, 25092003, IBB
%
% SW version: 1.0.4

%_____ Show progress data in command window
msg='RCV: progress data in Matlab command window...';
project=logProject(msg,project,TaskIndex,MethodIndex);

%_____ Costruct command line...
path0=project.sysinfo.systemdir;
pathin=uigetdir(project.sysinfo.workspace,'Source directory');
pathout=uigetdir(project.sysinfo.workspace,'Target directory');
path1=[path0 filesep 'IBB_wrapper' filesep 'd2a'];
cd (path1);

if ismac
    cmdline=['"' path1,filesep,'rcvmac" -k "',pathin,'" "',pathout,'"'];
else
    cmdline=['"' path1,filesep,'rcv" -k "',pathin,'" "',pathout,'"'];
end
result=unix(cmdline);

if result~=0
    [project,msg]=logProject('Error in RCV method.',project,TaskIndex,MethodIndex);
    project.taskDone{TaskIndex}.error{end+1}=msg;
end
