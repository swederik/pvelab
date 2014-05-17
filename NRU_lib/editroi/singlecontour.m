function [cx, cy, levelout] = singlecontour(img,x,y,level)

%SINGLECONTOUR
%  [cx, cy, level]=SINGLECONTOUR(img,x,y)
%    Return the contour line in an image closest to the point [x,y]
%  [cx, cy]=SINGLECONTOUR(img,x,y,level)
%    Return the contour line closest to the point [x,y] at given level

cx=[];
cy=[];

if nargin==1
  fig=figure
  imagesc(img);
  colorbar
  [x,y]=ginput(1);
end

ix=floor(x);
iy=floor(y);

rx=mod(x,1);
ry=mod(y,1);


siz=size(img);
if nargin==4
  val=level;
else
  val=img(iy,ix)*(1-rx)*(1-ry) + ...
      img(iy+1,ix)*(rx)*(1-ry) + ...
      img(iy,ix+1)*(1-rx)*(ry) + ...
      img(iy+1,ix+1)*(rx)*(ry);
end

c=contourc(img, [val val]);

n=1;
m=100;
last=Inf;
while n<size(c,2)
  len=c(2,n);
  pairs=c(:,n+1:n+len);
  xy=pairs-repmat([x;y],1,len);
  dist=sqrt(xy(1,:).^2 + xy(2,:).^2);
  m=min(dist);
  if nargin==4
    lim=min([last 30]);
  else
    lim=0.5;
  end
  if m<=lim
    cx=pairs(1,:);
    cy=pairs(2,:);  
    if nargin==1
      line(cx,cy,'Color',[0 0 0],'LineWidth',3);
    end
    last=m;
  end
  n=n+len+1;
end

if nargout==3
  levelout=val;
end
