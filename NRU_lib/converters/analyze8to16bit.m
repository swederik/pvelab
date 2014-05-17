function [result]=analyze8to16bit(FilesToConvert)
%
% [result]=analyze8to16bit(FilesToConvert)
%
% Program for conversion of 8 bit analyze files
%  to 16 bit signed format format, without changing
%  the bit value in each voxel
%
%   FilesToConvert - List of files to convert (cell array with text strings
%                    of file names) 
%
%   result - 1 if no problem, 0 if problem with one or more files
%
% CS, 20021129
%
result=1;
%
if (nargin==0)
  Tmp=pwd;
  [FilesToConvert,res,filter_out,hout] = ...
       ui_choosefiles(Tmp, '*.img', ...
       'Analyze files to convert?');
  delete(hout);
  cd(Tmp);
  if (res == -1)  
    warning('No analyze files selected');
    result=0;
    return
  end
end 
%
if isstr(FilesToConvert)
  FilesToConvert={FilesToConvert};
end  
%
for i=1:length(FilesToConvert);
   fprintf(...
       'Starting conversion of file : %s a _i16 will be added to the filename\n',...
       FilesToConvert{i});
   %
   [img,hdr]=ReadAnalyzeImg(FilesToConvert{i});
   %
   if ~isempty(img)
     hdr.name=[hdr.name '_i16'];
     if (hdr.pre==8)
       hdr.lim=[32767 -32768];
       hdr.pre=16;
       [res]=WriteAnalyzeImg(hdr,img);
       if (res==0)
         result=0;
       end  
     else
       warning(...
	 sprintf('This routine can only handle 8 bit files: %s is not a 8 bit file',...
	   FilesToConvert{i}));
     end
   else
     result=0;
   end
end  


