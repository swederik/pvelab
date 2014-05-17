function []=CreateUnityAIRDiffRes(FilenameIn,FilenameOut,AIRfile)
%
% []=CreateUnityAIRDiffRes([FilenameIn,FilenameOut])
%
% Create and AIR with the unity transformation for a selected analyze file
%  In pvelab it is assumed that (0,0,0) is in the center of the lower left
%  corner voxel in first slide, this means that if the input and out image
%  has different resolution then the no movement matrix has to have a
%  translation build in, containing this resolution change. 
%
%  Like if input image has resolution 2x2x2 mm the center of lower left
%  voxel is (1,1,1) mm and output image has resolution 1x1x2 mm and center
%  of lower left voxel (0.5,0.5,1)mm then a translation like 0.5,0.5,0 mm
%  is needed in the AIR matrix to have no movement. This could be the case
%  if you have a volume of 256x256x63 voxels (1x1x2mm) in MR space and 128x128x63
%  voxels (2x2x2mm) in PET space and images are already brought into same space.
%
%   FilenameIn - Analyze file for which to create the homogene unity
%                 transformation from - eye(4)
%   FilenameOut - Analyze file for which to create the homogene unity
%                 transformation to
%   AIRfile    - Name of AIR file
%
if nargin==0
    [fn,pn]=uigetfile('*.img','Select the analyze file to transfer?');
    if (fn==0)
        error('CreateUnityAIR: No analyze file selected');
    end
    FilenameIn=[pn,fn];
    [fn,pn]=uigetfile('*.img','Select the analyze file to transfer to?');
    if (fn==0)
        error('CreateUnityAIR: No analyze file selected');
    end
    FilenameOut=[pn,fn];
    [dd,fn,ext]=fileparts(fn);
    AIRfile=fullfile(pn,[fn '.air']);
end
%
%
%
hdrIn=ReadAnalyzeHdr(FilenameIn);
hdrOut=ReadAnalyzeHdr(FilenameOut);
Atal=eye(4);
Atrans=-[hdrOut.siz(1)/2-hdrIn.siz(1)/2;...
         hdrOut.siz(2)/2-hdrIn.siz(2)/2;
         hdrOut.siz(3)/2-hdrIn.siz(3)/2];
Atal(1:3,4)=Atrans;
%
strct.A=Atal;
[pnIn,fnIn]=fileparts(FilenameIn);
[pnOut,fnOut]=fileparts(FilenameIn);
strct.descr=sprintf('Identity transformation from %s to %s',fnIn,fnOut);
if length(strct.descr)>80
    strct.descr=strct.descr(1:79);
end
strct.endian='ieee-le';
strct.nruformat=0;
strct.hdrI=hdrIn;
strct.hdrO=hdrOut;
SaveAir(AIRfile,strct);
