function [Out1,Out2]=ShowImageRoiFcn(Inp,arg2,arg3,arg4),
%
Out1=[];
Out2=[];
if (nargin == 0),
   set(gcf,'WindowButtonDownFcn','[bw,XD,YD]=roipoly;ShowImageRoiFcn(1,XD,YD);');
   %[bw,XD,YD]=roipoly;
   %ShowImageRoiFcn(1,XD,YD);
   % set(gcf,'WindowButtonDownFcn','[bw,XD,YD]=roipoly;ShowImageRoiFcn(1,bw,XD,YD);');
   fprintf('\nStart marking ROI with left mouse button\n');
   fprintf('Stop marking ROI with right mouse button\n');
else
   if (Inp == 1), 
      %bw=arg2;
      %XD=arg3;
      %YD=arg4;
      ll=length(arg2);
      XD=arg2(1:ll-1);
      YD=arg3(1:ll-1);
      
      XD=XD';
      YD=YD';
      ZD=ones(size(XD));
      hl=line([XD XD(1)],[YD YD(1)],[ZD 1]);
      
      h=get(gca,'Children');
      NoOfROI=0;
      for ii=1:length(h),
         if (isstr(get(h(ii),'UserData')) == 1)
            if (~isempty(strfind(get(h(ii),'UserData'),'ROI'))),
               NoOfROI = NoOfROI + 1;
            end;
         end;   
      end;
      set(hl,'Color','r','UserData',['ROI' sprintf('%02d',NoOfROI+1)]);
      
      % Draw ROI
      RoiTxt = get(hl,'UserData');
      h_h=hatch(hl);
      XD=get(h_h,'XData');
      set(h_h,'ZData',ones(1,length(XD))*0.1);
      set(h_h,'Color','r','UserData',['HATCH' RoiTxt(4:5)]);
      
      set(gcf,'Pointer','arrow');
      set(gcf,'WindowButtonDownFcn','');
      
   elseif (Inp == 4),
      % Filter image
   
      set(gcf,'Pointer','watch');
      
      h=get(gca,'Children');
      ii_roi=0;
      h_image = -1;
      h_roi = [];
      for ii = 1:length(h)
         if (strcmp(get(h(ii),'Type'),'image') == 1)
            h_image = h(ii);
         end;
         if (isstr(get(h(ii),'UserData')) == 1) 
            if ((length(strfind(get(h(ii),'UserData'),'ROI')) ~= 0) &...
                (length(get(h(ii),'UserData')) > 0))
               ii_roi=ii_roi+1;
               h_roi(ii_roi) = h(ii);
            end;
         end;   
      end;
      if h_image == -1,
         fprintf('No image at current axis\n');
         return;
      end;
     
      Xlim=get(h_image,'XData');  % Image handle
      Ylim=get(h_image,'YData');  % Image handle
      
      ImgShadow=zeros(Ylim(2),Xlim(2));
      for ii=1:length(h_roi)
         Xdata=get(h_roi(ii),'XData');  % Image handle
         Ydata=get(h_roi(ii),'YData');  % Image handle
         ImgShadowTmp=roipoly(ImgShadow,Xdata',Ydata');

         ImgShadow=or(ImgShadow,ImgShadowTmp);
      end;
      
      if (arg2 == 0)
         % ImgShadow=ImgShadow';
         Img=get(h_image,'CData');
         Img=Img.*double(ImgShadow);
         set(h_image,'CData',Img);
      elseif (arg2 == 1)
         % ImgShadow=ImgShadow';
         ImgShadow=(ImgShadow==0);
         Img=get(h_image,'CData');
         Img=Img.*double(ImgShadow);
         set(h_image,'CData',Img);
      elseif (arg2 == 2)
         Img=get(h_image,'CData');
         Img=(Img > 0);
	 Img=or(Img,ImgShadow);
         set(h_image,'CData',Img);
      elseif (arg2 == 3)
         ImgShadow=(ImgShadow==0);
         Img=get(h_image,'CData');
         Img=(Img > 0);
	 Img=Img&ImgShadow;
         set(h_image,'CData',Img);
      else
	 error('Second argument to ShowImageRoiFcn out of limits');
      end   
      
      set(gcf,'Pointer','arrow');
   
   elseif (Inp == 5),
      % Find save image name
      
      [ImgRoiFileName, ImgRoiFilePath] = uiputfile('*.img',...
                    'Filtered image filename');
      points=strfind(ImgRoiFileName,'.img');
      if (length(points) ~= 0)
         ImgRoiFileName=ImgRoiFileName(1:points(length(points))-1);
      end;
      
      if (ImgRoiFileName ~= 0) & (~isempty(ImgRoiFileName))
         set(arg3,'UserData',ImgRoiFileName);
         
	 RoiText = uicontrol(... 
		'BackgroundColor',[ 0 0 0 ],... 
		'ButtonDownFcn','',... 
		'CallBack','',... 
		'ForegroundColor',[ 1 1 1 ],... 
		'HorizontalAlignment','center',... 
		'Position',[ 0.02 0.90 0.12 0.05 ],... 
		'String','New img file',... 
		'Style','text',... 
		'Units','normalized',... 
		'Visible','on',... 
		'Clipping','on',... 
		'Interruptible','off',... 
		'Selected','off',... 
		'UserData','RoiText'); 
   	 txt1 = uicontrol(... 
	   	   'BackgroundColor',[ 0 0 0 ],... 
		   'ButtonDownFcn','',... 
		   'CallBack','',... 
		   'ForegroundColor',[ 1 1 1 ],... 
		   'HorizontalAlignment','center',... 
		   'Position',[ 0.02 0.85 0.12 0.05 ],... 
		   'String',ImgRoiFileName,... 
		   'Style','text',... 
		   'Units','normalized',... 
		   'Visible','on',... 
		   'Clipping','on',... 
		   'Interruptible','off',... 
		   'Selected','off',... 
		   'UserData','RoiFileName'); 
         
         ShowImageRoiFcn(6,arg2); 
      else
         fprintf('No name given for filtered image filename\n');
      end;    
      
   elseif (Inp == 6),
      % save image in file
      set(gcf,'Pointer','watch');
      ImageName = get(gcf,'name');
      h=get(gcf,'Children');
      for ii=1:length(h),
         if (strcmp(get(h(ii),'Type'),'uimenu') == 1)
            if (strcmp(get(h(ii),'Label'),'Roi') == 1)
               h_roi=h(ii);
            end;   
         end;
      end;
      h=get(h_roi,'Children');
      for ii=1:length(h),
         if (strcmp(get(h(ii),'Label'),'Save img') == 1)
            h_roi=h(ii);
         end;
      end;
      RoiFileName = get(h_roi,'UserData');
      
      h=get(gca,'Children');
      h_image = -1;
      for ii = 1:length(h)
         if (strcmp(get(h(ii),'Type'),'image') == 1)
            h_image = h(ii);
         end;
      end;
      if (h_image == -1),
         fprintf('No image can be found\n');
         return;
      end;
      img=get(h_image,'CData');
      img=rot90(img,-1);
      
      if (exist([RoiFileName '.hdr']) == 2),
         [precision_roi,dim_roi,siz_roi,limits_roi,scale,offset]=ReadAnalyzeHdr(RoiFileName);
	 if (scale ~= 0)
	    img=double(img)/scale+offset;
	 else
	    index=find(img>limits_roi(2));
	    img(index)=ones(size(index))*limits_roi(2);
	    index=find(img<limits_roi(1));
	    img(index)=ones(size(index))*limits_roi(1);
	 end;   
         ImgRoi=ReadAnalyzeImg(RoiFileName,dim_roi,precision_roi,limits_roi,':');
                  
         if (arg2 <= dim_roi(3)),
            img=reshape(img,dim_roi(1)*dim_roi(2),1);
            ImgRoi((dim_roi(1)*dim_roi(2)*(arg2-1)+1):(dim_roi(1)*dim_roi(2)*arg2))=img;
            
            WriteAnalyzeImg(RoiFileName,ImgRoi,dim_roi,siz_roi,precision_roi,limits_roi,scale,offset);
         else
            img=reshape(img,dim_roi(1)*dim_roi(2),1);
            img_zeros=zeros(dim_roi(1)*dim_roi(2),1);
            for ii=dim_roi(3):arg2-2,
               dim_roi(3)=1;
               AppendAnalyze(RoiFileName,img_zeros,dim_roi,siz_roi,precision_roi,limits_roi,scale);
               % ImgRoi=[ImgRoi;img_zeros];
            end;
            % ImgRoi=[ImgRoi;img];
            % dim_roi(3)=arg2;
            % WriteAnalyzeImg(RoiFileName,ImgRoi,dim_roi,siz_roi,precision_roi,limits_roi);
            dim_roi(3)=1;
            AppendAnalyze(RoiFileName,img,dim_roi,siz_roi,precision_roi,limits_roi,scale);
         end;
      else
         [precision,dim,siz,limits,scale,offset]=ReadAnalyzeHdr(ImageName);
         if (scale ~= 0)
            img=img/scale+offset;
	 end

         ImgRoi=[];
         img=reshape(img,dim(1)*dim(2),1);
         img_zeros=zeros(dim(1)*dim(2),1);
         
         for ii=1:arg2-1,
            ImgRoi=[ImgRoi;img_zeros];
         end;
         ImgRoi=[ImgRoi;img];
         
         dim_roi=[dim(1) dim(2) arg2];
         WriteAnalyzeImg(RoiFileName,ImgRoi,dim_roi,siz,precision,limits,scale,offset);
     end;   
     set(gcf,'Pointer','arrow');
      
   elseif (Inp == 7),
      % delete region
      h=get(gca,'Children');
      h_image = -1;
      h_roi = [];
      for ii = 1:length(h)
         if (strcmp(get(h(ii),'Type'),'image') == 1)
            h_image = h(ii);
         end;
         UserDataTxt=get(h(ii),'UserData');
         if ((isstr(UserDataTxt) == 1) &...
             (strcmp(get(h(ii),'Type'),'line') == 1))
            if ((~isempty(strfind(UserDataTxt,'HATCH')) |...
                 ~isempty(strfind(UserDataTxt,'ROI')))),
               delete(h(ii));  
            end;
         end;   
      end;
      if h_image == -1,
         fprintf('No image at current axis\n');
         return;
      end;
      
      set(gcf,'WindowButtonDownFcn','');
      set(gcf,'Pointer','arrow');
      
   elseif (Inp == 9),
      % Calculate mean value in region
      
      h=get(gca,'Children');
      h_image = -1;
      h_roi = [];
      i_roi=1;
      for ii = 1:length(h)
         if (strcmp(get(h(ii),'Type'),'image') == 1)
            h_image = h(ii);
         end;
         UserDataTxt=get(h(ii),'UserData');
         if ((isstr(UserDataTxt) == 1) &...
             (strcmp(get(h(ii),'Type'),'line') == 1))
            if (~isempty(strfind(UserDataTxt,'ROI'))),
               h_roi(i_roi) = h(ii);
               i_roi=i_roi+1;  
            end;
         end;   
      end;
      i_roi=i_roi-1;
      
      if (i_roi == 0)
         fprintf('No ROI defined on image\n');
         set(gcf,'Pointer','arrow');
         return;
      end;   

      Xlim=get(h_image,'XData');  % Image handle
      Ylim=get(h_image,'YData');  % Image handle
      
      ImgShadow=zeros(Ylim(2),Xlim(2));
      for ii=1:length(h_roi)
         Xdata=get(h_roi(ii),'XData');  % Image handle
         Ydata=get(h_roi(ii),'YData');  % Image handle
         ImgShadowTmp=roipoly(ImgShadow,Xdata',Ydata');

         ImgShadow=or(ImgShadow,ImgShadowTmp);
      end;
      
      Img=get(h_image,'CData');  % Image handle
 
      Index=find(ImgShadow~=0);
      
      MeanVal=mean(Img(Index));
      StdVal=std(Img(Index));
      MinVal=min(Img(Index));
      MaxVal=max(Img(Index));
    
      Name=get(gcf,'Name');
      [pre,dim,siz,lim,scale]=ReadAnalyzeHdr(Name);
      PixArea=siz(1)*siz(2);
      ImageFileName=get(gcf,'Name');
      
      h=get(gcf,'Children');
      for ii=1:length(h)
         Txt=get(h(ii),'UserData');
         if (isstr(Txt) == 1) & (strcmp(Txt,'h(1)') == 1)
            h_slider=h(ii);
         end;
      end;
      SliceNo=round(get(h_slider,'Value'));
         
      fprintf('\n');
      fprintf('File name       : %s\n', ImageFileName);
      fprintf('  Slice         : %i\n',SliceNo);
      fprintf('  Area (pixels) : %2.3e (%i)\n',length(Index)*PixArea,length(Index));
      fprintf('  Mean+/-Std    : %2.3e +/- %2.3e\n',MeanVal,StdVal);
      fprintf('  Min/Max       : %2.3e / %2.3e\n',MinVal,MaxVal);

      set(gcf,'Pointer','arrow');
      set(gcf,'WindowButtonDownFcn','');

   elseif (Inp == 10),
      % Save ROI definition in file
      %fprintf('ShowImageRoiFcn 10 not implemented YET\n');

      h=get(gca,'Children');
      h_image = -1;
      h_roi = [];
      i_roi=1;
      for ii = 1:length(h)
         if (strcmp(get(h(ii),'Type'),'image') == 1)
            h_image = h(ii);
         end;
         UserDataTxt=get(h(ii),'UserData');
         if ((isstr(UserDataTxt) == 1) &...
             (strcmp(get(h(ii),'Type'),'line') == 1))
            if (~isempty(strfind(UserDataTxt,'ROI'))),
               h_roi(i_roi) = h(ii);
               i_roi=i_roi+1;  
            end;
         end;   
      end;
      i_roi=i_roi-1;
      
      if (i_roi == 0)
         fprintf('No ROI defined on image\n');
         set(gcf,'Pointer','arrow');
         return;
      end;   
      
      set(gcf,'WindowButtonDownFcn','');
    
      [RoiFileName, RoiFilePath] = uiputfile('*.roi', 'Roi filename');
      
      if (RoiFileName ~= 0)
         points=strfind(RoiFileName,'.roi');
         if (length(points) == 0)
            RoiFileName=[RoiFileName '.roi'];
         end;     
      else
         fprintf('ROI not saved, due to missing specification of file name\n');
         return
      end;
      
      fid=fopen([RoiFilePath RoiFileName],'w');
      for ii=1:i_roi  
         xdata=get(h_roi(ii),'XData');
         ydata=get(h_roi(ii),'YData');
         
         for jj=1:(length(xdata)-1)
            fprintf(fid,'%e %e\n',xdata(jj),ydata(jj));
         end;
         fprintf(fid,'\n');
      end;
      fclose(fid);   

      set(gcf,'Pointer','arrow');
      set(gcf,'WindowButtonDownFcn','');
    
   elseif (Inp == 13),
      % Load ROI definition in file
      % fprintf('ShowImageRoiFcn 13 not implemented YET\n');
      % fprintf('Roi with name %s shall be used\n',arg2);

      [RoiFileName, RoiFilePath] = uigetfile('*.roi', 'Roi filename');

      if (RoiFileName ~= 0)
         h=get(gca,'Children');
         NoOfROI=0;
            for ii=1:length(h),
            if (isstr(get(h(ii),'UserData')) == 1)
               if (~isempty(strfind(get(h(ii),'UserData'),'ROI'))),
                  NoOfROI = NoOfROI + 1;
               end;
            end;   
         end;
       
         fid = fopen([RoiFilePath RoiFileName],'r');  
         if (fid ~= -1),
            Stop = 0;
         
            while (Stop == 0)
               Stop1=0;
               xdata=[];
               ydata=[];
               counter=1;
               while (Stop1 == 0)
                  str = fgetl(fid);
                  if (isstr(str) == 1)
                     [roidata,count] = sscanf(str,'%e %e');
                     if (count == 2)
                        xdata(counter,1)=roidata(1);
                        ydata(counter,1)=roidata(2);
                        counter=counter+1;
                     else
                        Stop1=1;
                     end;
                  else
                     Stop1 = 1;
                  end;      
               end;
               if (feof(fid) == 1)
                  Stop = 1;
               end;            
                 
               h=line([xdata; xdata(1)],[ydata; ydata(1)],...
                      ones(size([xdata; 1]))*0.1);
               set(h,'Color','r','UserData',['ROI' sprintf('%02d',NoOfROI+1)]);

               h_h=hatch(h);
               XD=get(h_h,'XData');
               set(h_h,'ZData',ones(size(XD))*0.1);
               set(h_h,'Color','r','UserData',['HATCH' sprintf('%02d',NoOfROI+1)]);
            
               pos = ftell(fid);
               str = fgetl(fid);
               if (feof(fid) == 1)
                  Stop = 1;
               else
                  fseek(fid, pos,-1); 
               end;            
            
            end;
            fclose(fid);
         else
            fprintf('Not posssible to open ROI file\n');
         end;   
      else
         fprintf('No ROI file name specified\n');
      end;   
      
   elseif (Inp == 14),
      % Find save image name, for all images
      
      [ImgRoiFileName, ImgRoiFilePath] = uiputfile('*.img',...
                    'Filtered image filename');
      points=strfind(ImgRoiFileName,'.img');
      if (length(points) ~= 0)
         ImgRoiFileName=ImgRoiFileName(1:points(length(points))-1);
      end;
      
      if (ImgRoiFileName ~= 0) & (~isempty(ImgRoiFileName))
         set(arg3,'UserData',ImgRoiFileName);
         
	 RoiText = uicontrol(... 
		'BackgroundColor',[ 0 0 0 ],... 
		'ButtonDownFcn','',... 
		'CallBack','',... 
		'ForegroundColor',[ 1 1 1 ],... 
		'HorizontalAlignment','center',... 
		'Units','normalized',... 
		'Position',[ 0.02 0.90 0.12 0.05 ],... 
		'String','New img file',... 
		'Style','text',... 
		'Visible','on',... 
		'Clipping','on',... 
		'Interruptible','off',... 
		'Selected','off',... 
		'UserData','RoiText'); 
   	 txt1 = uicontrol(... 
	   	   'BackgroundColor',[ 0 0 0 ],... 
		   'ButtonDownFcn','',... 
		   'CallBack','',... 
		   'ForegroundColor',[ 1 1 1 ],... 
		   'HorizontalAlignment','center',... 
		   'Units','normalized',... 
		   'Position',[ 0.02 0.85 0.12 0.05 ],... 
		   'String',ImgRoiFileName,... 
		   'Style','text',... 
		   'Visible','on',... 
		   'Clipping','on',... 
		   'Interruptible','off',... 
		   'Selected','off',... 
		   'UserData','RoiFileName'); 
         
         ShowImageRoiFcn(15,arg2); 
      else
         fprintf('No name given for filtered image filename\n');
      end;    
      
   elseif (Inp == 15),
      % save image in file
      set(gcf,'Pointer','watch');
      ImageName = get(gcf,'name');
      h=get(gcf,'Children');
      for ii=1:length(h),
         if (strcmp(get(h(ii),'Type'),'uimenu') == 1)
            if (strcmp(get(h(ii),'Label'),'Roi') == 1)
               h_roi=h(ii);
            end;   
         end;
      end;
      h=get(h_roi,'Children');
      for ii=1:length(h),
         if (strcmp(get(h(ii),'Label'),'Save img') == 1)
            h_roi=h(ii);
         end;
      end;
      RoiFileName = get(h_roi,'UserData');


      % Find all ROI defined in image
      h=get(gca,'Children');
      ii_roi=0;
      h_image = -1;
      h_roi = [];
      for ii = 1:length(h)
         if (strcmp(get(h(ii),'Type'),'image') == 1)
            h_image = h(ii);
         end;
         if (isstr(get(h(ii),'UserData')) == 1) 
            if ((length(strfind(get(h(ii),'UserData'),'ROI')) ~= 0) &...
                (length(get(h(ii),'UserData')) > 0))
               ii_roi=ii_roi+1;
               h_roi(ii_roi) = h(ii);
            end;
         end;   
      end;
      if h_image == -1,
         fprintf('No image at current axis\n');
         return;
      end;
     
      Xlim=get(h_image,'XData');  % Image handle
      Ylim=get(h_image,'YData');  % Image handle

      ImgShadow=zeros(Ylim(2),Xlim(2));
      for ii=1:length(h_roi)
         Xdata=get(h_roi(ii),'XData');  % Image handle
         Ydata=get(h_roi(ii),'YData');  % Image handle
         ImgShadowTmp=roipoly(ImgShadow,Xdata',Ydata');

         ImgShadow=ImgShadow|ImgShadowTmp;
      end;

      % Deselect generating ROI
      set(gcf,'WindowButtonDownFcn','');
      set(gcf,'WindowButtonUpFcn','');
      set(gcf,'Pointer','arrow');
      
      set(gcf,'Pointer','watch');
      % Laes og filtrer billeder i image fil
      [pre,dim,siz,lim,scale,offset]=ReadAnalyzeHdr(ImageName);
      ImgShadow=flipud(ImgShadow);
      ImgShadow=ImgShadow';
      ImgShadow=reshape(ImgShadow,dim(1)*dim(2),1);
      imgT=ReadAnalyzeImg(ImageName,dim,pre,lim,':');
      for ii=1:dim(3),
         img=imgT((ii-1)*(dim(1)*dim(2))+1:ii*(dim(1)*dim(2)));
         img2=img.*double(ImgShadow);
         dimOut=[dim(1) dim(2) 1];
         if (ii==1)
            WriteAnalyzeImg(RoiFileName,img2,dimOut,siz,pre,lim,scale,offset);
         else   
            AppendAnalyze(RoiFileName,img2,dimOut,siz,pre,lim,scale);
         end;   
      end;
      set(gcf,'Pointer','arrow');
      
   elseif (Inp == 16),
      % Find ROI's, Calculate mean, Show ROI curve, Save in file
      
      ImageName=arg2;
      
      [RoiCurveName, RoiCurvePath] = uigetfile('*.tac',...
                    'Roi curve filename');
      points=strfind(RoiCurveName,'.tac');
      if (length(points) ~= 0)
         RoiCurveName=RoiCurveName(1:points(length(points))-1);
      end;
      
      % Find all ROI defined in image
      h=get(gca,'Children');
      ii_roi=0;
      h_image = -1;
      h_roi = [];
      for ii = 1:length(h)
         if (strcmp(get(h(ii),'Type'),'image') == 1)
            h_image = h(ii);
         end;
         if (isstr(get(h(ii),'UserData')) == 1) 
            if ((length(strfind(get(h(ii),'UserData'),'ROI')) ~= 0) &...
                (length(get(h(ii),'UserData')) > 0))
               ii_roi=ii_roi+1;
               h_roi(ii_roi) = h(ii);
            end;
         end;   
      end;
      if h_image == -1,
         fprintf('No image at current axis\n');
         return;
      end;
     
      Xlim=get(h_image,'XData');  % Image handle
      Ylim=get(h_image,'YData');  % Image handle

      ImgShadow=zeros(Ylim(2),Xlim(2));
      for ii=1:length(h_roi)
         Xdata=get(h_roi(ii),'XData');  % Image handle
         Ydata=get(h_roi(ii),'YData');  % Image handle
         ImgShadowTmp=roipoly(ImgShadow,Xdata',Ydata');

         ImgShadow=((ImgShadow+ImgShadowTmp)>0);
      end;

      % Deselect generating ROI
      set(gcf,'WindowButtonDownFcn','');
      set(gcf,'WindowButtonUpFcn','');
      set(gcf,'Pointer','arrow');
      
      set(gcf,'Pointer','watch');
      % Laes og filtrer billeder i image fil
      [pre,dim,siz,lim,scale,offset]=ReadAnalyzeHdr(ImageName);
      ImgShadow=flipud(ImgShadow);
      ImgShadow=ImgShadow';
      ImgShadow=reshape(ImgShadow,dim(1)*dim(2),1);
      Index=find(ImgShadow~=0);
      if (length(dim) == 3)
	error('This is not a dynamic image set');
      end;
      % Laes aktuelt billednummer staar i userdata 1.
      handle_list = get(gcf,'userdata');
      ActImgNo = round(get(handle_list(1),'Value'));
      imgT=ReadAnalyzeImg(ImageName,dim,pre,lim,sprintf('%i:',ActImgNo));
      for ii=1:dim(4),
         img=imgT((ii-1)*(dim(1)*dim(2))+1:ii*(dim(1)*dim(2)));
         RoiCurveData(ii)=(mean(img(Index))-offset)*scale;
      end;
      set(gcf,'Pointer','arrow');
      
      if (RoiCurveName ~= 0) & (RoiCurveName ~= '')
         pid=fopen([RoiCurvePath RoiCurveName '.tac'],'w');
         if (pid ~= -1)
            fprintf(pid,'%e\n',RoiCurveData);
            fclose(pid);
         else
            fprintf('Not possible to open Roi curve file (%s)\n',...
                     [RoiCurvePath RoiCurveName '.tac']);
         end,
      else
         fprintf('No name given for roi, data will not be saved\n');
      end;    
      
      h=figure;
      set(h,'Name',arg2);
      plot(RoiCurveData);
      xlabel('Frame no')
      ylabel('Roi data')
      title('Plot of mean roi pixel values');
      
   else
      fprintf('Inp undefined\n');
   end;
end;         
