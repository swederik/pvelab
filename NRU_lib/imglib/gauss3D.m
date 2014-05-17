function [w] = ...
    gauss3D(FWHMx,Sx,FWHMy,Sy,FWHMz,Sz,Err)
%
%    gauss3D(FWHMx,Sx,FWHMy,Sy,FWHMz,Sz,Err)
% GAUSS3D Returns 3D gauss window specified with Filter width half max, and
%    voxel dimension in each direction. Err is max filter value in rand of
%    filter matrix (eq. 0.05)
%    FWHM - Full width half maximum of filter
%
%
% Implemented, Claus Svarer, 01-09-94
% Changed,     Claus Svarer, 200398, using 3 dimensionel matrices
%
if (nargout ~=1)
   fprintf('gauss3D, No. of output arguments different from 1\n');
   return;
end
if (nargin == 5)
   FWHMz=FWHMy;
   Sz=Sy;
   Err=FWHMz;
   FWHMy=FWHMx;
   Sy=Sx;
elseif (nargin ~= 7)
   fprintf('gauss3D, No. of input arguments different from 5 or 7\n');
   return;
end;
%
kx=-log(0.5)/((FWHMx/2)^2);
ky=-log(0.5)/((FWHMy/2)^2);
kz=-log(0.5)/((FWHMz/2)^2);
max_x=sqrt(-1/kx*log(Err));
max_y=sqrt(-1/ky*log(Err));
max_z=sqrt(-1/kz*log(Err));
%
nx=(ceil(max_x/Sx)*2-1);
ny=(ceil(max_y/Sy)*2-1);
nz=(ceil(max_z/Sz)*2-1);
if (nz > 19)
   fprintf('gauss3D, Too many filter coefficients in Z dimension necessary\n'); 
end;
%   
m1=(-(nx-1)/2:(nx-1)/2);
m2=(-(ny-1)/2:(ny-1)/2);
m3=(-(nz-1)/2:(nz-1)/2);
mx=ones(ny,1)*((m1*Sx).^2)*kx;
my=((m2*Sy)'.^2)*ones(1,nx)*ky;
mz=((m3*Sz).^2)*kz;
w=zeros(nx,ny,nz);
for ii=1:nz,
   w(:,:,ii) = exp(-(mx+my+mz(ii)));;
end;
