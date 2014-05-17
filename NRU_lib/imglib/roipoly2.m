function img = roipoly2(Xaxis,Yaxis,polyX,polyY)

img = zeros(length(Yaxis),length(Xaxis));

[X,Y]=meshgrid(Xaxis,Yaxis);

% reshape X and Y to 1d vectors
xs = reshape(X,length(img(1,:))*length(img(:,1)),1);
ys = reshape(Y,length(img(1,:))*length(img(:,1)),1);

inout = inpolygon(xs,ys,polyX,polyY);

img(:)=inout(:);
