function [P,r] = PETsimRadon(I,theta,n)

[P,r_def]=radon( I,theta );

 r = linspace(min(r_def), max(r_def), n)';
 
 P = interp1(r_def(:), P, r(:), '*linear');

 
% P = P .*( (r_def(2)-r_def(1)) / (r(2)-r(1)) );

P = P .*(  n/length(r_def) );

