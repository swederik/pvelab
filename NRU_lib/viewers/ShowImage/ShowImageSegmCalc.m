function []=ShowImageSegmCalc(Inp)
%
if (nargin ~= 1),
   fprintf('ShowImageSegmCalc is called without argument\n');
   exit(1);
end;
%
if (Inp == 0),
  set(gcf,'Pointer','crosshair')
  set(gcf,'WindowButtonDownFcn','ShowImageSegmCalc(1)');   % Calculate area
  
elseif (Inp == 1),

   if (strcmp(get(gco,'Type'),'image') == 1)
   
      tmp=get(gca,'CurrentPoint');
      x=tmp(1,1);
      y=tmp(1,2);
      
      img=get(gco,'CData');
      MinMaxLim=get(gco,'UserData');
      img_bw=im2bw(img,eps);
      
      set(gcf,'Pointer','watch');
      
      if (img_bw(y,x) == 1)
         bw_perim=bwperim(img_bw);
         bw_morph=bwmorph(bw_perim,'fill');
         bw_roi=ShowImageRoiFill(bw_morph,[y,x]);
%figure(3),image(bw_perim*64),colormap(gray(64)),axis('image')
%figure(4),image(bw_morph*64),colormap(gray(64)),axis('image')
%figure(5),image(bw_roi*64),colormap(gray(64)),axis('image')
%figure(2)
         IndexRoi=find(bw_roi==1);
         RoiData=img(IndexRoi);
         
         Name=get(gcf,'Name');
         [pre,dim,siz,lim,scale,offset]=ReadAnalyzeHdr(Name);
         h=get(gcf,'UserData');
         SlideNo=get(h(1),'Value');       % Slide no
         ThresLevel=get(h(5),'Value');    % Threshold level
         
         MeanRoi=mean(RoiData);
         StdRoi=std(RoiData);
         NoOfPixels=length(RoiData);
         AreaOfRoi=NoOfPixels*siz(1)*siz(2);
         fprintf('ROI Data:\n');
         fprintf('   Image name                  : %s\n',Name);
         fprintf('   Slide no                    : %i\n',SlideNo);
         fprintf('   Threshold level             : %6.2f%%, %e\n',...
                   ThresLevel,ThresLevel/100*MinMaxLim(2));
         fprintf('   No of pixels in ROI         : %i\n',NoOfPixels);
         fprintf('   Area of ROI                 : %e\n',AreaOfRoi);
         fprintf('   Mean value of pixels in ROI : %e\n',MeanRoi);
         fprintf('   Std dev of pixels in ROI    : %e\n',StdRoi);
         
         StatFileName = get(h(6),'UserData');
         if (length(StatFileName) ~= 0)
            pid=fopen(StatFileName,'a');
            if (pid ~= -1)
               fprintf(pid,'ROI Data:\n');
               fprintf(pid,'   Image name                  : %s\n',Name);
               fprintf(pid,'   Slide no                    : %i\n',SlideNo);
               fprintf(pid,'   Threshold level             : %6.2f%%, %e\n',...
                        ThresLevel,ThresLevel/100*MinMaxLim(2));
               fprintf(pid,'   No of pixels in ROI         : %i\n',NoOfPixels);
               fprintf(pid,'   Area of ROI                 : %e\n',AreaOfRoi);
               fprintf(pid,'   Mean value of pixels in ROI : %e\n',MeanRoi);
               fprintf(pid,'   Std dev of pixels in ROI    : %e\n',StdRoi);
               fclose(pid);
            else
               fprintf('Did not succeed in logging data to file\n');
            end;
         end;

         img_new=img.*(1-bw_roi)+bw_roi*MinMaxLim(2);
         set(gco,'CData',img_new);
         
      else
         fprintf('Starting point out of region\n');
      end;      
      
      set(gcf,'Pointer','crosshair');
   else
      fprintf('Not pointed on region within image\n');
   end
end;     
