function [out, Xp]=attenuationOfSlice( attslice, camera )


attslice=spatialResolution(attslice, camera.radialResolutionValues, camera.radialResolutionRadius, camera.pixelSize );
attslice = double(imfill(attslice,'holes'));
attrange = find(attslice >0);
attslice(attrange) = 0.096*camera.pixelSize/10;

[trarad, Xp] = PETsimRadon(attslice,camera.theta,camera.members);
out=exp(trarad);




