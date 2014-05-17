function Y = mat_int(A,t1,t2)
%calculate the integral of the matrix exponential 
% DEOEC PET Center 1999 /BL

Y=zeros(size(A));
tol = []; trace = [];
for i1=1:size(A)
	for i2=1:size(A)
		Y(i1,i2) = quadl(@matexp,t1,t2,tol,trace,A,i1,i2);
	end
end
