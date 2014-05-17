function [result]=convert_analyze_to_16bit(FilesToConvert)
%
% [result]=convert_2_16bit(FilesToConvert)
%
% Program for conversion of analyze files (whatever format)
%  to 16 bit signed format format
%
%   FilesToConvert - List of files to convert (cell array with text strings
%                    of file names) 
%
%   result - 1 if no problem, 0 if problem with one or more files
%
% CS, 20020809
%
result=1;
%
if (nargin==0)
    [filename, pathname, filterindex] = uigetfile( ...
	'*.img', ...
        'Analyze files to convert', ...
        'MultiSelect', 'on');
    if iscell(filename)
        for i=1:length(filename)
	      FilesToConvert{i}=fullfile(pathname,filename{i});
        end
    elseif isstr(filename)
        FilesToConvert{1}=fullfile(pathname,filename);
    else    
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
     if (hdr.pre==32) | (hdr.pre==64) | (hdr.pre==8) | ...
	((hdr.pre == 16) & (hdr.lim(1) > 32767))
       if (hdr.offset ~= 0)
	 img=img-hdr.offset;
       end 
       MinImg=min(img(:));
       MaxImg=max(img(:));
       if (MinImg>=0) | ((MaxImg+1)>abs(MinImg))
         Scale=32767/MaxImg;
       else
         Scale=32768/abs(MinImg);
       end  
       img=img*Scale;
       if (hdr.scale~=0)
          hdr.scale=1/Scale*hdr.scale;
       else
          hdr.scale=1/Scale;
       end 
       hdr.offset=0;
       hdr.lim=[32767 -32768];
       hdr.pre=16;
       [res]=WriteAnalyzeImg(hdr,img);
       if (res==0)
         result=0;
       end  
     else
       warning(...
	 sprintf('No conversion needed for file: %s already in 16 bit format',...
	   FilesToConvert{i}));
     end
   else
     result=0;
   end
end  


