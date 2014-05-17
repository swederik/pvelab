function petAnalSimMain(main_gui_handle)
% function petAnalSimMain(SegmentedmriName,outputfilename, ...
%     AttYes,ScattYes,diam, RandYes,SpatialResolutionYes,  ...
%     noise_fact,bloodtype, cameraparfile)

%
% setup the initial variables
%

outputfilename = main_gui_handle.outputfilename;
AttYes = main_gui_handle.AttYes;
ScattYes = main_gui_handle.ScattYes;
diam = main_gui_handle.diam;
RandYes = main_gui_handle.RandYes;
DecayYes = main_gui_handle.DecayYes;
SpatialResolutionYes = main_gui_handle.SpatialResolutionYes;
noise_fact = main_gui_handle.noise_fact;
cameraparfile = main_gui_handle.cameraparfile;
mrihdr = main_gui_handle.mrihdr;
frameStartTime = main_gui_handle.FrameStartTime;
frameStopTime = main_gui_handle.FrameStopTime;
saveImageFrames = main_gui_handle.saveEachTimeFrames;

%
% setup the tracer kinet model for segments
%
TracKinModel.MaxNumOfSegments = main_gui_handle.MaxNumOfSegments;
TracKinModel.NumOfSegments =  main_gui_handle.NumOfSegments; 
TracKinModel.T_half = main_gui_handle.T_half;
TracKinModel.frame_times = main_gui_handle.frame_times;
TracKinModel.frame_lengths = main_gui_handle.frame_lengths;
TracKinModel.tissue_ts = main_gui_handle.tissue_ts;
TracKinModel.tissue_as = main_gui_handle.tissue_as;
%
%load the camera setup parameter file
%
camera=loadCameraParameters( cameraparfile );
%
%resampling the segmented mri VOL to PET resolution (slice width)
%

TotmriSliceNumberForSim = fix(fix(mrihdr.dim(3)*mrihdr.siz(3)/camera.axialPixelSize)*camera.axialPixelSize/mrihdr.siz(3));
TotpetSliceNumberForSim =fix(mrihdr.dim(3)*mrihdr.siz(3)/camera.axialPixelSize);

SegmentedResampledmriImg3D=int16(CreateSegmentedResampledMRI( main_gui_handle ));

%
% Slice loop for PET image simulation
%
sumout2anal = [];
numberOfruns = 1;


ofname=outputfilename;
disp(['The total number of slice for PET simulation is ',num2str(TotpetSliceNumberForSim),'.']);
for nruns=1:numberOfruns
tic;

imgframes = 1;

montage_handle = -1;
img = int32(zeros(1,1,1));
axes_handle = -1;
map = colormap('spectral');

startslice = 1;
endslice = TotpetSliceNumberForSim;
% startslice=15;
% endslice=15;

for i = 1 : endslice-startslice+1
    mrislice=double(SegmentedResampledmriImg3D(:,:,i+startslice-1));
    if max(max(mrislice)) ~=0
        [sumima, images] = Create_DynPetImage(noise_fact,mrislice,i+startslice-1, ...
            AttYes,ScattYes,diam, RandYes,DecayYes, SpatialResolutionYes, ...
            TracKinModel, camera, frameStartTime, frameStopTime, numberOfruns);

        sumima=flipud(sumima');      
        sumima = imresize(sumima,[mrihdr.dim(1)  mrihdr.dim(2)] ,'bilinear');
  
         if ( size(img, 1 )~=size(sumima,1) && size(img,2)~=size(sumima,2) )
            img=int32(zeros(size(sumima,1),size(sumima,2), endslice-startslice+1));
            figure; 
            axes_handle=axes;
        end;
 
         img(:,:,i)=int32(sumima);
         axes(axes_handle);
         montage_handle = petmontage( img, montage_handle );
         colorbar('peer', axes_handle);
       
	if ( saveImageFrames )
      	if ( (size(imgframes,1) ~= mrihdr.dim(1)) && (size(imgframes,2) ~= mrihdr.dim(2))) 
			imgframes=int32(zeros( mrihdr.dim(1), mrihdr.dim(2),  endslice-startslice+1, size(images,3)));
		end;
		for t=1:size(images,3)
		        % Changed by CS to have the code working at images
			% with different X,Y
			imgframes(:,:,i,t)=int32(imresize(double(images(:,:,t)'),[mrihdr.dim(1)  mrihdr.dim(2)] ,'bilinear')) ;
			% imgframes(:,:,i,t)=int32(images(:,:,t)');
		end;
	end;
        sumout2anal = [sumout2anal reshape(sumima,[1 mrihdr.dim(1)*mrihdr.dim(2)])];
    else
        disp(['No segmented information on resampled MRI slice of ',num2str(i),'.']);
        sumout2anal = [sumout2anal zeros(1,mrihdr.dim(1)*mrihdr.dim(2))];
    end
end

%
% creating analyse format output file 
%

%outputfilename=[ofname '_' int2str(nruns)]

hdrout.name=outputfilename;
hdrout.path='';
hdrout.pre=16;
hdrout.lim=[32767 -32768];
hdrout.dim=[mrihdr.dim(1) mrihdr.dim(2) endslice-startslice+1];% num of PET slice generated
hdrout.siz=[mrihdr.siz(1) mrihdr.siz(2) camera.axialPixelSize];
hdrout.origin=[0 0 0];
hdrout.scale = max(sumout2anal(:))/32767;
sumout2anal_scaled = sumout2anal/hdrout.scale;
if (min(sumout2anal_scaled(:))<-32768)
  ExtraScale=min(sumout2anal_scaled(:))/(-32768)
  hdrout.scale=hdrout.scal*ExtraScale;
  sumout2anal_scaled=sumout2anal_scaled/ExtraScale;
end
sumout2anal_scaled=round(sumout2anal_scaled);
hdrout.offset=0;
hdrout.descr='petsim simulated image (sum)';
%
% Shifting of dim 1 and 2 needed for none known reason
%
sumout2anal_scaled=reshape(sumout2anal_scaled,hdrout.dim);
sumout2anal_scaled=permute(sumout2anal_scaled,[2 1 3]);
sumout2anal_scaled=flipdim(sumout2anal_scaled,2);
%
[result] = WriteAnalyzeImg(hdrout,sumout2anal_scaled);

% write dynamic analyze
if ( saveImageFrames )
  hdrout.name=[outputfilename '_frames'];
  hdrout.path='';
  hdrout.pre=32;
  hdrout.lim=[0 0];
  hdrout.dim=[mrihdr.dim(1) mrihdr.dim(2) endslice-startslice+1 length(TracKinModel.frame_times)];
  hdrout.siz=[mrihdr.siz(1) mrihdr.siz(2) camera.axialPixelSize];
  hdrout.origin=[0 0 0];
  hdrout.scale = 1;
  hdrout.offset=0;
  hdrout.descr='petsim simulated image (all frames)';
  %
  % Shifting of dim 1 and 2 needed for none known reason
  %
  imgframes=reshape(imgframes,hdrout.dim);
  imgframes=permute(imgframes,[2 1 3 4]);  
  %
  [result] = WriteAnalyzeImg(hdrout,imgframes);
  
  fid=fopen([hdrout.name '.tim'],'w');
  if fid~=(-1)
    for i=1:length(TracKinModel.frame_times)
      fprintf(fid,'%e\t%e\n',TracKinModel.frame_times(i),TracKinModel.frame_lengths(i));
    end
    fclose(fid);
  end;
end;

%

t = toc;
disp(['The simulation was done. The elapsed time was ', num2str(round(t/60)),' min.']);

end;

