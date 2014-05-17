function Am=voxa2tala(A,hdrI,hdrO)
%
% Function that converts an A matrix defined i voxel space to an 
%  Am matrix in Talairach space
%
%  Am=voxa2tala(A,hdrI,hdrO)
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
%


%
%  vox = tal/siz + origin
%
%  C=[1/sizX      0      0 originX;
%          0 1/sizY      0 originY;
%          0      0 1/sizZ originZ;
%          0      0      0    1];
%
%   VoxO = A * VoxI
%   CO * TalO = A * CI * TalI
%   TalO = inv(CO) * A * CI * TalI
%
% dvs
%
%   Am = inv(CO) * A * CI
%

if (nargin == 2)
  hdrO=hdrI;
end  
CI=[diag(1./hdrI.siz(1:3)) reshape(hdrI.origin(1:3),3,1); ...
    0 0 0 1];
CO=[diag(1./hdrO.siz(1:3)) reshape(hdrO.origin(1:3),3,1); ...
    0 0 0 1];
%
Am=inv(CO)*A*CI;
