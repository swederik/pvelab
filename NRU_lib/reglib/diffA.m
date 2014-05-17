function R=diffA(V)
%
% Specificer en stiv rotor ud fra de tre vinkler.
% 
v1=V(1);
v2=V(2);
v3=V(3);
%
R=zeros(4,4);
R(1,1)=cos(v3)*cos(v2)+sin(v3)*sin(v1)*sin(v2);
R(1,2)=sin(v3)*cos(v2)-cos(v3)*sin(v1)*sin(v2);
R(1,3)=cos(v1)*sin(v2);
R(2,1)=-sin(v3)*cos(v1);
R(2,2)=cos(v3)*cos(v1);
R(2,3)=sin(v1);
R(3,1)=sin(v3)*sin(v1)*cos(v2)-cos(v3)*sin(v2);
R(3,2)=-cos(v3)*sin(v1)*cos(v2)-sin(v3)*sin(v2);
R(3,3)=cos(v1)*cos(v2);
R(4,4)=1;
