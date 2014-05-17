function [data_out, mode_out, level_out] = singlecontour(img,arg2, arg3)

%MULTICONTOUR
%  [c, mode, level]=MULTICONTOUR(img,x,y)
%    Return the all contour lines in an image.
%    Level chosen at the point [x,y]
%  [c, mode]=MILTICONTOUR(img,level)
%    Return the all contour lines in an image at given level.
%  c is a cell array containing the x and y data for contours. Data are sorted 
%    with largest area first.
%  mode is an array with ones for contour lines that sourrounds data with 
%    higher level.

cx=[];
cy=[];

i2=zeros(size(img)+2);
i2(2:end-1,2:end-1)=img;
img=i2;
clear i2;

if nargin==1
  fig=figure
  imagesc(img);
  colormap(gray);
  colorbar
  [x,y]=ginput(1);
end

siz=size(img);

if nargin==2
  val=arg2;
else
  x=arg2;
  y=arg3;
  if x<1 | x>siz(2)
    error('x must be within range if image');
  end
  if y<1 | y>siz(1)
    error('y must be within range if image');
  end
  ix=floor(x);
  iy=floor(y);

  rx=mod(x,1);
  ry=mod(y,1);
  val=img(iy,ix)*(1-rx)*(1-ry) + ...
      img(iy+1,ix)*(rx)*(1-ry) + ...
      img(iy,ix+1)*(1-rx)*(ry) + ...
      img(iy+1,ix+1)*(rx)*(ry);
end

c=contours(img, [val val]);
data={};
mode=[];
lev=[];
ar=[];
an=[];
n=1;
ncurve=0;
while n<size(c,2)
  ncurve=ncurve+1;;
  len=c(2,n);
  lev=[lev; c(1,n)];
  pairs=c(:,n+1:n+len);
   
  xp=pairs(1,:);
  yp=pairs(2,:);
  Area=sum( diff(xp).*(yp(1:len-1)+yp(2:len))/2 );

  ar=[ar; Area];
  pairs=pairs-1;
  pairs(find(pairs<0.5))=0.5;
  pairs(1,find(pairs(1,:)>siz(2)+0.5))=siz(2)+0.5;
  pairs(2,find(pairs(2,:)>siz(1)+0.5))=siz(1)+0.5;
  data{ncurve,1}=pairs;
  n=n+len+1;
end

% sort areas with largest first 
[dummy i]=sort(-abs(ar));
ar=ar(i);
data=data(i);
mode=ar>0;

if nargout==2
  levelout=val;
end

if nargin==1 | nargout==0
  for n=1:size(data,1)
    d=data{n,1}+1;
    if ~isempty(d)
      h=line(d(1,:), d(2,:));
      if mode(n,1)
        set(h,'Color',[0 1 0]);
      else
        set(h,'Color',[1 0 0]);
      end
    end
  end
end

if nargout>=1
  data_out=data;
end

if nargout>=2
  mode_out=mode;
end

if nargout>=3
  level_out=val;
end
