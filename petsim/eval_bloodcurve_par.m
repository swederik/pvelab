function bloodpar = eval_bloodcurve_par(blood_ts0, blood_as0,plotyes)
% function parameters = eval_bloodcurve_par(blood_ts,blood_as,plotyes)
% This modul calculates the fitted blood_curve parameters. The analytical 
% form of the fitted curve taken from D.Feng at al. Models for 
% computer simulation studies of ... ,Int J. biomed comput, 32(1993) 95-110 
%
%
% Inputs:  blood_ts0 - blood curve time points
%          blood_as0 - blood curve activity values 
%          plotyes   - {1 for plotting results ,0 - no graphical output} 
% Outputs:	
%	blood curve parameters=[A1 A2 A3 lambda1 lambda2 lambda3 tau] 
%		
%  
%	
% DEOEC PET CENTER	
% Used own moduls: 	fitblood.m;	bloodcurve.m;	
% History:
% 30/07/1997 BL

global blood_as blood_ts bloodpar

if nargin < 3
    plotyes = 0;
end

% set the activity = 0 at t= 0
blood_ts=[0,blood_ts0']';
blood_as0=[0,blood_as0']';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% set the bloodcurve Y scale to 100. It is needed 
% for the parameter's initial values (p0)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
max_blood_as=max(blood_as0);
blood_as=100/max_blood_as*blood_as0; 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%start the the fitting of tissue curve for calculating k's
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
disp(' ');
disp('Start the blood curve fitting procedure ... ');
tic; 

%p0=[1000 10 10 -1 -0.1 -0.01 0.5];
p0=[850 20 20 -4.1 -0.12 -0.01 0];
%p0=[A1 A2 A3 lambda1 lambda2 lambda3 tau]. The fitted curve taken from :
% D.Feng at al. Models for computer simulation studies of ... ,
% Int J. biomed comput, 32(1993) 95-110

 
options(1)=0;%display opt. output
options(2)=1e-4;%termination criteria for x
options(3)=1;% Termination criteria for f 
%options(4)=1e-4;% Termination criteria for g
%options(16)=1e-4;% Min perturb
%options(17)=0.1;%Max perturb
options(14)=2000;%max num. of step
%vlb=[10, 1, 1, -5, -1, -0.1 0.01];
vlb=[10, 1, 1, -5, -1, -0.1 0.1];
%vlb=[10, 1, 1, -15, -5, -0.1 0.000]; %def
%vub = [1000, 10, 10, -0.001, -0.001, -0.001 1];
vub = [1000, 100, 100, -0.001, -0.001, -0.001 1];
%vub = [10000, 1000, 1000, -0.0001, -0.0001, -0.0001 1]; %def

%par=constr('fitblood',p0,options,vlb,vub);
A = [-1 0 0 0 0 0 0;
     0 -1 0 0 0 0 0;
     0 0 -1 0 0 0 0];
B = [0;0;0];
options = optimset('fmincon');
par=fmincon('fitblood',p0,A,B,[],[],vlb,vub,[],options);

maxt=round(max(blood_ts))+1;
dt=maxt/500;
fine_ts=[0:dt:maxt]';
par([1:3])=par([1:3])*max_blood_as/100;
bloodpar=par;
%
%plot results
%
if plotyes
	figure('name','Fitted blood input curve');
	clf;
	maxt=round(max(blood_ts))+1;
	Nof_dt=500;	% number of division on the fine time scale
	dt=maxt/Nof_dt;
	fine_ts=[0:dt:maxt]';
	blood_fit_as=bloodcurve(fine_ts,bloodpar);
	
	maxY=max(blood_fit_as);
	maxX=maxt;
	
	plot(fine_ts,blood_fit_as,'g-');
	hold on;
	plot(blood_ts,blood_as0,'rx');
	title(['Input and fitted blood curves']);
	xlabel('time [min]');
	ylabel('Cb(t) [nCi/ml]');
	hold off;
end
