function w = gauss2D(FWHMx,SizX,FWHMy,SizY,Err)
%GAUSS2 GAUSS2(N) returns the N-point 2 dimensional Gauss window in a matrix.
%
%    w = gauss2D(FWHMx,SizX,FWHMy,SizY,Err)
%
% Gauss clock used
%
%  FWHM - Filter width half max
%  Siz  - Pixel size
%  Err  - Max error in periphery of filter
%
% Can be used by conv2 to filter aa image with an Gauss vindow.
%
% Implemented, Claus Svarer, 19-9-94
%
kx=-log(0.5)/((FWHMx/2)^2);
ky=-log(0.5)/((FWHMy/2)^2);
max_x=sqrt(-1/kx*log(Err));
max_y=sqrt(-1/ky*log(Err));
%
nx=(ceil(max_x/SizX)*2-1);
ny=(ceil(max_y/SizY)*2-1);
%   
m1=(-(nx-1)/2:(nx-1)/2);
m2=(-(ny-1)/2:(ny-1)/2);
mx=ones(ny,1)*((m1*SizX).^2)*kx;
my=((m2*SizY)'.^2)*ones(1,nx)*ky;
w = exp(-(mx+my));;
