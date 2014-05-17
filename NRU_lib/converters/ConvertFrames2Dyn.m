function []=ConvertFrames2Dyn(Name,OutName);
%
% function ConvertFrames2Dyn(Name,OutName);
%
% Convert dynamically data from individual file frames to
%    new 4 dim file format
%
%  Name - name of one of the frames, shal be named as:
%            c2_d3_Test_____________16_f01.img
%    where f01 is relating to frame 01.
%    scalefactor and offset shall be the same for all frames
%
%  OutName - Name of outfile (if left out, input file name without _f01
%            is used)
%
%   Can be called with one input argument - the file name of first frame
%
%  CS, 070900, Updated with origin information
%
if (nargin >= 1),
  if ((exist(Name) == 2) | (exist([Name '.img']) == 2))
     pos=strfind(Name,'/');
     if (~isempty(pos))
        LastPos=pos(length(pos));
        FILENAME=Name(pos+1:length(Name));
        PATHNAME=Name(1:pos);
     else
        FILENAME=Name;
        PATHNAME='';
     end
  else
     error('Specified file in input does not exist');   
  end;  
else
  [FILENAME, PATHNAME] = uigetfile('*.img', '1st Frame file to convert', 0, 0);
  if (FILENAME == 0)
    error('No file chosen\n')
  end; 
end;   
pos=strfind(FILENAME,'.img');
if (~isempty(pos))
  FILENAME=FILENAME(1:pos(1)-1);
end  
pos=strfind(FILENAME,'.hdr');
if (~isempty(pos))
  FILENAME=FILENAME(1:pos(1)-1);
end  
FILENAMEbase=FILENAME(1:length(FILENAME)-4);
FirstFrameNumber=str2num(FILENAME(length(FILENAME)-1:length(FILENAME)));
if (nargin <= 1)
  FILENAMEout=FILENAME(1:length(FILENAME)-4);
else
  FILENAMEout=OutName;
  pos=strfind(FILENAMEout,'.img');
  if (~isempty(pos))
    FILENAMEout=FILENAMEout(1:pos(1)-1);
  end  
  pos=strfind(FILENAMEout,'.hdr');
  if (~isempty(pos))
    FILENAMEout=FILENAMEout(1:pos(1)-1);
  end  
end  
%
hdr=ReadAnalyzeHdr([PATHNAME FILENAME]);
%
if (length(hdr.dim) ~= 3)
    error('Dimension of input image file shall be 3D');
end; 
%
Stop=0;
Frame=FirstFrameNumber;
Count=1;
MaxScale=0;
while (Stop == 0)
  FrameName=sprintf('%s_f%02u',[PATHNAME FILENAMEbase],Frame);
  if (exist([FrameName '.hdr']) == 2)
     fprintf('Checking frame: %u\n',Frame);
     hdr=ReadAnalyzeHdr(FrameName);
     MaxScale=max([MaxScale hdr.scale]);
     Count=Count+1;
     Frame=Frame+1;
  else
     Stop = 1;
  end;
end;
LastFrameNumber=Frame-1;
%
imgOut=zeros(prod(hdr.dim)*(Count-1),1);
%
Count=1;
for i=FirstFrameNumber:LastFrameNumber
  FrameName=sprintf('%s_f%02u',[PATHNAME FILENAMEbase],i);
  if (exist([FrameName '.img']) == 2)
     fprintf('Working on frame: %u\n',i);
     [img,hdr]=ReadAnalyzeImg(FrameName);
     if (hdr.scale~=MaxScale)
       img=round(img*hdr.scale/MaxScale);
     end
     imgOut((Count-1)*prod(hdr.dim)+1:Count*prod(hdr.dim))=img;
     Count=Count+1;
  else
    error('Image file does not exist');
  end
end  
Count=Count-1;
%
hdrOut=hdr;
hdrOut.dim(4)=Count;
hdrOut.name=FILENAMEout;
hdrOut.path=PATHNAME;
hdrOut.scale=MaxScale;
WriteAnalyzeImg(hdrOut,imgOut);



















