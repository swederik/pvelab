function A=tala2voxa(Am,hdrI,hdrO)
%
% Function that converts an A matrix defined i Talairach space to an 
%  A matrix in voxel space
%
%  A=tala2voxa(Am,hdrI,hdrO)
%
%  A - A matrix in Voxel space
%  hdrI - header defining right hand side image space (as read 
%          by ReadAnalyzeHdr)
%  hdrO - header defining keft hand side image space (not given, 
%          then hdrI used)
%  Am - A matrix in Talairach space
%
% CS&CM, 201000
%
% Note: If you are creating a voxel defined A matrix for use with   
% Air or warp_reslice you must subtract 1 from the header origins.
%

%
%  tal = (vox - origin) * siz
%
%  B=[sizX    0    0 -originX*sizX;
%        0 sizY    0 -originY*sizY;
%        0    0 sizZ -originZ*sizZ;
%        0    0    0       1];
%
%   TalO = Am * TalI
%   BO * VoxO = Am * BI * VoxI
%   VoxO = inv(BO) * Am * BI * VoxI
%
% dvs
%
%   A = inv(BO) * Am * BI
%
if (nargin == 2)
  hdrO=hdrI;
end  
BI=[diag(hdrI.siz(1:3)) -reshape(hdrI.origin(1:3).*hdrI.siz(1:3),3,1); ...
    0 0 0 1];
BO=[diag(hdrO.siz(1:3)) -reshape(hdrO.origin(1:3).*hdrO.siz(1:3),3,1); ...
    0 0 0 1];
%
A=inv(BO)*Am*BI;
