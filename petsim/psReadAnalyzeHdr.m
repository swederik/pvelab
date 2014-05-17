function [pre,dim,siz,lim,scale,offset,origin,descr,fileformat]=psReadAnalyzeHdr(name);
% Reads the header of an analyze file
% 
%  [pre,dim,siz,lim[,scale[,offset[,origin[,descr[,fileformat]]]]]]=ReadAnalyzeHdr(name)
%  [pre,dim,siz,lim,scale,offset,origin,descr,fileformat]=ReadAnalyzeHdr(name)
%  [hdr]=ReadAnalyzeHdr(name)
%  
%  pre       - precision for pictures (8/16 bit)
%  dim       - x,y,z, no of pixels in each direction
%  siz       - voxel size in mm
%  lim       - max and min limits for pixel values
%  scale     - scaling of pixel values
%  offset    - offset in pixel values
%  origin    - origin for AC-PC plane (SPM notation)
%  descr     - Description from description field
%  fileformat - Number format used 'ieee-be' or 'ieee-le' (normally
%               'ieee-be' is always used)
%
%  hdr       - structure with all the fields mentionened above plus
%               path - path of file if included in the call parameter 'name' 
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
if (nargout ~= 1) & ((nargout < 4) | (nargout > 9))
   error('ReadAnalyzeHdr, Incorrect number of output arguments');
end;
%
pos=strfind(name,'.img');
if (~isempty(pos))
  name=name(1:(pos(1)-1));
end;  
pos=strfind(name,'.hdr');
if (~isempty(pos))
  name=name(1:(pos(1)-1));
end; 
%
FileName=sprintf('%s.hdr',name);
%

pid=fopen(FileName,'r','ieee-be');

%
% Uncertainty if filesize is written as a int16 or int32
%
header_size=fread(pid,2,'int16');
fileformat='ieee-be';
if (header_size(1) ~= 348) & (header_size(2) ~= 348)
  fclose(pid);
  pid=fopen(FileName,'r','ieee-le');
  header_size=fread(pid,2,'int16');
  fileformat='ieee-le';
  if (header_size(1) ~= 348) & (header_size(2) ~= 348)
    fclose(pid);
    pid=fopen(FileName,'r','ieee-be');
    header_size=fread(pid,2,'int16');
    fileformat='ieee-be';
    fprintf('Not able to detect analyze file format, guessing at ieee-be\n');
  end
end  
fread(pid,36,'uchar');           % dummy read header information
dims=fread(pid,1,'ushort');      % dimension (3 or 4)
dim=fread(pid,4,'ushort');       % dimension, number of pixels
if (dims == 3) | (dim(4) == 1)
  dim=dim(1:3);
end;  
fread(pid,4,'ushort');          
fread(pid,7,'ushort');          
pre=fread(pid,1,'ushort'); % datatype
fread(pid,1,'ushort');
fread(pid,2,'ushort');        
siz=fread(pid,3,'float32');        % size of pixels
fread(pid,4,'float32');
offset=fread(pid,1,'float32');     % offset for pixels (funused8), SPM extension
scale=fread(pid,1,'float32');      % scaling for pixels (funused9), SPM extension

fread(pid,24,'char');

lim=fread(pid,2,'int');            % Limits for number in given analyze format

descr_input=fread(pid,80,'char');  % Description field in header file
descr=char(descr_input)';
descr=deblank(descr);

fread(pid,24,'char');
orient=fread(pid,1,'char');        % Orientation, not used

origin=fread(pid,3,'int16');       % Origin, SPM extension to analyze format

fread(pid,89,'char');              % Not used
fclose(pid);

if (nargout == 1)
  pos=strfind(name,'/');
  if (~isempty(pos))
    hdr.name=name((pos(length(pos))+1):length(name));
    hdr.path=name(1:(pos(length(pos))));
  else
    hdr.name=name;
    hdr.path='';
  end;  
  hdr.pre=pre;
  hdr.dim=dim;
  hdr.siz=siz;
  hdr.lim=lim;
  hdr.scale=scale;
  hdr.offset=offset;
  hdr.origin=origin;
  hdr.descr=descr;
  hdr.fileformat=fileformat;
  pre=hdr;
end







