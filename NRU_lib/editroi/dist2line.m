function dist=dist2line(lx,ly,px,py)

if lx(1)==lx(2)
  tmp=lx;
  lx=ly;
  ly=tmp;
  tmp=px;
  px=py;
  py=tmp;
end

if lx(1)==lx(2)
  dist=Inf;
  return;
end

a=(ly(1)-ly(2))/(lx(1)-lx(2));
b=ly(1)-lx(1)*a;

%x=(px/a+py-b)/(a+1/a)
%y=(px-x)/a+py


dist=abs(sqrt(a^2+1)*(px*a+b-py)/(a^2+1));
