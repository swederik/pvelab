function message=SaveAir(airfile,Struct)
%
% function SaveAir(airfile,Struct)
%
%  Function to save coregistration data to Woods Air 3.0
%  format. Inputs are airfile (output filename) and
%  Struct with fields
%    A - "real world" / talairach space transformation matrix
%    hdrI - input space Analyze hdr
%    hdrO - output space Analyze hdr
%    descr - descriptive string (Set to 'Written by SaveAir' if undefined)
%    [endian] - 'ieee-be' or 'ieee-le' not needed. Default is ieee-be
%    [nruformat] - 0 / 1. Controls if saved Air file is in NRU
%    format (includes time, scale and offset info). Can be set to
%    override default behaviour, defined within SaveAir.m.
%
%  PW, NRU, 2001
%

% MATHDESC Air 3.0 format (*.air)

% Definitions:

% What default endianness should be used?
% Is a global value set?
global DEF_ENDIAN;
if isempty(DEF_ENDIAN)
    DEF_ENDIAN='ieee-be';
end
% Write Air file in NRU format? 0/1
global NRU_FORMAT;
if isempty(NRU_FORMAT)
    NRU_FORMAT=0;
end

% Both of the above can be overwritten using input parameters on
% the struct

% Open the airfile for writing
if isfield(Struct,'endian')
    [fid,message] = fopen(airfile,'wb',Struct.endian);
else
    [fid,message] = fopen(airfile,'wb',DEF_ENDIAN);
end
if isfield(Struct,'nruformat');
    NRU_FORMAT=Struct.nruformat;
end
if not(fid<1)
    % Write the transformation matrix (Do conversion to inverse,
    % cubic voxel coordinates)
    %
    % Note: Air uses c-style indices, so hdr origins must be set accordingly
    if not(all(Struct.hdrI.origin==0))
        Struct.hdrI.origin=Struct.hdrI.origin-1;
    end
    if not(all(Struct.hdrO.origin==0))
        Struct.hdrO.origin=Struct.hdrO.origin-1;
    end
    A=voxa2cuba(inv(tala2voxa(Struct.A,Struct.hdrI,Struct.hdrO)),...
        Struct.hdrI,Struct.hdrO);
    fwrite(fid,A,'float64');
    % Write standard filename
    % Make sure that the filenames are given with path
    if isempty(strfind(Struct.hdrO.name,'/'))
        Struct.hdrO.name=fullfile(Struct.hdrO.path,Struct.hdrO.name);
    end
    if length(Struct.hdrO.name)>3
        dot=Struct.hdrO.name(length(Struct.hdrO.name)-3);
        if not(strcmp(dot,'.'));
            Struct.hdrO.name=[Struct.hdrO.name '.img'];
        end
    end
    % Concatenate a 128 byte, terminated string:
    Struct.hdrO.name=[Struct.hdrO.name char(0) char(32*ones(1,128-(length(Struct.hdrO.name)+1)))];
    fwrite(fid,Struct.hdrO.name,'char');
    % Standard 'bits'
    fwrite(fid,round(Struct.hdrO.pre),'int32');
    % Standard dim
    fwrite(fid,Struct.hdrO.dim(1:3)','int32');
    
    % Only in NRU Airfile format:
    if NRU_FORMAT==1
        % Standard 't_res'
        val=0;
        if length(Struct.hdrO.dim)==4
            val=Struct.hdrO.dim(4);
        end
        fwrite(fid,round(val),'int32');
        % Seperator
        fwrite(fid,0,'int32');
    end
    % Standard voxel size
    fwrite(fid,Struct.hdrO.siz','float64');
    
    % Only in NRU Airfile format:
    if NRU_FORMAT==1
        % Standard scale/offset
        fwrite(fid,Struct.hdrO.scale,'float64');
        fwrite(fid,Struct.hdrO.offset,'float64');
    end
    
    % Write reslice filename
    % Make sure that the filenames are given with path
    if isempty(strfind(Struct.hdrI.name,'/'))
        Struct.hdrI.name=fullfile(Struct.hdrI.path,Struct.hdrI.name);
    end
    if length(Struct.hdrI.name)>3
        dot=Struct.hdrI.name(length(Struct.hdrI.name)-3);
        if not(strcmp(dot,'.'));
            Struct.hdrI.name=[Struct.hdrI.name '.img'];
        end
    end
    % Concatenate a 128 byte, terminated string:
    Struct.hdrI.name=[Struct.hdrI.name char(0) char(32*ones(1,128-(length(Struct.hdrI.name)+1)))];
    fwrite(fid,Struct.hdrI.name,'char');
    % Reslice 'bits'
    fwrite(fid,round(Struct.hdrI.pre),'int32');
    % Reslice dim
    fwrite(fid,Struct.hdrI.dim(1:3)','int32');
    
    
    % Only in NRU Airfile format:
    if NRU_FORMAT==1% Reslice 't_res'
        val=0;
        if length(Struct.hdrI.dim)==4
            val=Struct.hdrI.dim(4);
        end
        fwrite(fid,round(val),'int32');
        % Seperator
        fwrite(fid,0,'int32');
    end
    
    % Reslice voxel size
    fwrite(fid,Struct.hdrI.siz','float64');
    
    if NRU_FORMAT==1
        % Reslice 't_res'
        % Reslice scale/offset
        fwrite(fid,Struct.hdrI.scale,'float64');
        fwrite(fid,Struct.hdrI.offset,'float64');
    end
    
    % Write descriptive field
    if not(isfield(Struct,'descr'))
        Struct.descr='Written by SaveAir';
    end
    fwrite(fid,sprintf('%-128s',Struct.descr),'char');
    
    % Write 'hash' and volume fields
    fwrite(fid,0,'int32');
    fwrite(fid,0,'int32');
    fwrite(fid,0,'int16');
    fwrite(fid,0,'int16');
    
    % Final closing string
    fwrite(fid,sprintf('%-116s',' '),'char');
    fclose(fid);
else % fopen returned an error
    error(message);
end
