function y = fractile(x,p);
%FRACTILE gives the percentiles of the sample in X.
%   Y = FRACTILE(X,P) returns a value that is greater than P percent
%   of the values in X. For example, if P = 50  Y is the median of X. 

[prows pcols] = size(p);
if prows ~= 1 & pcols ~= 1
    error('P must be a scalar or a vector.');
end
if any(p > 100) | any(p < 0)
    error('P must take values between 0 and 100');
end

if (~any(isnan(x)))
   y = prctilecol(x,p);
else                    % if there are NaNs, process each column
   if (size(x,1) == 1)
      x = x';
   end
   c = size(x,2);
   np = length(p);
   y = zeros(np,c);
   for j=1:c
      xx = x(:,j);
      xx = xx(~isnan(xx));
      y(:,j) = prctilecol(xx,p)';
   end
   if (min(size(x)) == 1)
      y = y';
   end
end

return
      
function y = prctilecol(x,p);
xx = sort(x);
[m,n] = size(x);

if m==1 | n==1
    m = max(m,n);
	if m == 1,
	   y = x*ones(length(p),1);
	   return;
	end
    n = 1;
    q = 100*(0.5:m - 0.5)./m;
    xx = [min(x); xx(:); max(x)];
else
    q = 100*(0.5:m - 0.5)./m;
    xx = [min(x); xx; max(x)];
end

q = [0 q 100];
y = interp1(q,xx,p);
