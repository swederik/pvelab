function []=SaveRoi(filename,roi);
% function []=SaveRoi(filename,roi)
% 
% Save roi structure in a Editroi file
%
% CS&PW, 290801
%
if nargin~=2
  error('Wrong number of input parameters');
end
%
vertex=roi.vertex;
mode=roi.mode;
region=roi.region;
relslice=roi.relslice;
regionname=roi.regionname;
slicedist=roi.slicedist;
filetype=roi.filetype;
%
v=version;
if v(1)>'6'
   save(filename,'vertex','mode','region','regionname','relslice',...
      'slicedist','filetype','-V6');
else
   save(filename,'vertex','mode','region','regionname','relslice',...
      'slicedist','filetype');
end