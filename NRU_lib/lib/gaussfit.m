%GAUSSFIT  Fit a Gaussian function to data-points using least-squares.
%   If x and y are vectors representing a function at discrete points,
%   then [A,x0,sigma]=GAUSSFIT(x,y) will determine constants such that
%   f=A*exp(-(x-x0).^2/(2*sigma^2)) is a least-squares fit to y.
%
%   If a 3rd argument is given, it specifies a tolerance for the stop
%   criteria. It should be non-negative with a default value of sqrt(eps).
%
%   The routine makes a crude direct estimate of the parameters, and then
%   refines it using Newton's method.
%
%   Warning: This routine is different from NORMFIT found in the statistics
%   toolbox. GAUSSFIT is intended to be used when a function is modelled by a
%   Gaussian. Although one could use GAUSSFIT to estimate the parameters of an
%   estimated PDF (and then ignore A), this will NOT be a correct estimate of
%   the variance. Use NORMFIT or a direct approximation instead.
%
%   Example: x=sort(100*rand(100,1)-50);
%            y=2*exp(-(x-12).^2/(2*5^2))+randn(100,1)*0.2;
%            [A,x0,sigma]=gaussfit(x,y)

%   Author: Esben Høgh-Rasmussen
%   Date: 07.08.2002
function [A,x0,sigma]=gaussfit(x,y,tol)
  %
  % Normalize arguments.
  %
  if nargin<3, tol=sqrt(eps); end               % Default tolerance
  if nargin<2
    y=x;
    x=1:length(y);
  end
  x=x(:);
  y=y(:);
  %
  % Make initial approximation.
  %
  x0=sum(x.*y)/sum(y);                          % Estimate mean value
  xx=(x-x0).*(x-x0);
  ss=sum(xx.*abs(y))/sum(abs(y));               % Estimate mean variance
  sigma=sqrt(ss);
  f=exp(-xx/(2*ss));
  A=(f'*y)/(f'*f);                              % Estimate amplitude
  %
  % Run Newton.
  %
  dif=y-A*f;                                    % Error vector
  E=dif'*dif; Emin=E;                           % Error-squared
  Pmin=[A x0 sigma];                            % Store best parameters so far
  div=0;                                        % Divergence steps
  for iter=1:300
    %
    % Construct the Jacobian.
    %
    sss=sigma*sigma*sigma;
    J=[f (A/ss)*(x-x0).*f (A/sss).*xx.*f];
    %
    % Update parameters, except A that can
    % be solved for.
    %      
    D=(J'*J)\(J'*dif);
    x0=x0+D(2);
    sigma=abs(sigma+D(3));
    %
    % Compute new errors and stop when it diverges.
    %
    xx=(x-x0).*(x-x0);
    ss=sigma*sigma;                             % Variance
    f=exp(-xx/(2*ss));
    A=(f'*y)/(f'*f);                            % Optimal A
    dif=y-A*f;                                  % Error vector
    E=dif'*dif;                                 % Error-squared
    if Emin-E>Emin*tol                          % Any significant improvement?
      div=0;                                    %   Yes; reset divergence counter
    else
      div=div+1;                                %   No; note an insignificant step
    end
    if E<Emin                                   % Save the best set of parameters
      Emin=E;
      Pmin=[A x0 sigma];
    end
    if div>3, break, end                        % Stop when we have no significant improvements
  end
  %
  % Return best set.
  %
  A=Pmin(1);
  x0=Pmin(2);
  sigma=Pmin(3);
