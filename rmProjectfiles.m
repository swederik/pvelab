function  project=rmProjectfiles(project,TaskIndex,MethodIndex,varargin)
%  Remove from project-structure all files found in the sub-entry: 
%  'project.pipeline.taskSetup{TaskIndex}'
%
%   Files are indentified by searching the project for filenames and corresponding pathnames
%   Special for Analyze image files:
%       - If only filename of header (hdr) or image (img) is given, the counterpart is found and erased
%
%   Do not erease files within:
%       'project.pipeline.taskSetup{TaskIndex}.filestatus'
%       'project.pipeline.taskSetup{TaskIndex}.error'
%       'project.pipeline.taskSetup{TaskIndex}.inputfiles'
%       'project.pipeline.taskSetup{TaskIndex=1}.outputfiles'
%       'project.pipeline.taskSetup{TaskIndex}.outputfiles='project.pipeline.taskSetup{TaskIndex}.inputfiles'
%       'project.pipeline.taskDone{TaskIndex}.configuration' (251103TR)
%
% Input:
%   project     : Structure containing all information of actual pipeline
%   TaskIndex   : Index to active task in the project structure
%   MethodIndex : Index to used method in a TaskIndex in the project structure
%   varargin{1}=(LeaveExistingFiles): If flag is set then remove info of none
%              existing filenames and paths in the project
%
% Output:
%   project     : Return updated project       
%
% Uses special functions:
%   struct2entries: Get all possible entries
%   logProject
%____________________________________________
% T. Dyrby, 220503, NRU
%
%SW version: 220503TD

%____ Initialise
pathStructEntries=[];
filenameStructEntries=[];
noModalities=length(project.pipeline.imageModality);

if(nargin==4)
    LeaveExistingFiles=varargin{1};
else
    LeaveExistingFiles=0;
end
    
%______Get all sub-entries from: project.taskDone{TaskiIndex,MethodIndex}
structEntries=struct2entries(['project.taskDone{',num2str(TaskIndex),'}'],project.taskDone{TaskIndex});

%______ Search project for filenames and pathsnames
for(i=1:length(structEntries))
    
    % Empty sub-entry   
    if(isempty(eval(structEntries{i}.entry)))
        continue
    end
 
    % Do not remove files mentioned in configuration
    if ~isempty(strfind(lower(structEntries{i}.entry),'.configuration'))
        continue
    end

    % Do not remove outputfiles if outputfiles=inputfiles! 
    if(strfind(lower(structEntries{i}.entry),'.outputfiles'))
        equal=0;
        ImageIndex=project.pipeline.imageIndex(1);
        for(ModalityIndex=1:noModalities)
            equal=equal+strcmp(project.taskDone{TaskIndex}.outputfiles{ImageIndex,ModalityIndex}.name,project.taskDone{TaskIndex}.inputfiles{ImageIndex,ModalityIndex}.name);         
        end    
        
        if(equal>0)
            %project=logProject('RM files: input=outfiles',project,TaskIndex,MethodIndex);                                                     
            continue
        end
        
        %Do not remove ORIGINAL images if TaskIndex=1 (LoadFiles)
        if(TaskIndex==1)
            %project=logProject('RM files: TaskIndex=1, outfiles NOT removed',project,TaskIndex,MethodIndex);                                                     
            continue
        end
    end

    % Do not remove inputfiles !!    
    if(strfind(lower(structEntries{i}.entry), '.inputfiles') | ~ischar(eval(structEntries{i}.entry)))
        continue
    end
            

    
    % Do not remove filestatus information!!  
    if(strfind(lower(structEntries{i}.entry),'.filestatus'))
        continue
    end
    
    % Do not remove error information!!  
    if(strfind(lower(structEntries{i}.entry), '.error'))
        continue        
    else
        %Is string
        if(~isstr(eval(structEntries{i}.entry)))
            continue
        end
        % Split sub-entry into fileparts
         [filepath,filename,file_ext] = fileparts(eval(structEntries{i}.entry));
        
        % Check if sub-entry is a dir and save it for later use...
        if(exist(eval(structEntries{i}.entry),'dir')==7 | exist(filepath,'dir')==7)          
            pathStructEntries{end+1}=structEntries{i}.entry;           
            continue
        end
        
        % Not a file if no extension...
        if(isempty(file_ext))
            continue
        end
        
        
        % String of numbers?? (a problem with .time in start and finish)
        if(length(str2num(eval(structEntries{i}.entry)))>0)
            continue
        end
        
        % We belive it is a filename...
        filenameStructEntries{end+1}=structEntries{i}.entry;        
    end
end %for       

%______ Make similarity-matirx between sub-entries contain filenames and paths
Similarity=[];
for(i=1:length(pathStructEntries))
    n_path=length(pathStructEntries{i});
    
    for(ii=1:length(filenameStructEntries))
        n_filename=length(filenameStructEntries{ii});
        %zereo padding
        if(n_path>n_filename)
            str_filename=zeros(1,n_path);
            str_path=zeros(1,n_path);   
        else
            str_filename=zeros(1,n_filename);
            str_path=zeros(1,n_filename);   
        end
        str_filename(1:n_filename)=filenameStructEntries{ii};
        str_path(1:n_path)=pathStructEntries{i};
        
        %Similarity matrix (filenames,paths) a relative measure...
        Similarity(ii,i)=length(find((str_filename-str_path)==0))/length(str_filename);
    end%ii
end%i
%___ No files to delete
if(isempty(Similarity))
    return
end
%______ Delete found files if the corresponding path is found
for(ii=1:length(filenameStructEntries))    
    
    % Get path structure with highst similarity
    
    [ival,i]=max(Similarity(ii,:));        

    % ONLY FOR TEST
    msg=sprintf('Processing file mentioned in: --- %s --- %s ---',filenameStructEntries{ii},pathStructEntries{i});
    logProject(msg,project,TaskIndex,MethodIndex);                                                     
    
    % Get filename and extension
    guessPath=eval(pathStructEntries{i});
    if isempty(guessPath) %if similarity shit doesnt work, try project dir
        guessPath=project.sysinfo.workspace;
    end
    [filepath,filename,file_ext]=fileparts(eval(filenameStructEntries{ii}));
    filenameQ=fullfile('',guessPath,[filename,file_ext]);        
    
    % Check if file exist w. given path and filename
    if exist(filenameQ,'file')

        %____ If flag is set then existing files are NOT deleted and file- and path names are leaved in project
        if(LeaveExistingFiles==1)
            logProject(sprintf('Leave existing file: %s',filenameQ),project,TaskIndex,MethodIndex);                                                     
            continue                
        end
        
        delete(filenameQ);
        %____ Also delete Analyzeheader or image file
        switch lower(file_ext)
        case '.img'
            hdrFile=fullfile('',guessPath,[filename,'.hdr']);
            logProject(sprintf('Delete existing file: %s',hdrFile),project,TaskIndex,MethodIndex);  
            delete(hdrFile); 
        case '.hdr'
            imgFile=fullfile('',guessPath,[filename,'.img']);
            logProject(sprintf('Delete existing file: %s',imgFile),project,TaskIndex,MethodIndex);  
            delete(imgFile);   
        end
        
        % Remove filename from project
        string=sprintf('%s = ''''; ',filenameStructEntries{ii});
        eval(string); 
        
        % Remove path from project
        string=sprintf('%s = ''''; ',pathStructEntries{i});
        eval(string); 
        
        logProject(sprintf('Delete existing file: %s',filenameQ),project,TaskIndex,MethodIndex);                                                     
        
    else        
        %______ Remove filename and path for non existing files            
        % Remove filename from project
        string=sprintf('%s = ''''; ',filenameStructEntries{ii});
        eval(string); 
        
        % Remove path from project
        string=sprintf('%s = ''''; ',pathStructEntries{i});
        eval(string); 
        
        logProject(sprintf('Remove info. of not existing file: %s',filenameQ),project,TaskIndex,MethodIndex);                                                     
    end   
   % fclose(fid);
end%ii

