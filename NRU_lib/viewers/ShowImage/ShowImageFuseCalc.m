function [ImgFuse,OverlayLimits]=ShowImageFuseCalc(SliceNo,OrgName,OverlayName,NoOfOrgColors,...
    ImgLimitsOrg,NoOfOverlayColors)
%
if (nargin ~= 6),
   fprintf('ShowImageFuseCalc is called without argument\n');
   exit(1);
end;
%
if ((isstr(OrgName) == 0) | (isstr(OverlayName) == 0) | OrgName == [])
   ImgFuse=[];
   OverlayLimits=[];
   fprintf('ShowImageFuseCalc, No names given as input\n');
   return;
else
   % CS, 171195, Noed loesning
   ImgLimitsOrg=[ImgLimitsOrg(2) ImgLimitsOrg(1) ImgLimitsOrg(3) ImgLimitsOrg(4)];
  
   [pre,dim,siz,lim,scale,offset]=ReadAnalyzeHdr(OrgName);
   if (SliceNo > dim(3))
      fprintf('ShowImageFuseCalc, Slice no. greater than no. of slices in org. file\n');
      return
   end;   
   img=ReadAnalyzeImg(OrgName,dim,pre,lim,SliceNo);
   if (img ~= []),
      MaxPix=max(max(img));
      MinPix=min(min(img));
                   
      if (scale == 0) | (abs(scale) < 1e-10) | (abs(scale) > 1e10)
         imgOrg=(img-ImgLimitsOrg(1))*...
             (NoOfOrgColors/(ImgLimitsOrg(2)-ImgLimitsOrg(1)))+NoOfOverlayColors+1;
      else
         imgOrg=(img*scale-ImgLimitsOrg(1))*...
             (NoOfOrgColors/(ImgLimitsOrg(2)-ImgLimitsOrg(1)))+NoOfOverlayColors+1;
      end;   

      imgOverlay=zeros(size(img));
      ColonPos=strfind(OverlayName,':');
      for i=1:length(ColonPos),
	 if (i == 1)
	    Name=OverlayName(1:ColonPos(i)-1);
	 else
	    Name=OverlayName(ColonPos(i-1)+1:ColonPos(i)-1);
	 end;
         [preO,dimO,sizO,limO,scaleO,offsetO]=ReadAnalyzeHdr(Name);
	 OverlaySliceNo=round(SliceNo*siz(3)/sizO(3));
	 if (OverlaySliceNo <= dimO(3)),
            img=ReadAnalyzeImg(Name,dimO,preO,limO,OverlaySliceNo);
            if (img ~= []),
               if (scaleO == 0) | (abs(scaleO) < 1e-10) | (abs(scaleO) > 1e10)
                  imgMidl=(img-offsetO);
               else
                  imgMidl=img-offsetO*scaleO;
	       end;
	       Index=find(imgMidl>imgOverlay);
	       imgOverlay(Index)=imgMidl(Index);
	    end;   
	 else
	    fprintf('Not enough slices in image file (%s)\n',Name);
	 end;
      end;	
      MaxPix=ImgLimitsOrg(3);
      MinPix=ImgLimitsOrg(4);
      OverlayLimits=[MaxPix MinPix];
      
      if (MaxPix ~= MinPix)
         imgOverlay=(imgOverlay-MinPix)*(NoOfOverlayColors/(MaxPix-MinPix));
      else
	 imgOverlay=zeros(size(imgOverlay));
      end;	 
      imgAll=imgOrg.*(imgOverlay==0)+imgOverlay.*(imgOverlay~=0);

      ImgFuse=zeros(6*size(img));
      for i=1:6,
	 for j=1:6,
	    if (rem(i,2) == 0)
	       if (rem(j,2) == 0)
	       	  ImgFuse(i:6:size(ImgFuse,1),j:6:size(ImgFuse,2)) = imgAll;
	       else
	          ImgFuse(i:6:size(ImgFuse,1),j:6:size(ImgFuse,2)) = imgOrg;
	       end;
	    else   
	       if (rem(j,2) ~= 0)
	       	  ImgFuse(i:6:size(ImgFuse,1),j:6:size(ImgFuse,2)) = imgAll;
	       else
	          ImgFuse(i:6:size(ImgFuse,1),j:6:size(ImgFuse,2)) = imgOrg;
	       end;
	    end;  
	 end
      end;	 
     
   else
      fprintf('ShowImageFuseCalc, No image read\n');
   end;   
end;




