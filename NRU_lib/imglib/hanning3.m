function [w1,w2,w3,w4,w5,w6,w7,w8,w9,w10,w11,w12,w13] = hanning2(n1,n2,n3)
%HANNING2 HANNING2(N) returns the N-point 2 dimensional Hanning window in a matrix.
%
% w = .5*(1 - cos(2*pi*(1:n)'/(n+1)))
% w=w/sum(sum(w))
%
% Can be used by conv2 to filter aa image with an Hanning vindow.
%
% Implemented, Claus Svarer, 25-8-94
%
if (nargout > 13)
   fprintf('hanning3, Too many output arguments, more than 13\n');
   return;
end
if (nargin == 2)
   n3 = n2;
   n2 = n1;
elseif (nargin ~= 3)
   fprintf('hanning3, No. of input arguments different from 2 or 3\n');
   return;
end;   
m1=(-(n1-1)/2:(n1-1)/2)/(n1+1);
m2=(-(n2-1)/2:(n2-1)/2)/(n2+1);
m3=(-(n3-1)/2:(n3-1)/2)/(n3+1);
mx=ones(n2,1)*m1;
my=m2'*ones(1,n1);
mz=m3;
msqxy=mx.^2+my.^2;
for ii=1:n3,
   mxy=sqrt(msqxy+mz(ii)^2);
   mmm=1/2-mxy;
   mmm=mmm.*(mmm>0);
   ww = .5*(1 - cos(2*pi*mmm));
   eval([sprintf('w%i',ii) '=ww;']);
end;
