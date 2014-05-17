function [w] = hanning2D(FWHMx,Sx,FWHMy,Sy)
%
% HANNING2D Returns 2D hanning window specified with Filter width half max, and
%    voxel dimension in each direction. 
%    FWHM - Full width half maximum of filter
%
% Implemented, Claus Svarer, 19-09-94
%
if (nargout > 1)
   fprintf('hanning2D, Too many output arguments, more than 1\n');
   return;
end
w=[];
if (nargin == 2)
   FWHMy=FWHMx;
   Sy=Sx;
elseif (nargin ~= 4)
   fprintf('hanning2D, No. of input arguments different from 2 or 4\n');
   return;
end;
%
nx=(ceil(FWHMx/Sx)*2-1);
ny=(ceil(FWHMy/Sy)*2-1);
%   
m1=(-(nx-1)/2:(nx-1)/2)/(nx+1);
m2=(-(ny-1)/2:(ny-1)/2)/(ny+1);
mx=ones(ny,1)*m1;
my=m2'*ones(1,nx);
msqxy=mx.^2+my.^2;
mxy=sqrt(msqxy);
mmm=1/2-mxy;
mmm=mmm.*(mmm>0);
w = .5*(1 - cos(2*pi*mmm));
