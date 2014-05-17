function [outslice,radtemp] = create_PETnois_onSlice(inslice,noise_fact, att,AttYes,ScattYes,diam, RandYes, DecayYes, scanlength, framestarttime, halflife, camera, outsize)
% function outslice = create_PETnois_onSlice(inslice,noise_fact,members)
%

voxelvolume= camera.voxelSize; % ml 2*2*12 mm 

%
% Calculate radioactive decay effect
%

Activity = inline('A0.*exp(-t*log(2)/T12)','t', 'A0','T12');
midtime = framestarttime+scanlength/2;
inslice = Activity(midtime, inslice, halflife);

%
% convert the nCi scale to cps scale and using the scanner calib factor
%
inslice=inslice*60* voxelvolume*37*scanlength;
count_scaler=1/camera.calibrationFactor;


%
% generates the attenuation map and sinogram
%

if AttYes
    % attnoise for att. effect
    attnoise=randn(size(att)).*sqrt(att);
    attnoise(find(attnoise<0))=0;
    attnoise(find(att==1))=0;
    % attnoise for att. correction
    randn('state',sum(100*clock)); 
    attnoise2=randn(size(att)).*sqrt(att);
    attnoise2(find(attnoise2<0))=0;
    attnoise2(find(att==1))=0;
end

% do the radon transformation of inslice
%

[radtemp,Xp] = PETsimRadon(inslice,camera.theta,camera.members);


radtemp=radtemp*count_scaler;

randn('state',sum(100*clock)); 
radtemp=radtemp+randn(size(radtemp)).*(sqrt(radtemp)*noise_fact);
radtemp=round(radtemp);


%
% do the attenuation effect
%
if AttYes
    radtemp = radtemp./(att+attnoise);
    radtemp=round(radtemp);
end

%
% adding the scatter counts
%
if ScattYes
    scattereff=ScatterCorrGE4096(radtemp, diam, camera);
    randn('state',sum(100*clock)); 
    scattereff=scattereff+(randn(size(scattereff)).*sqrt(scattereff));
    radtemp = radtemp + scattereff;
    radtemp=round(radtemp);
end

%
% adding the random counts
%
if RandYes
   
    randomeff=TotPlusRandom2Random(radtemp, scanlength, camera);
    randomeff=real(randomeff);
    randomeff(find(randomeff<0)) = 0;
    randn('state',sum(100*clock)); 
    radtemp=radtemp+ randomeff + randn(size(randomeff)).*sqrt(randomeff);
    radtemp=round(radtemp);
end


%
% adding the noise
%
%  noise = randn(size(radtemp)).*sqrt(radtemp).*noise_fact;
%  radtemp = radtemp + noise;
%  radtemp=round(radtemp);
%     radtemp(find(radtemp<0)) = 0;
%     
%
% correction the random counts
%
if RandYes
    randcorr=TotPlusRandom2Random(radtemp, scanlength, camera);
    randcorr=real(randcorr);
    randcorr(find(randcorr<0)) = 0;
    randn('state',sum(100*clock)); 
    radtemp=radtemp - randcorr - randn(size(randcorr)).*sqrt(randcorr);
  
    radtemp=round(radtemp);
end

%
% correction the scatter counts
%
if ScattYes
    scatcorr = ScatterCorrGE4096(radtemp, diam, camera);
    randn('state',sum(100*clock)); 
    scatcorr=scatcorr+(randn(size(scatcorr)).*sqrt(scatcorr ));
    radtemp = radtemp - scatcorr;
    radtemp=round(radtemp);
end

%
% do the atten. corr with the noisy atten. sinog
%
if AttYes
    radtemp = radtemp.*(att+attnoise2);
    radtemp=round(radtemp);
end

%
% reconstruct the image
%
 
radtemp=radtemp./count_scaler;

outslice = iradon(radtemp,camera.theta,'spline','Hann');

% these lines is important because the iradon shift the image in x
% dircetion 
K=outslice(2:size(outslice,1),1:size(outslice,2));
K(size(outslice,1),1:size(outslice,2))=0;
outslice=K;


outslice(find(outslice < 0 )) = 0;
outslice = outslice ./(voxelvolume*37*scanlength*60);

outslice=imresize(outslice, outsize ,'bilinear');

%
%   Correct for decay effect
%

if (DecayYes)
    outslice=outslice.*(2^(midtime/halflife));
end;



outslice=outslice./0.639; % ha a GE4096 radont hasznaljuk 96 bin



