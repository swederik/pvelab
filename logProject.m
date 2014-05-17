function [project,varargout]=logProject(msgLog,project,TaskIndex,MethodIndex,varargin)
% logProject shows a message in the Logwin of the pipline program if a GUI exist.
%  The logmessage is appended to the log file if flag 'savelog' is given.
%
% Input:
%   msgLog      : Message to appear in the pipleine program if GUI exist, and saved in logfile
%   project     : Structure containing all information of actual pipeline
%   TaskIndex   : Index (or empty '[]') to active task in the project structure 
%   MethodIndex : Index (or empty '[]')to used method in a TaskIndex in the project structure
%   varargin{1}='savelog': Add log information stored 'project.info.ligfile.tmp' to the log file
%
% Output:
%   project     : Return updated project       
%   varargout   : Return updated 'msgLog' if wanted
%
% Uses special functions:
%
% ____________________________________________
% T. Dyrby, 190303, NRU
%
%SW version: 170303TD

%_______ Save log file
if(nargin==5 & strcmp(lower(varargin{1}),'savelog'))    
    % Check if project file name exist
    if(isempty(project.sysinfo.prjfile))
        return
    end
    
    % Check if logfile name exist
    if(isempty(project.sysinfo.logfile.name))
        [pathstr,name,ext] = fileparts(project.sysinfo.prjfile);
        project.sysinfo.logfile.name=[name,'.log'];
    end
    
    logfile=fullfile('',project.sysinfo.workspace,project.sysinfo.logfile.name);    
    %Open file and append logtext
    fid=fopen(logfile,'a');
    status=fseek(fid,0,1);%Start at end of file
    Q=length(project.sysinfo.logfile.tmp);
    for i=1:Q
        fwrite(fid,sprintf('%s \n',project.sysinfo.logfile.tmp{i}),'char');
    end 
    fclose(fid);%Close logfile
    
    project.sysinfo.logfile.tmp='';%Clear temp log file    
    return
end

%_______ Fullfill Log information
if(isempty(TaskIndex) | isempty(MethodIndex))
    msgLog=sprintf('- %s ----(Task: ?, Method: ?)',msgLog);    
else
    msgLog=sprintf('- %s ----(Task: %s, Method: %s) ',msgLog,project.pipeline.taskSetup{TaskIndex,MethodIndex}.task,...
        project.pipeline.taskSetup{TaskIndex,MethodIndex}.method);
    
end

%_______ Convert to single line strings
msgCells=splitStr(msgLog);

%_______ Write Log to infobar
for i=1:length(msgCells)
    project.sysinfo.logfile.tmp{end+1}=msgCells{i};%Add msgLog to 
    
end


%_______ If log message must be send returned, eg. used as an error message
if(nargout==2)
    varargout{1}=msgLog;
end

%=================Split multiline string to cell array og strings ===============


function cArray=splitStr(str)
pos=find((double(str))==10); %Find positions for linebreak (\n==char(10))
if isempty(pos)
    cArray=cellstr(str);
    return
else
    le=length(pos);
    
    %Make complete position list
    bPos(1)=0;
    bPos(le+2)=length(str)+1;
    for k=1:le, bPos(k+1)=pos(k); end
    
    %Make cells
    for i=1:(le+1)
        if (bPos(i+1)-1)>(bPos(i)+1)
            cArray{i}=str((bPos(i)+1):(bPos(i+1)-1));
        else
            cArray{i}='';
        end
    end
end

