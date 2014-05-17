function pip_cleanMatlabpath(tmp_workspace)
% Clean up Matlab by remove path's from the Matlab path if the path exist.
% Note: Do not remove path for actual function!
%
% Input:
%   tmp_workspace{:}: Struct containing paths to be removed from Matlab path
%   tmp_workspace   : String containing one path to be removed from Matlab path
%
% Output:
%
% Uses:
%
%____________________________________________
%SW version: 261103TD, By T. Dyrby, 261103,DRCMR
%

%Only one path is given?
if(isstr(tmp_workspace))
    tmp_workspace={tmp_workspace};
end


if(~isempty(tmp_workspace))
    for(i=1:length(tmp_workspace))%NOTE: first dir is not removed is system dir

%         %Ensure to get only path --- NO this removes the last dir in path!
%         tmp_workspace{i}=fileparts(tmp_workspace{i});

        while strcmp(tmp_workspace{i}(end),filesep) %Added by Thomas Rask 281103
            tmp_workspace{i}=tmp_workspace{i}(1:(end-1));
        end
        
        if(strcmp(tmp_workspace{i},fileparts(which('pip_cleanMatlabpath'))))
            %disp('Do not remove path for function')
            continue
        end
        %ONLY FOR TEST   
        %(tmp_workspace{i})
        %exist(tmp_workspace{i})
        
        %Clean up Matlab path
        if(isunix)%OS difference
            tmp_pathSep=':';
            tmp_path=[tmp_pathSep,path,tmp_pathSep];
        else
            tmp_pathSep=';';      
            tmp_workspace{i}=lower(tmp_workspace{i});%needs lower() because windows write path in lower. 281103TR
            tmp_path=lower([tmp_pathSep,path,tmp_pathSep]);
        end

    
        if(~isempty(strfind([tmp_pathSep,tmp_workspace{i},tmp_pathSep],tmp_path)))
            rmpath(tmp_workspace{i});%Clean-up Matlab path for old paths
        end        
    end    
end
