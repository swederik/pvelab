function []=ConvertDyn2Frames(Name);
%
% Convert dynamically data from new 4 dim file format to 
%  individual file frames
%
%   Can be called with one input argument - the file name of dyn file
%
%  New files are created as:  <Name>_f01  (for frame 01)
%
%  CS, 070900, 
%
if (nargin == 1),
  if ((exist(Name) == 2) | (exist([Name '.img']) == 2))
    [PATHNAME,FILENAME,ext]=fileparts(Name);
  else
    error('Specified file in input does not exist');   
  end;  
else
   [FILENAME, PATHNAME] = uigetfile('*.img', 'File to convert', 0, 0);
   if (FILENAME == 0)
     error('No file chosen\n')
   end; 
end;
[pn,FILENAME,ext]=fileparts(FILENAME);
%
hdr=ReadAnalyzeHdr(fullfile(PATHNAME,FILENAME));
%
if (length(hdr.dim) ~= 4)
  if (hdr.dim(4) == 1)
    error('Dimension of input image file not 4D');
  end;  
end; 
%
hdrOut=hdr;
hdrOut.dim(4)=1;
%
for i=1:hdr.dim(4),
  fprintf('Working on frame: %u\n',i);
  img=ReadAnalyzeImg(fullfile(PATHNAME,FILENAME),sprintf(':%u',i));
  OutFILENAME=sprintf('%s_f%02u',FILENAME,i);
  hdrOut.name=OutFILENAME;
  hdrOut.path=PATHNAME; 
  [result]=WriteAnalyzeImg(hdrOut,img);
end;




