%RIGTRANS  Rigid transform from a set of 3D-points to another.
%   A=RIGTRANS(x,y) determines the best rigid transform from a set of points
%   in 3D to another. There must be at least 3 points.
%
%   Arguments:
%     x = [ x1 x2 ... xn    y= [ X1 X2 ... Xn
%           y1 y2 ... yn         Y1 Y2 ... Yn
%           z1 z2 ... zn ]       Z1 Z2 ... Zn ]
%
%   The cost function minimized is the sum of squared distances between
%   the transformed input points and the given output points. The matrix A is
%   the 4-by-4 matrix that transforms the points in homogenic coordinates.
%
%   [A,V]=RIGTRANS(x,y) also returns the transform as a set of 3 Euler
%   rotations followed by a translation:
%
%     V(3): Yaw (rotation about z-axis)
%     V(1): Pitch (rotation about x-axis)
%     V(2): Roll (rotation about y-axis)
%
%   Pitch and yaw are returned as the negative of the standard convention, in
%   order to be consistent with Roger Woods notation. The remaining elements are
%   the translation in the x-, y- and z-direction.
function [A,V]=rigtrans(x,y)
  n=size(x,2);                                          % Get number of points
  cx=mean(x,2); x=x-repmat(cx,1,n);                     % Remove centroids
  cy=mean(y,2); y=y-repmat(cy,1,n);
  
  %
  % Construct the matrix N, and determine the
  % quaternion representing the rotation.
  %
  x1=x(1,:)'; y1=x(2,:)'; z1=x(3,:)';
  x2=y(1,:)'; y2=y(2,:)'; z2=y(3,:)';
  M=[x1 y1 z1]'*[x2 y2 z2];
  Mt=trace(M);
  D=[M(2,3)-M(3,2) ; M(3,1)-M(1,3) ; M(1,2)-M(2,1)];
  N=[Mt D' ; D M+M'-Mt*eye(3)];
  [Q,lambda]=eig(N);
  [dummy,inx]=max(diag(lambda));
  q=Q(:,inx);

  %
  % Convert the quaternion into the coresponding rotation matrix.
  %
  xx=2*q(2)*q(2); xy=2*q(2)*q(3); xz=2*q(2)*q(4);
  yy=2*q(3)*q(3); yz=2*q(3)*q(4);
  zz=2*q(4)*q(4);
  wx=2*q(1)*q(2); wy=2*q(1)*q(3); wz=2*q(1)*q(4);
  Rot=[1-yy-zz   xy-wz    xz+wy                         % Form the rotation matrix
        xy+wz   1-xx-zz   yz-wx
        xz-wy    yz+wx   1-xx-yy];

  A=[Rot     cy ; [0 0 0] 1]*...                        % Form the full transformation matrix
    [eye(3) -cx ; [0 0 0] 1];

  %
  % Factor transform matrix into rotations (yaw-pitch-roll) followed by
  % a translation. Note that the definition used is rather absurd, so we
  % have to change signs for some of the angles.
  %
  if nargout>=2
    ang=A2Euler(A,5);
    V=[ang.*[-1 1 -1] A(1:3,4)'];
  end


%
% Convert a rotation matrix to Euler angles:
%
% Order:  1   X Y Z       4   Y Z X
%         2   X Z Y       5   Z X Y
%         3   Y X Z       6   Z Y X
%
% References:
%   [1] "Euler Angle Conversion"
%       by Ken Shoemake, shoemake@graphics.cis.upenn.edu
%       "Graphics Gems IV", Academic Press, 1994
%
function ang=A2Euler(A,order)
  t=[1 1 2 2 3 3]; i=t(order);
  t=[2 3 1 3 1 2]; j=t(order);
  t=[3 2 3 1 2 1]; k=t(order);
  cy=sqrt(A(i,i)*A(i,i)+A(j,i)*A(j,i));
  if cy>16*eps
    alpha = atan2( A(k,j), A(k,k));
    beta  = atan2(-A(k,i), cy);
    gamma = atan2( A(j,i), A(i,i));
  else
    alpha = atan2(-A(j,k), A(j,j));
    beta  = atan2(-A(k,i), cy);
    gamma = 0;
  end
  ang(i)=alpha; ang(j)=beta; ang(k)=gamma;
  t=[1 -1 -1 1 1 -1];
  if t(order)<0, ang=-ang; end

%
% If one wants to make a rotation matrix from Euler angles,
% the following could be used.
%
%function A=Euler2A(v,order)
%  if nargin<2, order=1; end
%  Rx=eye(3); Ry=eye(3); Rz=eye(3);
%  Rx([2 3],[2 3])=[cos(v(1)) -sin(v(1)) ;  sin(v(1)) cos(v(1))];
%  Ry([1 3],[1 3])=[cos(v(2))  sin(v(2)) ; -sin(v(2)) cos(v(2))];
%  Rz([1 2],[1 2])=[cos(v(3)) -sin(v(3)) ;  sin(v(3)) cos(v(3))];
%  switch order
%    case 1, A=Rz*Ry*Rx;
%    case 2, A=Ry*Rz*Rx;
%    case 3, A=Rz*Rx*Ry;
%    case 4, A=Rx*Rz*Ry;
%    case 5, A=Ry*Rx*Rz;
%    case 6, A=Rx*Ry*Rz;
%    otherwise, error('Illegal axis order.');
%  end



