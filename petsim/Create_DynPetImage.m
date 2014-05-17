function [sumima, images] = Create_DynPetImage(noise_fact, mrislice, currentslice, ...
    AttYes, ScattYes, diam, RandYes, DecayYes, SpatialResolutionYes, ...
    TracKinModel, camera, frameStartTime, frameStopTime, numberOfruns);
% sumima = Create_DynPetImage(noise_fact, mrislice, currentslice, ...
%     AttYes, ScattYes, diam, RandYes, SpatialResolutionYes, ...
%     TracKinModel, camera, numberOfruns);

%
% 
%

SizeM = size(mrislice,1);
SizeOut = SizeM;
mrislice_vect = round(reshape(mrislice,[SizeM*SizeM 1]));
ima_frames = zeros(SizeM*SizeM,length(TracKinModel.frame_times));
%
% creating the TACT curves for different
% tissue segment
%


for i = 1: TracKinModel.NumOfSegments
    RangeForSegment = find(mrislice_vect == i);
	for j = 1: length(TracKinModel.frame_times)
        ima_frames(RangeForSegment,j) = TracKinModel.tissue_as(i,j);
    end
end
%
% do forwar projection, perform the attenuation effect
% and backprojet the sinograms
%


ima_frames_mat = reshape(ima_frames,SizeM,SizeM,length(TracKinModel.frame_lengths));

%
%Adding the Poisson noise of the radioactivity to the image
%randn('state',sum(100*clock)); %resets the random generator to a different state each time.
%
N=128;

ima_frames_mat_irad = zeros(size(mrislice,1), size(mrislice,2),length(TracKinModel.frame_lengths));




fprintf(['Processing the PET simulation on slice of ',num2str(currentslice),' : ']);
info.color=[1 0 0];
info.title=['Slice : ',num2str(currentslice)];
info.size=1;
p=progbar(info);
%
% calc attenuation matrix
%
att=zeros(camera.members, length(camera.theta) );
if AttYes
	att=attenuationOfSlice(  mrislice, camera );
end;

%
% Spatial resolution effect only for the axial slice. 
%

if ( SpatialResolutionYes )
    for i=1 : length(TracKinModel.frame_lengths)
        ima_frames_mat(:,:,i) = ...
      spatialResolution( ima_frames_mat(:,:,i), camera.radialResolutionValues, camera.radialResolutionRadius, camera.pixelSize );
    end;
%     for t=1:length(TracKinModel.frame_lengths)
%         for i=1:size( ima_frames_mat, 2 )
%           ima_frames_mat(:,i,t)=spatialResolution( ima_frames_mat(:,i,t), camera.axialResolutionValues, camera.axialResolutionRadius, camera.axialPixelSize);
%         end;
%     end;
end;

framestart=0;


for i=1 : length(TracKinModel.frame_lengths) % frame loop for the given slice

 
if mod(i,2)== 0;fprintf('.');progbar(p,round(i/length(TracKinModel.frame_lengths)*100));end
	%Adding the noise of the radioactivity to the image
	randn('state',sum(100*clock)); %resets the random generator to a different state each time.
	ima_frames_mat_irad(:,:,i) = ...
        create_PETnois_onSlicePVE(ima_frames_mat(:,:,i),noise_fact, att,AttYes,ScattYes,diam, ...
        RandYes, DecayYes, TracKinModel.frame_lengths(i),framestart,TracKinModel.T_half, ...
        camera,[size(mrislice,1)  size(mrislice,2)]);
    framestart=framestart+TracKinModel.frame_lengths(i);
end



close(p);
disp(' ');
%
% summing the necessary frames
%
sumima = zeros(size(ima_frames_mat_irad(:,:,1)));
dt = 0;

lastframeid=length( find ( TracKinModel.tissue_ts<frameStopTime ));
if lastframeid > size(ima_frames_mat_irad,3)
    lastframeid=size(ima_frames_mat_irad,3);
end
firstframeid=length( find(TracKinModel.tissue_ts<frameStartTime ))+1;
if ( firstframeid<1 ) firstframeid = 1; end;
    
 for i=firstframeid:lastframeid;
	sumima = sumima + ima_frames_mat_irad(:,:,i)*TracKinModel.frame_lengths(i);
	dt = dt + TracKinModel.frame_lengths(i);
end
sumima = sumima/dt;

images = int32(ima_frames_mat_irad);





