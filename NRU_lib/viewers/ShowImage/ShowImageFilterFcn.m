function []=ShowImageFilterFcn(Inp,arg2),
%
if (nargin == 0),
else
   % Generate IMAGE with ROI
   h=get(gca,'Children');
   h_image = -1;
   for ii = 1:length(h)
      if (strcmp(get(h(ii),'Type'),'image') == 1)
         h_image = h(ii);
      end;
   end;
   if (h_image ~= -1),
      if (Inp == 1) | (Inp == 2), 
         % Hanning or Gauss window used
         if (arg2 == 0)
            % Selected filter size
            h=get(gcf,'Children');
            h_filt=-1;
            for ii=1:length(h),
               if (isstr(get(h(ii),'UserData')) == 1) &...
		     (strcmp(get(h(ii),'UserData'),'h_SizeFilter') == 1),
                  h_filt = h(ii);
               end;
            end;
            if (h_filt ~= -1)
               Txt=get(h_filt,'String');
               delete(h_filt);
               arg2=str2num(Txt);
            end;
         end;
         if (isstr(arg2) == 0),
            ImageName=get(gcf,'Name');
            [pre,dim,siz,lim,scale]=ReadAnalyzeHdr(ImageName) ;
            
            if (siz(1) ~= 0) & (siz(2) ~= 0),
               if (Inp == 1)
                  w=hanning2D(arg2,siz(1),arg2,siz(2));
               elseif (Inp == 2)
                  w=gauss2D(arg2,siz(1),arg2,siz(2),0.05);
               end;   
               w=w/sum(sum(w));
               CData=get(h_image,'CData');
               NewCData=conv2(CData,w,'same');
               set(h_image,'CData',NewCData);
               
               % Set filter type and size in UserData for Filter all images in file
               h=get(gcf,'UserData');
               h_Filter=-1;
               for i=1:length(h)
                  if (strcmp(get(h(i),'Type'),'uimenu') == 1)
                     if (strcmp(get(h(i),'Label'),'Filter') == 1)
                        h_Filter=h(i);
                     end;
                  end;   
               end;
               if (h_Filter ~= -1)      
                  h=get(h_Filter,'Children');
                  h_FilterImg=-1;
                  for i=1:length(h)
                     if (strcmp(get(h(i),'Label'),'Filter all') == 1)
                        h_FilterImg=h(i);
                     end;
                  end;
                  if (h_FilterImg ~= -1),
                     if (Inp == 1)
                        FilterDef=sprintf('hanning,%i',arg2);
                     elseif (Inp == 2)
                        FilterDef=sprintf('gauss,%i',arg2);
                     end;
                     set(h_FilterImg,'UserData',FilterDef);
                  else
                     fprintf('Filter can not be used for filtering all images in image file\n');   
                  end;
               else
                  fprintf('Filter can not be used for filtering all images in image file\n');   
               end;         
            else
               fprintf('Image pixel size equal to 0\n');
            end;   
         else
            fprintf('Tried to filter image with filter size uncorrect\n');
         end;   
      elseif (Inp == 3)
         % Filter all images in image file
         ImageName=get(gcf,'Name');
         if (strcmp(ImageName,'') == 0)

            % Get filter type and size in UserData for Filter all images in file
            h=get(gcf,'UserData');
            h_Filter=-1;
            for i=1:length(h)
               if (strcmp(get(h(i),'Type'),'uimenu') == 1)
                  if (strcmp(get(h(i),'Label'),'Filter') == 1)
                     h_Filter=h(i);
                  end;
               end;   
            end;
            if (h_Filter ~= -1)      
               h=get(h_Filter,'Children');
               h_FilterImg=-1;
               for i=1:length(h)
                  if (strcmp(get(h(i),'Label'),'Filter all') == 1)
                     h_FilterImg=h(i);
                  end;
               end;
               if (h_FilterImg ~= -1) 
                  FilterDef=get(h_FilterImg,'UserData');
                  PointPos=strfind(FilterDef,',');
                  
                  FilterName=FilterDef(1:PointPos-1);
                  FilterSize=str2num(FilterDef(PointPos+1:length(FilterDef)));

                  [pre,dim,siz,lim,scale]=ReadAnalyzeHdr(ImageName);
                  NewImageName=sprintf('%s_%s%i',ImageName,FilterName,FilterSize);

                  set(gcf,'Pointer','watch')

                  if (strcmp(FilterName,'hanning') == 1)
                     w=hanning2D(FilterSize,siz(1),FilterSize,siz(2));
                  elseif (strcmp(FilterName,'gauss') == 1)   
                     w=gauss2D(FilterSize,siz(1),FilterSize,siz(2),0.05);
                  end;
                  w=w/sum(sum(w));   

                  for ii=1:dim(3),
                     img=ReadAnalyzeImg(ImageName,dim,pre,lim,ii);
                     NewImg=conv2(img,w,'same');
                     if ii==1
                        NewDim=[dim(1) dim(2) 1];
                        [result]=WriteAnalyzeImg(NewImageName,NewImg,NewDim,siz,pre,lim,scale);
                     else
                        [result]=AppendAnalyze(NewImageName,NewImg,NewDim,siz,pre,lim,scale);
                     end;
                  end;
                  set(gcf,'Pointer','arrow')
               else
                  fprintf('Filter can not be used for filtering all images in image file\n');   
               end;
            else
               fprintf('Filter can not be used for filtering all images in image file\n');   
            end;         

         else
            fprintf('No image file choosen for filtering\n');
         end;   
         
      else
         fprintf('Inp undefined\n');
      end;
   else
      fprintf('No image found\n');
   end;
end;         
