function tissue_as = create_4CompTacs(k, tissue_ts, bloodcurvepar)
%tissue_as = create_4CompTacs(k,tissue_ts,bloodpar)

%k = [0.8542 0.0785 0.0502 0.0227 0];
%C11-MDL 100907 

%k = [0.0613 0.0776 0.0734 0.0135 0];
%F18-FCWAY 100635

% loading the blood curve and parameteres	
%     load blood_curves_c11_pars.mat;
% 	blood_par = p(bloodtype,:);

%calculating the frame meadtimes

frame_lengths = diff(tissue_ts);
frame_times = tissue_ts(1:end-1)+frame_lengths/2;

%creating fine time scale and the bloodcurve
dtime=max(tissue_ts)/10000;	%5[sec]
fine_ts=[0:dtime:max(tissue_ts)];
blood_curve = bloodcurve(fine_ts, bloodcurvepar);

A=[	-( k(2) + k(3) + k(5) ) 	 k(4)           k(6)    0	
    	k(3)  		            -k(4)           0	    0
	    k(5)                       0            -k(6)   0            
        (1-k(7))	            (1-k(7))	   (1-k(7)) 0 ];

B=[ 	k(1)	0	0  k(7)]';


%creating the sampled tissue and blood curves 
FI=expm(A*dtime);
%disp('start the calculation of G matrix');
G=mat_int(A,0,dtime);
%disp('the calculation of G matrix is finished');
C_=zeros(4,length(fine_ts));

for i=1:length(fine_ts)-1
	C_(:,i+1) = FI *C_(:,i)+G*B*blood_curve(i);
end

%interpolate the integrated tissue activity at the tissue_ts 
int_tissue_as = C_(4,:);
int_tissue_as_ip = interp1(fine_ts,int_tissue_as,tissue_ts);

%calculate the integral values for the frame_times
tissue_as =  diff(int_tissue_as_ip)./diff(tissue_ts);



