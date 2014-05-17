function Rois=CutVoi(VOI,n,p);
% function Rois=CutVoi(VOI,n,p);
% 
% Cut a VOI with a planes defined by normal 
% n and points p (acutally p*n)
%
% See also Roi2Voi, Voi2Roi, RotVoi
%  

% reshape n and p:
  n=reshape(n,3,1);
  p=reshape(p,1,length(p));
  
% Loop over each VOI region:
  Rois.Contours=[];
  Rois.RegionType=[];
  for j=1:length(VOI.FV)
    if not(isempty(VOI.FV{j}))
      FV=VOI.FV{j};
      FV.vertices=FV.vertices+0.01*randn(size(FV.vertices));
      % Which vertices are over, under or on each of the planes?
      sgn=planeq(FV.vertices,n,p);
      % for each plane...
      laststr=[];
      for k=1:length(p)
	str=sprintf('%s%i%s%i%s%i','Processing region ',j,' - plane ',k,' of ',length(p));
	fprintf([repmat(8,1,length(laststr)) str]);
	laststr=str;
	Sgn=sgn(:,k);
	f1=FV.faces(:,1);
	f2=FV.faces(:,2);
	f3=FV.faces(:,3);
	Under=Sgn(f1)==-1 & Sgn(f2)==-1 & Sgn(f3)==-1;
	Over=Sgn(f1)==1 & Sgn(f2)==1 & Sgn(f3)==1;
	Contour=not(Under)&not(Over);
	ContourFaces=[f1(Contour) f2(Contour) f3(Contour)];
	if not(isempty(ContourFaces))
	  Cf1=ContourFaces(:,1);
	  Cf2=ContourFaces(:,2);
	  Cf3=ContourFaces(:,3);
	  	  
	  % Which of the Contour faces have two vertices over plane?
	  Over2=(Sgn(Cf1)==1 & Sgn(Cf2)==1 & Sgn(Cf3)==-1) | ...
		(Sgn(Cf1)==1 & Sgn(Cf3)==1 & Sgn(Cf2)==-1) | ...
		(Sgn(Cf3)==1 & Sgn(Cf2)==1 & Sgn(Cf1)==-1);
	  % Which of the Contour faces have two vertices under?
	  Under2=(Sgn(Cf1)==-1 & Sgn(Cf2)==-1 & Sgn(Cf3)==1) | ...
		 (Sgn(Cf1)==-1 & Sgn(Cf3)==-1 & Sgn(Cf2)==1) | ...
		 (Sgn(Cf3)==-1 & Sgn(Cf2)==-1 & Sgn(Cf1)==1);
	  % Which of the Contour faces have vertices
	  % on the plane?
	  On2=(Sgn(Cf1)==0 | Sgn(Cf2)==0 | Sgn(Cf3)==0) & not(Sgn(Cf1)==0 & Sgn(Cf2)==0 & Sgn(Cf3)==0);
	  F2Over=[Cf1(Over2) Cf2(Over2) Cf3(Over2)];
	  F2Under=[Cf1(Under2) Cf2(Under2) Cf3(Under2)];
	  FOn=[Cf1(On2) Cf2(On2) Cf3(On2)];
	  On1=(Sgn(Cf1)==0 & not(Sgn(Cf2)==0) & not(Sgn(Cf3)==0)) | ...
	      (not(Sgn(Cf1)==0) & Sgn(Cf2)==0 & not(Sgn(Cf3)==0)) | ...
	      (not(Sgn(Cf1)==0) & not(Sgn(Cf2)==0) & Sgn(Cf3)==0);
	  idx=not(On2) & not(Over2) & not(Under2) & not(On1);
	  
	  Cf1(idx)=[];
	  Cf2(idx)=[];
	  Cf3(idx)=[];
	  
	  % Pick a triangle
	  %figure
	  %P=patch('vertices',FV.vertices,'Faces',[Cf1 Cf2 Cf3],'edgecolor','yellow','facecolor','black');
          Cface=[Cf1 Cf2 Cf3];
          %Cface=unique(Cface,'rows');
	  Cf1=Cface(:,1);
	  Cf2=Cface(:,2);
	  Cf3=Cface(:,3);
	  Xes=cell(length(Cf1),3);
	  Lines=zeros(length(Cf1),3);
	  for jj=1:length(Cf1)
	    for kk=1:3
	      if kk==1
		c1=FV.vertices(Cface(jj,1),:);
		c2=FV.vertices(Cface(jj,2),:);
	      elseif kk==2
		c1=FV.vertices(Cface(jj,1),:);
		c2=FV.vertices(Cface(jj,3),:);
	      elseif kk==3
		c1=FV.vertices(Cface(jj,2),:);
		c2=FV.vertices(Cface(jj,3),:);
	      end
	      [x,t]=lpc(n,p(k)*n,c1,c2);
	      if isnan(t)
		Xes{jj,kk}=[Xes{jj,kk};c1;c2];
		Lines(jj,kk)=1;
	      else
		Xes{jj,kk}=[Xes{jj,kk};x];
		if not(isempty(x))
		  Lines(jj,kk)=1;
		end
	      end
	    end
	  end
	  Remove=zeros(size(Cf1));
	  for jj=1:length(Cf1)
	    for kk=1:3
	      if size(Xes{jj,kk},1)==2
		Lines(jj,:)=[1 1 1];
		Lines(jj,kk)=0;
		Xes{jj,kk}=[];
	      end
	    end
	    Idx=find(Lines(jj,:)==1);
	    %for kk=1:3
	    %  if Lines(kk)==1
	    %	Idx=[Idx;kk];
	    %      end
	    %    end
	    X=[];
	    for kk=1:length(Idx)
	      X=[X;Xes{jj,Idx(kk)}];
	    end
	    X=unique(X,'rows');
	    if size(X,1)==1
	      Remove(jj)=1;
	    end
	  end
	  Stop=0;
	  Stop0=0;
	  idx=1;
	  % Find neighbouring triangles:
	  taken=zeros(size(Cf1));
	  taken(idx)=1;
	  NumContours=1;
	  clear Contours;
	  kk=1;
	  Stop=0;
	  Found=0;
	  Contours{NumContours}=[];
	  for kk=1:3
	    Contours{NumContours}=[Contours{NumContours};Xes{idx,kk}];
	    if Lines(idx,kk)==1
	      ThisLine=kk;
	    end
	  end
	  
	  while not(Stop0==1);
	    while not(Stop==1)
	      if ThisLine==1
		v1=Cface(idx,1);
		v2=Cface(idx,2);
	      elseif ThisLine==2
		v1=Cface(idx,1);
		v2=Cface(idx,3);
	      elseif ThisLine==3
		v1=Cface(idx,2);
		v2=Cface(idx,3);
	      end
	      oldidx=idx;
	      OldThisLine=ThisLine;
	      NumFace=[1:size(Cface,1)]';
	      NumFace=NumFace(taken==0);
	      CfaceRest=Cface(NumFace,:);
	      %[idx,ThisLine]=FindBuddy(v1,v2,CfaceRest,taken);
	      [idx,ThisLine]=FindBuddy(v1,v2,CfaceRest);
	      idx=NumFace(idx);
	      if isempty(idx)
		%keyboard
		Stop=1;
	      elseif not(length(idx)==1)
		error('More than one match returned...')
	      else
		taken(idx)=1;
		for kk=1:3
		  if Lines(idx,kk)==1 & not(kk==ThisLine)
		    N=size(Contours{NumContours},1);
		    Point=Contours{NumContours}(N,:);
		    NewPoint=Xes{idx,kk};
		    if not(all(Point==NewPoint))
		      Contours{NumContours}=[Contours{NumContours}; Xes{idx,kk}];
		    end
		    ThisLineNew=kk;
		  end
		end
		ThisLine=ThisLineNew;
	      end
	    end
	    if all(taken==1)
	      Stop0=1;
	    elseif Stop==1
	      NumContours=NumContours+1;
	      Contours{NumContours}=[];
	      idx=find(not(taken==1));
	      idx=idx(1);
	      taken(idx)=1;
	      for kk=1:3
		if not(Lines(idx,kk)==0)
		  Contours{NumContours}=[Contours{NumContours}; Xes{idx,kk}];
		  ThisLine=kk;
		end
	      end
	      if isempty(Contours{NumContours})
		keyboard
	      end
	      Stop=0;
	    end
	  end
 	  hold on
	  if exist('Contours')==1 & not(isempty(Contours))
	    SNR=length(Contours);
	    for jjj=1:SNR
	      if not(isempty(Contours{jjj}))
		Rois.Contours{1+length(Rois.Contours)}=Contours{jjj};
		Rois.RegionType{1+length(Rois.RegionType)}=j;
	      end
	    end
	  else
	    clear Contours;
	  end
	end
      end
      fprintf('\n');
    end
  end
  
function [idx1,ThisLine]=FindBuddy(v1,v2,Cface)
  idx1=zeros(size(Cface,1));
  ThisLine=zeros(size(Cface,1));
  if not(isempty(idx1))
    Match=(Cface==v1)+(Cface==v2);
    NumFace=[1:size(Cface,1)];
    match=sum(Match,2)==2;
    idx1(match)=NumFace(match);
    line1=Match*[1 1 0]';
    line2=Match*[1 0 1]';
    line3=Match*[0 1 1]';
    match=line1==2;
    ThisLine(match)=1;
    match=line2==2;
    ThisLine(match)=2;
    match=line3==2;
    ThisLine(match)=3;
    idx1(idx1==0)=[];
    ThisLine(ThisLine==0)=[];
  end

  
  
function sgn=planeq(xyz,n,p)  
% Find out if each point is over, under or on the plane
  vsize=size(xyz);
  psize=size(p);
  p=n*p;
  sgn=zeros(vsize(1),psize(2));
  for j=1:psize(2);
    sgn(:,j)=n(1)*(xyz(:,1)-p(1,j))+n(2)*(xyz(:,2)-p(2,j))+n(3)*(xyz(:,3)-p(3,j));
  end
  sgn=sign(sgn);

function sgn=planeq2(xyz,n,p)  
% Find out if each point is over, under or on the plane
  vsize=size(xyz);
  psize=size(p);
  %p=n*p;
  sgn=zeros(vsize(1),psize(2));
  for j=1:psize(2);
    sgn(:,j)=n(1)*(xyz(:,1)-p(1,j))+n(2)*(xyz(:,2)-p(2,j))+n(3)*(xyz(:,3)-p(3,j));
  end
  sgn=sign(sgn);
  
   
  
  
function [x,t]=lpc(n,p,c1,c2)
% function x=lpc(n,p,c1,c2)
% Calculate coordinate set(s) of croosing
% point of line with plane
  
% vector of line direction:
  r=c2-c1;
  
  a=-[c1(:,1)-p(1) c1(:,2)-p(2) c1(:,3)-p(3)];
  
  sc=size(c1);
  x=zeros(sc);
  t=zeros(sc(1),1);
  s=size(a);
  for j=1:s(1)
    if dot(r(j,:),n)==0 % if r | n return first coordinate set
      if planeq2(c1,n,p)==0  
	x(j,:)=c1(j,:);
	t(j)=NaN;
      else
	t(j)=inf;
	x(j,:)=[];
      end
    else
      t(j)=(dot(a(j,:),n)/dot(r(j,:),n));
      x(j,:)=t(j)*r(j,:)+c1(j,:);
      if t<0 | t>1
	x(j,:)=[];
      end
    end
  end
  
function x=GetCrossing(vertices,face,n,p)
% Return Crossing point(s) of triangle and plane
  
  % Vertices:
  xyz1=vertices(face(1),:);
  xyz2=vertices(face(2),:);
  xyz3=vertices(face(3),:);
  
  x=[];
  
  [xx1,t1]=lpc(n,n*p,xyz1,xyz2);
  if (0<=t1) & (t1<=1)
    x=[x;xx1];
  elseif isnan(t1)
    x=[x;xyz1;xyz2];
  end
  [xx2,t2]=lpc(n,n*p,xyz1,xyz3);
  if (0<=t2) & (t2<=1)
    x=[x;xx2];
  elseif isnan(t2)
    x=[x;xyz1;xyz3];
  end
  [xx3,t3]=lpc(n,n*p,xyz2,xyz3);
  if (0<=t3) & (t3<=1)
    x=[x;xx3];
  elseif isnan(t3)
    x=[x;xyz2;xyz3];
  end
  s=size(x);
  
  Keep=ones(s(1),1);
  for j=1:s(1)
    for k=1:s(1)
      if not(k==j)
	if MatchCoord(x(j,:),x(k,:))==1
	  Keep(j)=0;
	end
      end
    end
  end
  x1=x(:,1);
  x2=x(:,2);
  x3=x(:,3);
  x1(Keep==0)=[];
  x2(Keep==0)=[];
  x3(Keep==0)=[];
  x=[x1 x2 x3];
  x=unique(x,'rows');
  s=size(x);
  if s(1)>2
    disp('More than 2 cuts!')
    keyboard
  end
  
function bool=MatchCoord(x1,x2);
  bool=(sqrt(sum((x1-x2).^2)))==0;%<1e-6;
  

  