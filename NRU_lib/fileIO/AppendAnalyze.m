function [result]=AppendAnalyze(name,img,dim,siz,pre,lim,scale),
%  Appends or creates an analyze image and header file 
%
%       [result]=AppendAnalyze(name,img,dim,siz,pre,lim,scale)
%  name      - name of image file
%  img       - image data
%  dim       - x,y,z, no of pixels in each direction
%  siz       - voxel size in mm
%  pre       - precision for pictures
%  lim       - max and min limits for pixel values
%  scale     - scale is scaling of pixel values
%
%  CS, 180494
%  CS, 280100  Reading changed so routines works on both HP and Linux
%              systems
%
result=1;
FileName=sprintf('%s.img',name);
pid=fopen(FileName,'rb','ieee-be');
%pid=fopen(FileName,'rb');
if (pid ~= -1),
   fclose(pid);
   % File already exist
   [pre_old,dim_old,siz_old,lim_old,scale_old,offset_old,origin_old]=ReadAnalyzeHdr(name);
   if (length(dim) ~= 3) & dim(4) ~= 1
      fprintf('AppendAnalyze, Works only for three dimensional image sets\n');
   end; 
   if ((abs(siz_old(1)-siz(1)) > 1e-5) |...  
       (abs(siz_old(2)-siz(2)) > 1e-5) |...  
       (abs(siz_old(3)-siz(3)) > 1e-5))
      fprintf('AppendAnalyze, Problems with voxel size in added image (none correspondance)\n'); 
   end;    
   if ((pre_old == pre) &...
       (abs(dim_old(1) - dim(1)) < 1e-4) &...  
       (abs(dim_old(2) - dim(2)) < 1e-4)) 
%       (lim_old(1) == lim(1)) &... 
%       (lim_old(2) == lim(2))) 
      pid=fopen(FileName,'ab','ieee-be');
      %pid=fopen(FileName,'rb');
      if ~isreal(pre)
        if (imag(pre) ~= 32)
          error('Only 32 bit complex files available');
        else
          f=fwrite(pid,real(img),'float32');
          f=fwrite(pid,imag(img),'float32');
        end  
      elseif (pre == 8),
        fwrite(pid,img,'uint8');
      elseif (pre == 16),
        if (lim(2) < 0)
          f=fwrite(pid,img,'int16');
        else
          f=fwrite(pid,img,'uint16');
        end;
      elseif (pre == 32),
        f=fwrite(pid,img,'float32');
      else
        error('Illegal precision')
	result=0;
      end;
      fclose(pid);
      if (nargin == 6),
        dim_old(3)=dim(3)+dim_old(3);
      else
        if (abs(scale_old-scale) > 1e-6)
  	  txt=sprintf('Problems with new scale factor (%e), old scalefactor (%e)\n',...
                       scale,scale_old );
          fprintf(txt);
        end	 
        scale_old=scale;
        dim_old(3)=dim(3)+dim_old(3);
      end;            
      WriteAnalyzeHdr(name,dim_old,siz_old,pre_old,lim_old,scale_old,offset_old,origin_old);
   else
      result=0;
      fprintf('AppendAnalyze, Dimensions in existing image file and added image not corresponding\n'); 
   end;            
else
   if (nargin == 6),
      result = WriteAnalyzeImg(name,img,dim,siz,pre,lim);
   else   
      result = WriteAnalyzeImg(name,img,dim,siz,pre,lim,scale);
   end;   
end;      











