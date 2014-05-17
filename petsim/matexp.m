function Y= matexp(t,A,i1,i2)
%calculate the matrix exponent of A
% DEOEC PET Center 1999 /BL

size_t=size(t);
Y=zeros(size(t));

for j=1:size_t(2)
	Z = expm(A*t(j));
	Y(j) = Z(i1,i2);
end
