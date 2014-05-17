function w = hanning2(n)
%HANNING2 HANNING2(N) returns the N-point 2 dimensional Hanning window in a matrix.
%
% w = .5*(1 - cos(2*pi*(1:n)'/(n+1)))
% w=w/sum(sum(w))
%
% Can be used by conv2 to filter aa image with an Hanning vindow.
%
% Implemented, Claus Svarer, 25-8-94
%
m=-(n-1)/2:(n-1)/2;
mx=ones(n,1)*m;
my=m'*ones(1,n);
mm=sqrt(mx.^2+my.^2);
mmm=(n+1)/2-mm;
mmm=mmm.*(mmm>0);
ww = .5*(1 - cos(2*pi*mmm/(n+1)));
w = ww/sum(sum(ww));
