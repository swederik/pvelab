function tim=tstr();
% function tim=tstr();
% 
% Returns current time in standard format.
% hh:mm:ss
tim=clock;

h=tim(4);
m=tim(5);
s=round(tim(6));

if (h<10)
  h=['0' num2str(h)];
else 
  h=[num2str(h)];
end
if (m<10)
  m=['0' num2str(m)];
else 
  m=[num2str(m)];
end
if (s<10)
  s=['0' num2str(s)];
else 
  s=[num2str(s)];
end

tim=[h ':' m ':' s];
