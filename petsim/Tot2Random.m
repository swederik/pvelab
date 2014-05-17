function counts = tot2random(slicein, scanlength, camera)


%a1=1.0014;

a1 = camera.randomEffectConstant;

w=slicein./(scanlength*60);
%counts = (a1*w.^2 + a2*w);
counts=  w./a1;

counts = counts .* (scanlength*60);
