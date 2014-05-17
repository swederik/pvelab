function SegmentedResampledmriImg3D=CreateSegmentedResampledMRI( main_gui_handle )

mrihdr = main_gui_handle.mrihdr;
SegmentedmriImg = main_gui_handle.SegmentedmriImg;
camera=loadCameraParameters( main_gui_handle.cameraparfile ); 



TotmriSliceNumberForSim = fix(fix(mrihdr.dim(3)*mrihdr.siz(3)/camera.axialPixelSize)*camera.axialPixelSize/mrihdr.siz(3));
TotpetSliceNumberForSim =fix(mrihdr.dim(3)*mrihdr.siz(3)/camera.axialPixelSize);
SegmentedmriImg3D = reshape(SegmentedmriImg,[mrihdr.dim(1) mrihdr.dim(2) mrihdr.dim(3)]);
SegmentedmriImg3D = SegmentedmriImg3D(:,:,1:TotmriSliceNumberForSim); 

xsize=size(SegmentedmriImg3D,1);
ysize=size(SegmentedmriImg3D,2);
maxdim=max([xsize ysize]);
r1=maxdim/2-size(SegmentedmriImg3D,1)/2+1;
r2=r1+size(SegmentedmriImg3D,1)-1;
r3=maxdim/2-size(SegmentedmriImg3D,2)/2+1;
r4=r3+size(SegmentedmriImg3D,2)-1;
SquareSegmentedmriImg3D=zeros(maxdim, maxdim, TotmriSliceNumberForSim);
SquareSegmentedmriImg3D(r1:r2, r3:r4,:)=SegmentedmriImg3D;

disp('Resampling the segmented brain volume to the PET resolution');
SegmentedResampledmriImg3D = zeros(maxdim, maxdim,TotpetSliceNumberForSim);
for i=1:maxdim
    if mod(i,4)==0 
        fprintf('.');
    end
    SegmentedResampledmriImg3D(i,:,:)= ...
        imresize(squeeze(SquareSegmentedmriImg3D(i,:,:)),[maxdim TotpetSliceNumberForSim]);
end
fprintf(' Done');
disp(' ');