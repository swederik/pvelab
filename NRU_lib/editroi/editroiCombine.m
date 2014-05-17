function []=editroiCombine(EditroiIn,EditroiOut)
%
%  []=editroiCombine([EditroiIn,EditroiOut])
%
%  Interactive tool for combining multiple editroi files into one file
%
%   EditroiIn - Cell array of editroi files to combine into one editroi file
%   EditroiOut - Name of created editroi file
%
% CS, 20030909, Vers. 1
%
if (nargin~=0) & (nargin~=2)
  error('editroiCombine has to be called with zero or two input arguments');
elseif (nargin == 0)
  Stop=0;
  Counter=1;
  EditroiInFN=[];
  while (Stop==0)
    TxtStr=sprintf('Name of editroi file no. %i to include',Counter);
    [EditroiInFN, EditroiInPN] = ...
      uigetfile('*.mat', TxtStr);
    if (EditroiInFN==0)
      Stop=1;
    else  
      EditroiIn{Counter}=[EditroiInPN EditroiInFN];
      Counter=Counter+1;
    end
  end  
  if isempty(EditroiIn)
    error('At least one files has to be selected for including in output file');
  end
  %
  [EditroiOutFN, EditroiOutPN] = ...
    uiputfile('*.mat', 'Name of editroi file to combine ROIs into');
  if (EditroiOutFN==0)
    error('Editroi file has to be defined');
  end
  EditroiOut=[EditroiOutPN EditroiOutFN];
end  
%
for i=1:length(EditroiIn)
  RoiIn{i}=load(EditroiIn{i});
end  
%
RoiOut=CombineRois(RoiIn);
%
SaveRoi(EditroiOut,RoiOut);



function [RoiOut]=CombineRois(RoiIn)
%
% Function that combine rois from multiple files
%

% Test fro common slicedist
%
for i=1:length(RoiIn)
  Slicedist(i)=RoiIn{i}.slicedist;
end
if length(unique(Slicedist))>1
  error('editroiCombine, Selected editroi files dont have same slicedist');
end
%
RoiOut=RoiIn{1};
RoiOut=rmfield(RoiOut,{'regionname','relslice','region','mode','vertex'});
%
RoiOutNumber=1;
VertexNumber=1;
for k=1:length(RoiIn) % Number of ROI files
  for j=1:length(RoiIn{k}.regionname) % Number of ROIs in each file 
    RoiOut.regionname{RoiOutNumber,1}=RoiIn{k}.regionname{j};
    pos=find(RoiIn{k}.region==j);
    for i=1:length(pos)  % Number of vertex's for each ROI
      RoiOut.relslice(VertexNumber,1)=RoiIn{k}.relslice(pos(i));
      RoiOut.region(VertexNumber,1)=RoiOutNumber;
      RoiOut.mode{VertexNumber,1}=RoiIn{k}.mode{pos(i)};
      RoiOut.vertex{VertexNumber,1}=RoiIn{k}.vertex{pos(i)};
      VertexNumber=VertexNumber+1;
    end  
    RoiOutNumber=RoiOutNumber+1;
  end  
end













