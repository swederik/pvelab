function []=ShowImageCutFcn(Inp)
%
%
if (nargin ~= 1),
   fprintf('ShowImageCutFcn is called without argument\n');
   exit(1);
end;
%
if (Inp == 0),
   % Set up so next time button is pressed sagital/cornal image is created
   set(gcf,'WindowButtonDownFcn','ShowImageCutFcn(1);');
   set(gcf,'Pointer','crosshair');
elseif (Inp == 1),
   h_fig_orig=gcf;
   set(gcf,'WindowButtonDownFcn','');
   set(gcf,'Pointer','watch');
   
   % Scale to colorbar in original image
   h=get(gca,'Children');
   UserDataTxt=get(gca,'UserData');
   h_img=-1;
   if (isstr(UserDataTxt) == 1) &...
	 (strcmp(UserDataTxt,'ImageObject') == 1),
      CLim=get(gca,'CLim');
   end;
   
   Name=get(gcf,'Name');
   pos=get(gca,'CurrentPoint');
   ax_ylim=get(gca,'YLim');
   %fprintf('Current Point %f\n',pos);
   %
   Xpos=round(pos(1,1));
   Ypos=(ax_ylim(2)-ax_ylim(1))-round(pos(1,2));
   %
   [pre,dim,siz,lim,scale]=ReadAnalyzeHdr(Name);
   %
   if (min(abs(siz)) < 1e-10)
      fprintf('Voxel dimension in analyze hdr is zero, change header file\n');
   else   
      SagCut=zeros(dim(3),dim(2));
      CorCut=zeros(dim(1),dim(3));
      %
      imgAll=ReadAnalyzeImg(Name,dim,pre,lim,':');
      for ii=1:dim(3),
         img=reshape(imgAll((ii-1)*dim(1)*dim(2)+1:ii*dim(1)*dim(2)),dim(1),dim(2));
         %
         SagCut(ii,:)=img(Xpos,:);
         CorCut(:,ii)=img(:,Ypos);
         %
      end;
      %
      Xpix=min([siz(1) siz(3)]);
      Ypix=min([siz(1) siz(2)]);
      %
      Xorig=siz(2):siz(2):siz(2)*dim(2);
      Yorig=siz(3):siz(3):siz(3)*dim(3);
      Xnew=siz(2):Xpix:siz(2)*dim(2);
      Ynew=siz(3):Xpix:siz(3)*dim(3);
      %
      SagCutNew = interp2(Xorig',Yorig,SagCut,Xnew',Ynew);
      %
      Xorig=siz(3):siz(3):siz(3)*dim(3);
      Yorig=siz(1):siz(1):siz(1)*dim(1);
      Xnew=siz(2):Ypix:siz(3)*dim(3);
      Ynew=siz(1):Ypix:siz(1)*dim(1);
      %
      CorCutNew = interp2(Xorig',Yorig,CorCut,Xnew',Ynew);
      %
      Colormap=get(gcf,'Colormap');
      NoOfColors=length(Colormap);
      %
      h_f=figure('Position',[650 40 600 800],'Name',Name,'resize','on',...
                 'Colormap',Colormap,'UserData','Sagital/Coronal cut'); 
      h_ax1=gca;
      set(h_ax1,'Position',[0.13 0.55 0.775 0.415],'UserData','Sagital');
      if (scale ~= 0)
         SagCutNew=SagCutNew*scale;
      else
         SagCutNew=SagCutNew;
      end;   
      imagesc(flipud(SagCutNew)),axis('image')
      SagTxt=sprintf('Sagital cut (pos - %i)',Xpos);
      title(SagTxt)
      set(gca,'CLim',CLim);

      h_ax2=axes('Position',[0.13 0.05 0.775 0.415],'UserData','Sagital');
      if (scale ~= 0)
         CorCutNew=CorCutNew*scale;
      else
         CorCutNew=CorCutNew;
      end;   
      imagesc(flipud(CorCutNew')),axis('image')
      CorTxt=sprintf('Coronal cut (pos - %i)',Ypos);
      title(CorTxt)
      set(gca,'CLim',CLim);
   end;   

   set(h_fig_orig,'Pointer','arrow');

elseif (Inp == 2) | (Inp == 3),
   ll=get(0,'Children');
   h_sagcor = -1;
   for i=1:length(ll),
      if (isstr(get(i,'UserData')) == 1) &...
	    (strcmp(get(i,'UserData'),'Sagital/Coronal cut') == 1)
         h_sagcor=i;
      end   
   end;
   if (h_sagcor ~= -1)
      Name=get(h_sagcor,'Name');
      ch=get(h_sagcor,'children');
      ch1=get(ch(1),'child');
      ch2=get(ch(2),'child');
      img1=get(ch1(5),'cdata');
      img2=get(ch2(5),'cdata');
      colmap=get(h_sagcor,'ColorMap');
      CLim=get(gca,'CLim');

      if (Inp == 2)
         Stop=0;
         i=1;
         while (Stop == 0)
   	    name1=sprintf('%s_cor_%i',Name,i);
	    name2=sprintf('%s_sag_%i',Name,i);
	    if (exist([name1 '.tif']) ~= 2)
	       Stop = 1;
	    end;
            i=i+1;
         end;
         
         ll=length(colmap);
         img1=img1.*(img1>CLim(1))+ll*(img1>CLim(2));
	 img1=img1-CLim(1);
	 img1=img1*ll/(CLim(2)-CLim(1));
	 img2=img2.*(img2>CLim(1))+ll*(img2>CLim(2));
	 img2=img2-CLim(1);
	 img2=img2*ll/(CLim(2)-CLim(1));
      
         tiffwrite(img1,colmap,[name1 '.tif']);
         tiffwrite(img2,colmap,[name2 '.tif']);
   	 fprintf('tiff image %s and %s written\n',name1,name2);
      else
	 Stop=0;
	 i=1;
	 while (Stop == 0)
	    name1=sprintf('%s_sag_%i',Name,i);
	    name2=sprintf('%s_cor_%i',Name,i);
	    if (exist([name1 '.eps']) ~= 2)
	       Stop = 1;
	    end;
	    i=i+1;
	 end;
	 h=figure('Visible','off');
	 imagesc(img2);
	 colormap(colmap);
	 set(gca,'CLim',CLim);
	 axis('image');
	 axis('off');
	 eval(['print -depsc ' name1]);
	 imagesc(img1);
	 colormap(colmap);
	 set(gca,'CLim',CLim);
	 axis('image');
	 axis('off');
	 eval(['print -depsc ' name2]);
	 delete(h);
   	 fprintf('eps image %s and %s written\n',name1,name2);
      end;   
   else
      fprintf('No sagital/coronal cut defined\n');
   end;   
   
else
   fprintf('ShowImageSagCorCutFcn no legal input to fcn\n');
end;     
