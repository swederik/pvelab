function blood_act_values = bloodcurve(t,bloodpar)
% function blood_act_values = bloodcurve(t) 
% calculating a blood crve based on the model of ....
%

%global bloodpar;

p=bloodpar;
vector_rank = 0;
if size(t,1) == 1
	t=t';
	vector_rank = 1;
end 

t=t-p(7);
t1=t(find(t <= 0));
blood_act_values1=zeros(size(t1));

t2=t(find(t > 0));
tag1a=p(1)*t2-p(2)-p(3);
tag1b=exp(p(4)*t2);
tag2=p(2)*exp(p(5)*t2);
tag3= p(3)*exp(p(6)*t2);

blood_act_values2 = tag1a.*tag1b+tag2+tag3;
bv = [blood_act_values1',blood_act_values2']';
if vector_rank == 0 
	blood_act_values=bv;
else 
	blood_act_values=bv';
end