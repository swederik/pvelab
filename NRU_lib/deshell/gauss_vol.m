function [volf]=gauss_vol(vol,vox_size,filt_size,mult_filt)
% Filter a three dimensional image volume by a gaussian filter kernel
% 
%  [volf]=gauss_vol(vol,vox_size,filt_size,mult_filt)
%
%  vol       - Image volume to filter (3 dimensional, doubles)
%  vox_size  - Voxel size (3 dimensional, in mm), (if empty assumed to be 1)
%  filt_size - FWHM for Gaussian filter (3 dimensional)
%  mult_filt - Size of Gaussian kernel (mult_filt*filt_size is Gaussian
%                kernel size) (if empty or undefined assumed to be 4)
%
%  volf      - Filtered image volumen (3 diensional, doubles)
%
%    [volf]=gauss_vol(vol,[2 2 2],[12 12 8],4)
%    [volf]=gauss_vol(vol,[],[12 12 8],[])
%    [volf]=gauss_vol(vol,[],[12 12 8])
%
%  CS, 171198  
%
%  Procedure based on Ulrik Kjems gaussian filter
%
if strcmp(computer,'PCWIN64') || ismac
    filt=gauss3D(filt_size(1),vox_size(1),filt_size(2),vox_size(2),filt_size(3),vox_size(3),0.05);
    fprintf('Parameter mult_filt is not used\n');
    volf=convn(double(vol),filt,'same')/sum(filt(:));
end