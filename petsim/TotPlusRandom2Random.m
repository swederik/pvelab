function counts = TotPlusRandom2Random(slicein, scanlength, camera)
% function counts = tot2random(slicein)
% random profile versus random + total counts


w=slicein./(scanlength*60);


a1=camera.randomCorrectionConstants(1);
a2=camera.randomCorrectionConstants(2);

counts = a1*w.^2+w.*a2;

counts = counts .* (scanlength*60);