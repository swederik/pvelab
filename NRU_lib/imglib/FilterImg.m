function []=FilterImg(nameIn,nameOut,SizX,SizY,SizZ)
%
% []=FilterImg(name)
%
%
if (nargin ~= 5)
   nameIn =input('Name of original image file            : ','s');
   nameOut=input('Name of filtered image file (output)   : ','s');
   SizX   =input('X size of filter in img units (eq. mm) : ');
   SizY   =input('Y size of filter in img units (eq. mm) : ');
   SizZ   =input('Z size of filter in img units (eq. mm) : ');
end;
%
[pre,dim,siz,lim,scale]=ReadAnalyzeHdr(nameIn);
for ii=1:dim(3),
   img=ReadAnalyzeImg(nameIn,dim,pre,lim,ii);
   eval([sprintf('img%i',ii) '=img;']);
end;
%
if ((siz(1) ~= 0) & (siz(2) ~= 0) & ...
    ((siz(3) ~= 0) | (dim(3) == 1)))
   NoOfPlanesX=ceil(SizX/siz(1));
   if (rem(NoOfPlanesX,2) == 0)
      NoOfPlanesX=NoOfPlanesX+1;
   end;   
   NoOfPlanesY=ceil(SizY/siz(2));
   if (rem(NoOfPlanesY,2) == 0)
      NoOfPlanesY=NoOfPlanesY+1;
   end; 
   if (dim(3) ~= 1)
      NoOfPlanesZ=ceil(SizZ/siz(3));
      if (rem(NoOfPlanesZ,2) == 0)
         NoOfPlanesZ=NoOfPlanesZ+1;
      end;
   else
      NoOfPlanesZ=1;
   end;
   OutArgList='[';    
   for jj=1:NoOfPlanesZ,
      OutArgList=[OutArgList sprintf('Filt%i,',jj)];
   end; 
   OutArgList(length(OutArgList))=']';
   eval([OutArgList '=hanning3(' sprintf('%i,%i,%i);',NoOfPlanesX,NoOfPlanesY,NoOfPlanesZ);]);

   for jj=1:dim(3),
      MinPlane=-(NoOfPlanesZ-1)/2;
      if (MinPlane+jj < 1) 
         MinPlane = 1-jj;
      end;   
      MaxPlane=(NoOfPlanesZ-1)/2;
      if (MaxPlane+jj > dim(3)) 
         MaxPlane = dim(3)-jj; 
      end;
      
      SumFilterKoef=0;
      img=zeros(dim(1),dim(2));
      for kk=MinPlane:MaxPlane,
         eval(['Filter=Filt' sprintf('%i;',kk+(NoOfPlanesZ+1)/2)]);
         SumFilterKoef=SumFilterKoef+sum(sum(Filter));
         eval(['ImgLoc=img' sprintf('%i;',kk+jj);]);
         img=img+conv2(ImgLoc,Filter,'same');
      end;
      img=img/SumFilterKoef;
      if (jj == 1)
         dimOut=[dim(1) dim(2) 1];
         [result]=WriteAnalyzeImg(nameOut,img,dimOut,siz,pre,lim,scale);
      else
         [result]=AppendAnalyze(nameOut,img,dimOut,siz,pre,lim,scale);
      end   
   end; 
 
else
   fprintf('FilterImg error, voxel dimension zero\n');
end;  
   
