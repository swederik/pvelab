load blood_curves_pars.mat;
ft = [0:1:180];      
figure('Name','Type of blood curves for PET simulator');
for i=1:9                                                            
  subplot(3,3,i);                                                      
  plot(ft, bloodcurve(ft,p(i,:)) ,'b');
  %xlabel('time [sec]');
  %ylabel('Act. conc.[arb. unit]');
  title(['blood curve ',num2str(i),'.']); 
  axis([0 180 0 6000]);
end
 
