function [pre,dim,sz,lim,scale,offset,origin,descr,endian]=ReadAnalyzeHdr(name)
% Reads the header of an analyze file
%
%  [hdr]=ReadAnalyzeHdr(name)
%
%  hdr       - structure with all the fields mentionened belove plus
%               path - path of file if included in the call parameter 'name'
%
%  hdr.pre       - precision for voxels in bit
%                1 - 1 single bit
%                8 - 8 bit voxels (lim is used for deciding if signed or
%                     unsigned char, if min < 0 then signed))
%               16 - 16 bit integer (lim is used for deciding if signed or
%                     unsigned notation should be used, if min < 0 then signed))
%               32 - 32 bit floats
%               32i - 32 bit complex numbers (64 bit pr. voxel)
%               64 - 64 bit floats
%  hdr.dim       - x,y,z, no of pixels in each direction
%  hdr.siz       - voxel size in mm
%  hdr.lim       - max and min limits for pixel values
%  hdr.scale     - scaling of pixel values
%  hdr.offset    - offset in pixel values
%  hdr.origin    - origin for AC-PC plane (SPM notation)
%  hdr.descr     - Description from description field
%  hdr.endian    - Number format used 'ieee-be' or 'ieee-le' (normally
%               'ieee-be' is always used)
%
%  abs_pix_val = (pix_val - offset) * scale
%
%  name      - name of image file
%
%  Cs, 010294
%
%  Revised
%  CS, 181194  Possibility of offset and scale in header file
%  CS, 130398  Possibility of origin in header file
%  CS, 280100  Reading changed so routines works on both HP and Linux
%              systems
%  CS, 050200  Changed so description field also is returned
%  CS, 060700  Structure output appended as possibility
%  CS, 070801  Changed to be able to handle the iee-le files (non standard
%               analyze files)
%  CS, 210901  Changed including an extra field 'path' in hdr structure
%
if (nargin ~= 1)
    error('ReadAnalyzeHdr, Incorrect number of input arguments');
end;
if (nargout ~= 1)
    warning('Old way of calling ReadAnalyzeHdr used, please use [hdr]=ReadAnalyzeHdr(name)');
end;
%
[pn,fn,ext]=fileparts(name);
if length(ext)~=4   % There is a dot in the filename, but it is not the extension
    fn=[fn ext];
end
if exist(fullfile(pn,[fn '.hdr']),'file')==2        % Analyze header
    hdr=LoadAnalyzeHdr(fullfile(pn,[fn '.hdr']));
elseif exist(fullfile(pn,[fn '.nii']),'file')==2    % Nifti header
    hdr=LoadNiftiHdr(fullfile(pn,[fn '.nii']));
else
    error('Unknow file type');
end
if nargout==1
    pre=hdr;
else
    pre=hdr.pre;
    dim=hdr.dim;
    sz=hdr.siz;
    lim=hdr.lim;
    scale=hdr.scale;
    offset=hdr.offset;
    origin=hdr.origin;
    descr=hdr.descr;
    endian=hdr.endian;
end

function hdr=LoadAnalyzeHdr(FileName)
%
pid=fopen(FileName,'r','ieee-be');
%
% Uncertainty if filesize is written as a int16 or int32
%
header_size=fread(pid,2,'int16');
hdr.endian='ieee-be';
if (header_size(1) ~= 348) && (header_size(2) ~= 348)
    fclose(pid);
    pid=fopen(FileName,'r','ieee-le');
    header_size=fread(pid,2,'int16');
    hdr.endian='ieee-le';
    if (header_size(1) ~= 348) && (header_size(2) ~= 348)
        fclose(pid);
        pid=fopen(FileName,'r','ieee-be');
        header_size=fread(pid,2,'int16');
        hdr.endian='ieee-be';
        fprintf('Not able to detect analyze file format, guessing at ieee-be\n');
    end
end
fread(pid,36,'uint8');           % dummy read header information
dims=fread(pid,1,'uint16');      % dimension (3 or 4)
hdr.dim=fread(pid,4,'uint16');       % dimension, number of pixels
if (dims == 3) || (hdr.dim(4) == 1) || (hdr.dim(4) == 0)
    hdr.dim=hdr.dim(1:3);
end;
fread(pid,4,'uint16');
fread(pid,6,'uint16');
Datatype=fread(pid,1,'uint16');    % datatype
BitsPrVoxel=fread(pid,1,'uint16'); %Bits pr. voxel
fread(pid,1,'uint16');
fread(pid,2,'uint16');
hdr.siz=fread(pid,3,'float32');        % size of pixels
fread(pid,4,'float32');
hdr.offset=fread(pid,1,'float32');     % offset for pixels (funused8), SPM extension
hdr.scale=fread(pid,1,'float32');  % scaling for pixels (funused9), SPM extension

fread(pid,24,'int8');

hdr.lim=fread(pid,2,'int32');            % Limits for number in given analyze format

hdr.descr=fread(pid,80,'*char')';  % Description field in header file
hdr.descr=deblank(hdr.descr);

fread(pid,24,'int8');
orient=fread(pid,1,'int8');        % Orientation, not used

hdr.origin=fread(pid,3,'int16');       % Origin, SPM extension to analyze format

fread(pid,89,'int8');              % Not used
fclose(pid);

if (Datatype==1)&&(BitsPrVoxel==1)         % single bit
    hdr.pre=1;
elseif (Datatype==2)&&(BitsPrVoxel==8)     % unsigned char
    hdr.pre=8;
elseif (Datatype==4)&&(BitsPrVoxel==8)     % signed char
    hdr.pre=8;
elseif (Datatype==4)&&(BitsPrVoxel==16)    % Needed for compatibility with
    % NRU and AIR format
    hdr.pre=16;
elseif (Datatype==8)&&(BitsPrVoxel==16)    % signed 16 bit int
    % based on lim it is decided
    % whether it is signed/unsigned in
    % accordance with AIR
    hdr.pre=16;
elseif (Datatype==16)&&(BitsPrVoxel==32)   % 32 bit float
    hdr.pre=32;
elseif (Datatype==32)&&(BitsPrVoxel==32)   % Old NRU format (wrong but did
    % work because of no complex
    % files)
    hdr.pre=32;
elseif (Datatype==32)&&(BitsPrVoxel==64)   % Complex (2xfloats)
    hdr.pre=32*sqrt(-1);
elseif (Datatype==64)&&(BitsPrVoxel==64)   % 64 bit float
    hdr.pre=64;
else
    error(sprintf('Unknown data type, Datatype: %i, Bits pr. voxel %i',Datatype,BitsPrVoxel));
end

if (hdr.pre == 32) || (hdr.pre == 64)       % To be sure that img=(imgRead-offset)*scale
    hdr.scale=1;
    hdr.offset=0;
end

[pn,fn,ext]=fileparts(FileName);
if length(ext)~=4
    hdr.name=[fn ext];
else
    hdr.name=fn;
end
hdr.path=pn;


function hdr=LoadNiftiHdr(FileName)
%
if ~exist('load_nii_hdr','file')==2
    error('SW for reading nifti files not available, please install package from Rotman Institute including load_nii_hdr');
end
%
nii_hdr=load_nii_hdr(FileName);
%
[pn,fn,ext]=fileparts(FileName);
if length(ext)~=4
    hdr.name=[fn ext];
else
    hdr.name=fn;
end
hdr.path=pn;
%
if (nii_hdr.dime.datatype==1)&&(nii_hdr.dime.bitpix==1)         % single bit
    hdr.pre=1;
    hdr.lim=[1 0];
elseif (nii_hdr.dime.datatype==2)&&(nii_hdr.dime.bitpix==8)     % unsigned char
    hdr.pre=8;
    hdr.lim=[255 0];
elseif (nii_hdr.dime.datatype==4)&&(nii_hdr.dime.bitpix==16)    % Needed for compatibility with
    % NRU and AIR format
    hdr.pre=16;
    hdr.lim=[32767 -32768];
elseif (nii_hdr.dime.datatype==8)&&(nii_hdr.dime.bitpix==32)    % signed 16 bit int
    % based on lim it is decided
    % whether it is signed/unsigned in
    % accordance with AIR
    hdr.pre=32;
    hdr.lim=[1 0];
elseif (nii_hdr.dime.datatype==16)&&(nii_hdr.dime.bitpix==32)   % 32 bit float
    hdr.pre=32;
    hdr.lim=[1 0];
elseif (nii_hdr.dime.datatype==32)&&(nii_hdr.dime.bitpix==64)   % Complex (2xfloats)
    hdr.pre=32*sqrt(-1);
    hdr.lim=[1 0];
elseif (nii_hdr.dime.datatype==64)&&(nii_hdr.dime.bitpix==64)   % 64 bit float
    hdr.pre=64;
    hdr.lim=[1 0];
else
    error(sprintf('Unknown data type, Datatype: %i, Bits pr. voxel %i',nii_hdr.dime.datatype,nii_hdr.dime.bitpix));
end
hdr.siz=nii_hdr.dime.pixdim(2:4);
if (nii_hdr.dime.dim(1)==3)||(nii_hdr.dime.dim(5)==3)
    hdr.dim=nii_hdr.dime.dim(2:4);
else
    hdr.dim=nii_hdr.dime.dim(2:5);
end
hdr.scale=nii_hdr.dime.scl_slope;
hdr.offset=nii_hdr.dime.scl_inter;
if ((nii_hdr.hist.srow_x(1)==0)||...
        (nii_hdr.hist.srow_y(2)==0)||...
        (nii_hdr.hist.srow_z(3)==0))
    hdr.origin=[0 0 0];
else
    hdr.origin=round([-nii_hdr.hist.qoffset_x/nii_hdr.hist.srow_x(1)+1,...
        -nii_hdr.hist.qoffset_y/nii_hdr.hist.srow_y(2)+1,...
        -nii_hdr.hist.qoffset_z/nii_hdr.hist.srow_z(3)+1]);
end
hdr.descr=nii_hdr.hist.descrip;
hdr.endian='ieee-le';


