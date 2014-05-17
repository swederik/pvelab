function [A,Struct]=ReadAir(airfile,endian)
%
% function [A,Struct]=ReadAir(airfile,endian)
%
%  Function to read coregistration data from Woods Air 3.0
%  format. Input is airfile (.air filename to read) and optional
%  input parameter endian (if undefined, defaults to ieee-be)
%
%  Outputs
%
%  A -  "real world" / talairach space transformation matrix
%
%  And optionally
%
%  Struct with fields
%    A - "real world" / talairach space transformation matrix
%    hdrI - input space Analyze hdr
%    hdrO - output space Analyze hdr
%    descr - descriptive string
%
%  Checks for ieee-le/ieee-be endianness. Assumes machine endian as
%  default.
%
%  Warning: Existence of airfile is not checked - must be done
%  before calling ReadCor, e.g. using uigetfile
%
%  PW, NRU, 2001
%

% MATHREADDESC Air 3.0 format (*.air)

% Does file exist?
if exist(airfile)==2
    d=dir(airfile);
    NRUFORMAT=0;
    if length(d)==1
        if d.bytes==768
            NRUFORMAT=1;
            disp(['ReadAir: ' airfile ' seems to be NRU air format...']);
        end
    else
        error(['ReadAir: ' airfile ' matches several filenames!']);
    end
else
    error(['ReadAir: ' airfile ' does not exist!']);
end


% Open the airfile for reading
if (exist('endian')==1)
    if strcmp(lower(endian),'native') | strcmp(lower(endian),'n')
        % Assume ''native'' endianness
        [comp,tmp,endian]=computer;
        endian=lower(endian);
        if strcmp(endian,'l')
            endian='ieee-le';
        elseif strcmp(endian,'b')
            endian='ieee-be';
        end
        % disp(['Computer type is ' comp ', endian is ' endian]);
    end
else
    endian='ieee-be';
    [fid,message] = fopen(airfile,'rb',endian);
    dummy=fread(fid,256,'uint8');
    bits=fread(fid,1,'uint16');
    fclose(fid);
    fprintf('Reading air file as: ieee-be\n');
    if (bits>128)
        endian='ieee-le';
        [fid,message] = fopen(airfile,'rb',endian);
        dummy=fread(fid,256,'uint8');
        bits=fread(fid,1,'uint16');
        fclose(fid);
        fprintf('Reading air file as: ieee-le\n');
        if (bits>128)
            error('ReadAir: Unknown bit format in air file');
        end
    end
end
[fid,message] = fopen(airfile,'rb',endian);
% Is Stuct undefined?
if exist('Struct')==0
    Struct=[];
end
if not(fid<1)
    % Read transformation matrix
    A=reshape(fread(fid,16,'float64'),[4 4]);
    % Read STD filename
    stdname=fread(fid,128,'uint8=>char');
    pos=find(stdname==0);
    if ~isempty(pos)
        stdname=stdname(1:pos(1)-1)';
    end
    %stdname=sscanf(stdname,'%s');
    % Remove spaces:
    if not(isempty(stdname))
        stdname=stdname(not(stdname-0==32));
        stdname=stdname(not(stdname-0==0));
        % Put an .hdr after the filename
        [pn,fn,ext]=fileparts(stdname);
        stdname=fullfile(pn,[fn '.hdr']);
    end
    buildhdr=0;
    % Is Stdname undefined?
    if not(exist(stdname)==2) | isempty(stdname)
        warning(['Standard file missing / not defined in ' ...
            airfile '. Assuming origin=[1 1 1], scale=1 offset=0']);
        buildhdr=1;
    else
        % Read in STD Analyze Hdr
        Struct.hdrO=ReadAnalyzeHdr(stdname);
    end
    % Read different bits of unneeded information: (contained in hdr)
    s.bits=fread(fid,1,'int32');
    s.xres=fread(fid,1,'int32');
    s.yres=fread(fid,1,'int32');
    s.zres=fread(fid,1,'int32');
    if NRUFORMAT==1
        s.tres=fread(fid,1,'int32');
        tmp=fread(fid,1,'int32');
    else
        s.tres=0;
    end
    s.x_size=fread(fid,1,'float64');
    s.y_size=fread(fid,1,'float64');
    s.z_size=fread(fid,1,'float64');
    if NRUFORMAT==1
        s.scale=fread(fid,1,'float64');
        s.offset=fread(fid,1,'float64');
    else
        s.scale=1;
        s.offset=0;
    end
    if buildhdr==1
        [pn,fn]=fileparts(stdname);
        Struct.hdrO.name=fn;
        Struct.hdrO.path=pn;
        Struct.hdrO.pre=s.bits;
        if Struct.hdrO.pre==0
            warning('Standard precision read as 0 in airfile. Assuming 8 bit!');
            Struct.hdrO.pre=8;
        end
        Struct.hdrO.dim=[s.xres s.yres s.zres]';
        Struct.hdrO.siz=[s.x_size s.y_size s.z_size]';
        Struct.hdrO.lim=[2^Struct.hdrO.pre-1 0]';
        Struct.hdrO.scale=1;
        Struct.hdrO.offset=0;
        Struct.hdrO.origin=[1 1 1]';
        Struct.hdrO.descr='Pseudo header from ReadAir';
        Struct.hdrO.endian='ieee-be';
    end

    % Read RES filename
    resname=fread(fid,128,'uint8=>char');
    pos=find(resname==0);
    if ~isempty(pos)
        resname=resname(1:pos(1)-1)';
    end
    %resname=sscanf(resname,'%s');
    % Remove spaces:
    resname=resname(not(resname-0==32));
    resname=resname(not(resname-0==0));
    % Put an .hdr after the filename
    [pn,fn,ext]=fileparts(resname);
    resname=fullfile(pn,[fn '.hdr']);
    buildhdr=0;
    % Is Resname undefined?
    if not(exist(resname)==2) | isempty(resname)
        warning(['Reslice file missing / not defined in ' ...
            airfile '. Assuming origin=[1 1 1], scale=1 offset=0']);
        buildhdr=1;
    else
        % Read in RES Analyze Hdr
        Struct.hdrI=ReadAnalyzeHdr(resname);
    end
    % Read different bits of unneeded information: (contained in hdr)
    r.bits=fread(fid,1,'int32');
    r.xres=fread(fid,1,'int32');
    r.yres=fread(fid,1,'int32');
    r.zres=fread(fid,1,'int32');
    if NRUFORMAT==1
        r.tres=fread(fid,1,'int32');
        tmp=fread(fid,1,'int32');
    else
        r.tres=0;
    end
    r.x_size=fread(fid,1,'float64');
    r.y_size=fread(fid,1,'float64');
    r.z_size=fread(fid,1,'float64');
    if NRUFORMAT==1
        r.scale=fread(fid,1,'float64');
        r.offset=fread(fid,1,'float64');
    else
        r.scale=1;
        r.offset=0;
    end

    if buildhdr==1
        [pn,fn]=fileparts(resname);
        Struct.hdrI.name=fn;
        Struct.hdrI.path=pn;
        Struct.hdrI.pre=r.bits;
        if Struct.hdrI.pre==0
            warning('Reslice precision read as 0 in airfile. Assuming 8 bit!');
            Struct.hdrI.pre=8;
        end
        Struct.hdrI.dim=[r.xres r.yres r.zres]';
        Struct.hdrI.siz=[r.x_size r.y_size r.z_size]';
        Struct.hdrI.lim=[2^Struct.hdrI.pre-1 0]';
        Struct.hdrI.scale=1;
        Struct.hdrI.offset=0;
        Struct.hdrI.origin=[1 1 1]';
        Struct.hdrI.descr='Pseudo header from ReadAir';
        Struct.hdrI.endian='ieee-be';
    end


    s.hash=fread(fid,1,'int32');
    r.hash=fread(fid,1,'int32');

    s.volume=fread(fid,1,'int16');
    r.volume=fread(fid,1,'int16');

    fclose(fid);
    % Convert read transformation matrix from cubic voxel
    % coordinates to real-world mm coordiates
    %
    % Note: Air uses c-style indices, and hdr origins must be
    % adjusted accordingly.
    %
    hdrItmp=Struct.hdrI;
    if not(all(hdrItmp.origin==0))
        hdrItmp.origin=hdrItmp.origin-1;
    end
    hdrOtmp=Struct.hdrO;
    if not(all(hdrOtmp.origin==0))
        hdrOtmp.origin=hdrOtmp.origin-1;
    end
    if ~any(isnan(A(:))) & ~any(isinf(A(:))) & ~isinf(cond(A))
        A=voxa2tala(inv(cuba2voxa(A,hdrItmp,hdrOtmp)),hdrItmp,hdrOtmp);
        Struct.A=A;
        Struct.endian=endian;
        Struct.nruformat=NRUFORMAT;
    else
        % Check if we should have done endian swapping...
        disp(['ReadAir: The file ' airfile ' seems not to be in ' endian ' format. Trying to byte-swap']);
        if strcmp('ieee-be',endian)
            [A,Struct]=ReadAir(airfile,'ieee-le');
        elseif strcmp('ieee-le',endian)
            [A,Struct]=ReadAir(airfile,'ieee-be');
        else
            message='Error in endian definition.';
            error(message);
            return
        end
    end
else % fopen returned an error
    error(message);
end













