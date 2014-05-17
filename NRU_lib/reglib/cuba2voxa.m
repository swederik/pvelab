function A=cuba2voxa(Acub,hdrI,hdrO)
%
% Function that converts an A matrix defined i Talairach space to an 
%  A matrix in cubic voxel space
%
%  A=tala2cuba(Acub,hdrI,hdrO)
%
%  A - A matrix in Voxel space
%  hdrI - header defining right hand side image space (as read 
%          by ReadAnalyzeHdr)
%  hdrO - header defining keft hand side image space (not given, 
%          then hdrI used)
%  Acub - A matrix in Talairach space
%
% PW, NRU, 2001
%
% Note: If you are creating a voxel defined A matrix for use with   
% Air or warp_reslice you must subtract 1 from the header origins.
%

Asc=diag([min(hdrO.siz)./hdrO.siz' 1]);
A=Acub*inv(Asc);

