function tasks=fileVersion(tasks,varargin)
% fileVersion search for version number and checks that needed functions are available as described in
%  'task=project.pipeline.taskSetup{TaskIndex,MethodIndex}'
%
% fileVersion is checking for:
%   function_wrapper
%   function_name (if exist in field). Note that a function_wrapper dont have to use a function_name!
%   configuratorfile (if exist in field)
%   configurator_wrapper(if exist in field)
%
% Input:
%   tasks       : task=project.pipeline.taskSetup{TaskIndex,MethodIndex}'
%   varargin    : 
%           varargin{1}:filename of single file to check for
%           varargin{2}:versionlabel to search for
% Output:
%   tasks: As input but with an extra filestatus
%
% Uses special functions:
%
%____________________________________________
% T. Dyrby, 190303, NRU
%
%SW version: 250803TD

% -OK 240803TD: Add possibility to check only a single file
% -OK 250803TD: Add check of configurator wrapper and if exist configurator_name


%________ Initialisation
status='';%Reset status cell-array

if(isunix)
    os='UNIX';
else
   os='WINDOWS';
end

%____ Check a single filename
if(length(varargin))
    chkFilename=varargin{1};
    versionlabel=varargin{2};
    names=which(chkFilename,'-all');
    for(i=1:length(names))
        if(isempty(names(i)))
            status{end+1}.indexname='check of single filename';
            status{end}.exist=0;
            status{end}.version='';
            status{end}.path='';
            status{end}.filename='';
            status{end}.os=os;    
        else                
            [path,name,ext] = fileparts(names{i});
            status{end+1}.indexname='check of single filename';
            status{end}.exist=1;
            status{end}.version=search(names{i},versionlabel);%Get label thats describe the SWversion
            status{end}.path=path;
            status{end}.filename=[name,ext];
            status{end}.os=os;
        end        
    end%for
    
    tasks=status;
    return
end

%________ Exist?:Function_wrapper name, Version, path
names=which(tasks.function_wrapper,'-all');
if(isempty(names))    
    tasks.filesexist=0;%problem finding program
    status{end+1}.indexname='function_wrapper';
    status{end}.exist=0;
    status{end}.version='';
    status{end}.path='';
    status{end}.filename='';
    status{end}.os=os;    
else  
    tasks.filesexist=1;%Programfiles exist
    [path,name,ext] = fileparts(names{1});
    status{end+1}.indexname='function_wrapper';
    status{end}.exist=1;
    status{end}.version=search(names{1},tasks.versionlabel);%Get label thats describe the SWversion
    status{end}.path=path;
    status{end}.filename=[name,ext];
    status{end}.os=os;
end

%________(OPTIONAL:NOTE afunction_wrapper could do the same as a function_wrapper) Exist?:Function_name, Version, path
if(~isempty(tasks.function_name))
    names=which(tasks.function_name,'-all');
    
    if(isempty(names))
        tasks.filesexist=0;%problem finding program
        status{end+1}.indexname='function_name';
        status{end}.exist=0;
        status{end}.version='';
        status{end}.path='';
        status{end}.filename='';
        status{end}.os=os;    
    else    
        tasks.filesexist=1;%Programfiles exist
        [path,name,ext] = fileparts(names{1});
        status{end+1}.indexname='function_name';
        status{end}.exist=1;
        status{end}.version=search(names{1},tasks.versionlabel);%Get label thats describe the SWversion
        status{end}.path=path;
        status{end}.filename=[name,ext];
        status{end}.os=os;
    end
end



% %________ (OPTIONAL) Exist?:Configurator_name, Version, path
%____ Do configurator wrapper exist
if(~isempty(tasks.configurator_wrapper))%Check if function name is given to configurator_name 
    names=which(tasks.configurator_wrapper,'-all');
    
    if(isempty(names))%Configurator exist     
        tasks.filesexist=0;%problem finding program
        status{end+1}.indexname='';
        status{end}.exist=0;
        status{end}.version='';
        status{end}.path='';
        status{end}.filename='';
        status{end}.os=os;    
    else  
        tasks.filesexist=1;%Programfiles exist
        [path,name,ext] = fileparts(names{1});
        status{end+1}.indexname='configuratorfile';
        status{end}.exist=1;
        status{end}.version=search(names{1},tasks.versionlabel);%Get label thats describe the SWversion
        status{end}.path=path;
        status{end}.filename=[name,ext];
        status{end}.os=os;
    end
    %If given do a function configurator_name exist
    if(~isempty(tasks.configurator.configurator_name))%Check if function name is given to configurator_name 
        names=which(tasks.configurator_wrapper,'-all');
        
        if(isempty(names))%Configurator exist
            tasks.filesexist=0;%problem finding program
            status{end+1}.indexname='';
            status{end}.exist=0;
            status{end}.version='';
            status{end}.path='';
            status{end}.filename='';
            status{end}.os=os;    
        else  
            tasks.filesexist=1;%Programfiles exist
            [path,name,ext] = fileparts(names{1});
            status{end+1}.indexname='configuratorfile';
            status{end}.exist=1;
            status{end}.version=search(names{1},tasks.versionlabel);%Get label thats describe the SWversion
            status{end}.path=path;
            status{end}.filename=[name,ext];
            status{end}.os=os;
        end
    end    
end%end configurator_wrapper
 
%________ Add status to project
tasks.filestatus=status;


%____________________________________________
% search for version label in given matlabfile (text) 
%
%
%____________________________________________
% T. Dyrby, 190303, NRU
function version=search(filename,literal)
% Search for number of string matches per line.  
fid = fopen(filename, 'rt');
y = 0;
version='';
while feof(fid) == 0
    tline = fgetl(fid);
    matches = strfind(lower(tline), lower(literal));
    num = length(matches);   
    if num > 0
        version=tline;
        break
    end
end

if(length(version)==0)
    version=sprintf('''%s'' not found in filename',literal);
end
fclose(fid); 
