function [errorres,g] = fitblood(p)
%function error = fitblood(p)
% fitting procedure for calulating A1..A3, labda1..labda2,tau 

global  blood_as blood_ts bloodpar

g = -p(3);
bloodpar=p;

blood_fit_as = bloodcurve(blood_ts,bloodpar);
%range=[3:length(blood_fit_as)];
%error=sum( ((blood_fit_as(range)-blood_as(range)).^2) ./ blood_as(range) );
errorres = norm(blood_fit_as-blood_as);


