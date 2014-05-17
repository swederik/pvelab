function []=ShowImageFuseFcn(Inp)
%
%
if (nargin ~= 1),
   fprintf('ShowImageFuseFcn is called without argument\n');
   exit(1);
end;
%
if Inp ~= 0 
	handle_list = get(gcf,'userdata'); 
	if length(handle_list) > 0 
		h(1) = handle_list(1); 
		h(2) = handle_list(2); 
		h(3) = handle_list(3); 
		h(4) = handle_list(4); 
		h(5) = handle_list(5); 
		h(6) = handle_list(6); 
		h(7) = handle_list(7); 
		h(8) = handle_list(8); 
		txt1 = handle_list(9); 
		txt2 = handle_list(10); 
		txt3 = handle_list(11); 
		txt4 = handle_list(12); 
	end 
end 
%
if (Inp == 0),
   h_fig_orig=gcf;
   
%	figure('position',[ 360 543 560 420 ],'resize','on'); 
	figure('position',[ 290 543 640 450 ],'resize','on'); 
	set(gca,'visible','off');
	set(gcf,'Interruptible','on'); 

	%  Uicontrol Object Creation 
	h(1) = uicontrol(... 
		'BackgroundColor',[ 0.7 0.7 0.7 ],... 
		'ButtonDownFcn','',... 
		'CallBack','ShowImageFuseFcn(1);',... 
		'ForegroundColor',[ 0 0 0 ],... 
		'HorizontalAlignment','center',... 
		'Max',[ 1+1e-6 ],... 
		'Min',[ 1 ],... 
		'Position',[ 0.03 0.39 0.035 0.22 ],... 
		'Enable','on',... 
		'String',' ',... 
		'Style','slider',... 
		'Units','normalized',... 
		'Value',[ 1 ],... 
		'Visible','on',... 
		'ButtonDownFcn','',... 
		'Clipping','on',... 
		'Interruptible','off',... 
		'Selected','off',... 
		'UserData','h(1)'); 
	h(2) = uicontrol(... 
		'BackgroundColor',[ 0.7 0.7 0.7 ],... 
		'ButtonDownFcn','',... 
		'CallBack','ShowImageFuseFcn(2);',... 
		'ForegroundColor',[ 0 0 0 ],... 
		'HorizontalAlignment','center',... 
		'Max',[ 1 ],... 
		'Min',[ 0 ],... 
		'Position',[ 0.03 0.26 0.11 0.05 ],... 
		'Enable','on',... 
		'String','NEXT',... 
		'Style','pushbutton',... 
		'Units','normalized',... 
		'Value',[ 0 ],... 
		'Visible','on',... 
		'Clipping','on',... 
		'Interruptible','off',... 
		'Selected','off',... 
		'UserData','h(2)'); 
	h(3) = uicontrol(... 
		'BackgroundColor',[ 0.7 0.7 0.7 ],... 
		'ButtonDownFcn','',... 
		'CallBack','ShowImageFuseFcn(3);',... 
		'ForegroundColor',[ 0 0 0 ],... 
		'HorizontalAlignment','center',... 
		'Max',[ 1 ],... 
		'Min',[ 0 ],... 
		'Position',[ 0.03 0.15 0.11 0.05 ],... 
		'Enable','on',... 
		'String','PREV',... 
		'Style','pushbutton',... 
		'Units','normalized',... 
		'Value',[ 0 ],... 
		'Visible','on',... 
		'Clipping','on',... 
		'Interruptible','off',... 
		'Selected','off',... 
		'UserData','h(3)'); 
	h(4) = uicontrol(... 
		'BackgroundColor',[ .7 0 0 ],... 
		'ButtonDownFcn','',... 
		'CallBack','ShowImageFuseFcn(4);',... 
		'ForegroundColor',[ 0 0 0 ],... 
		'HorizontalAlignment','center',... 
		'Max',[ 1 ],... 
		'Min',[ 0 ],... 
		'Position',[ 0.03 0.05 0.11 0.05 ],... 
		'Enable','on',... 
		'String','EXIT',... 
		'Style','pushbutton',... 
		'Units','normalized',... 
		'Value',[ 0 ],... 
		'Visible','on',... 
		'Clipping','on',... 
		'Interruptible','off',... 
		'Selected','off',... 
		'UserData','h(4)'); 
	h(5) = 0;    
	h(6) = uimenu(... 
		'BackgroundColor',[ 0.7 0.7 0.7 ],... 
		'CallBack','ShowImageFuseFcn(6);',... 
		'ForegroundColor',[ 0 0 0 ],... 
		'Enable','on',... 
		'Visible','on',... 
		'Label','Image',...
		'Accelerator','I',...
		'ButtonDownFcn','',... 
		'Clipping','on',... 
		'Interruptible','off',... 
		'UserData',''); 
	  h6(1) = uimenu(h(6),... 
		  'BackgroundColor',[ 0.7 0.7 0.7 ],... 
		  'CallBack','ShowImageFuseFcn(61);',... 
		  'ForegroundColor',[ 0 0 0 ],... 
		  'Enable','on',... 
		  'Visible','on',... 
		  'Label','Select',...
		  'Clipping','on',... 
		  'Interruptible','off',... 
		  'UserData','h6(1)'); 
	  h6(2) = uimenu(h(6),... 
		  'BackgroundColor',[ 0.7 0.7 0.7 ],... 
		  'CallBack','ShowImageFuseFcn(62);',... 
		  'ForegroundColor',[ 0 0 0 ],... 
		  'Enable','on',... 
		  'Visible','on',... 
		  'Label','Select bin',...
		  'Clipping','on',... 
		  'Interruptible','off',... 
		  'UserData','h6(2)'); 
        h(7) = 0;
	h(8) = uimenu(... 
		'BackgroundColor',[ 0.7 0.7 0.7 ],... 
		'CallBack','ShowImageFuseFcn(8);',... 
		'ForegroundColor',[ 0 0 0 ],... 
		'Enable','on',... 
		'Visible','on',... 
		'Label','Print',...
		'Accelerator','P',...
		'ButtonDownFcn','',... 
		'Clipping','on',... 
		'Interruptible','off',... 
		'UserData','h(8)'); 
	  h8(1) = uimenu(h(8),... 
		  'BackgroundColor',[ 0.7 0.7 0.7 ],... 
		  'CallBack','ShowImageFuseFcn(81);',... 
		  'ForegroundColor',[ 0 0 0 ],... 
		  'Enable','on',... 
		  'Visible','on',... 
		  'Label','Laserprinter',...
		  'Clipping','on',... 
		  'Interruptible','off',... 
		  'UserData','h8(1)'); 
	  h8(2) = uimenu(h(8),... 
		  'BackgroundColor',[ 0.7 0.7 0.7 ],... 
		  'CallBack','ShowImageFuseFcn(82);',... 
		  'ForegroundColor',[ 0 0 0 ],... 
		  'Enable','on',... 
		  'Visible','on',... 
		  'Label','Paintjet',...
		  'Clipping','on',... 
		  'Interruptible','off',... 
		  'UserData','h8(2)'); 
	  h8(3) = uimenu(h(8),... 
		  'BackgroundColor',[ 0.7 0.7 0.7 ],... 
		  'CallBack','ShowImageFuseFcn(83);',... 
		  'ForegroundColor',[ 0 0 0 ],... 
		  'Enable','on',... 
		  'Visible','on',... 
		  'Label','Tiff image',...
		  'Clipping','on',... 
		  'Interruptible','off',... 
		  'UserData','h8(3)'); 
	  h8(4) = uimenu(h(8),... 
		  'BackgroundColor',[ 0.7 0.7 0.7 ],... 
		  'CallBack','ShowImageFuseFcn(84);',... 
		  'ForegroundColor',[ 0 0 0 ],... 
		  'Enable','on',... 
		  'Visible','on',... 
		  'Label','EPS image',...
		  'Clipping','on',... 
		  'Interruptible','off',... 
		  'UserData','h8(4)'); 
	  h8(5) = uimenu(h(8),... 
		  'BackgroundColor',[ 0.7 0.7 0.7 ],... 
		  'CallBack','ShowImageFuseFcn(85);',... 
		  'ForegroundColor',[ 0 0 0 ],... 
		  'Enable','on',... 
		  'Visible','on',... 
		  'Label','Tiff image (all)',...
		  'Clipping','on',... 
		  'Interruptible','off',... 
		  'UserData','h8(5)'); 
		      
	 txt1 = uicontrol(... 
		'BackgroundColor',[ 0 0 0 ],... 
		'ButtonDownFcn','',... 
		'CallBack','',... 
		'ForegroundColor',[ 1 1 1 ],... 
		'HorizontalAlignment','center',... 
		'Position',[ 0.09 0.475 0.04 0.05 ],... 
		'String',num2str(round(get(h(1),'Value'))),... 
		'Style','text',... 
		'Units','normalized',... 
		'Visible','on',... 
		'Clipping','on',... 
		'Interruptible','off',... 
		'Selected','off',... 
		'UserData','txt1'); 
	 txt2 = uicontrol(... 
		'BackgroundColor',[ 0 0 0 ],... 
		'ButtonDownFcn','',... 
		'CallBack','',... 
		'ForegroundColor',[ 1 1 1 ],... 
		'HorizontalAlignment','center',... 
		'Position',[ 0.09 0.56 0.04 0.05 ],... 
		'String',num2str(get(h(1),'Max')),... 
		'Style','text',... 
		'Units','normalized',... 
		'Visible','on',... 
		'Clipping','on',... 
		'Interruptible','off',... 
		'Selected','off',... 
		'UserData','txt2'); 
	 txt3 = uicontrol(... 
		'BackgroundColor',[ 0 0 0 ],... 
		'ButtonDownFcn','',... 
		'CallBack','',... 
		'ForegroundColor',[ 1 1 1 ],... 
		'HorizontalAlignment','center',... 
		'Position',[ 0.09 0.39 0.04 0.05 ],... 
		'String',num2str(get(h(1),'Min')),... 
		'Style','text',... 
		'Units','normalized',... 
		'Visible','on',... 
		'Clipping','on',... 
		'Interruptible','off',... 
		'Selected','off',... 
		'UserData','txt3'); 
	 txt4 = uicontrol(... 
		'BackgroundColor',[ 0 0 0 ],... 
		'ButtonDownFcn','',... 
		'CallBack','',... 
		'ForegroundColor',[ 1 1 1 ],... 
		'HorizontalAlignment','center',... 
		'Position',[ 0.09 0.62 0.04 0.05 ],... 
		'String','No.',... 
		'Style','text',... 
		'Units','normalized',... 
		'Visible','on',... 
		'Clipping','on',... 
		'Interruptible','off',... 
		'Selected','off',... 
		'UserData','txt4'); 

	handle_ui_list = [ h(1) h(2) h(3) h(4) h(5), h(6), h(7), h(8),...
	                   txt1 txt2 txt3 txt4 ]; 

	handle_list = [handle_ui_list]; 
	set(gcf,'userdata',handle_list); 
	
   
   Name=get(h_fig_orig,'Name');
   hh=get(h_fig_orig,'Children');
   h_img_obj=-1;
   for i=1:length(hh)
      if (isstr(get(hh(i),'UserData')) == 1) &...
	    (strcmp(get(hh(i),'UserData'),'ImageObject') == 1)
	 h_img_obj = hh(i);
      end;
   end;
   if (h_img_obj ~= -1)
      hhh=get(h_img_obj,'Children');
      limits=get(hhh(5),'UserData');
   else
      fprintf('No image selected yet!\n');
      return
   end;   

   if (~isempty(Name)) & (Name ~= 0)
   
      h_orig=get(h_fig_orig,'UserData');
      ImgNo = round(get(h_orig(1),'value'));
      Colormap=get(h_fig_orig,'Colormap');
      NoOfOrgColors=length(Colormap);
      
      load ShowImageColMap.txt
      NoOfOverlayColors=length(ShowImageColMap);
      
      Colormap=[ShowImageColMap; Colormap];
keyboard
      ImgLimits=[limits(2) limits(1) 255 0];
   
      ImgFuse=ShowImageFuseCalc(ImgNo,Name,'',NoOfOrgColors,ImgLimits,NoOfOverlayColors);
      
      if (ImgFuse ~= [])
         hi=image(rot90(ImgFuse));

         set(hi,'UserData',ImgLimits);   

         set(gca,'UserData','ImageObject','TickDir','out','FontName','Times');
         axis('image');

         set(gcf,'NextPlot','add');
         set(gcf,'Colormap',Colormap);
         set(gcf,'Name',Name);
         colorbar
      else
         fprintf('No data in choosen image file (%s)\n',ImageName);   
      end;
   
      
      [pre,dim,siz,lim,scale,offset]=ReadAnalyzeHdr(Name);
      set(h(1),'Max',dim(3));
      set(txt2,'String',num2str(dim(3)),'UserData',num2str(dim(3)));
      set(txt1,'string',num2str(round(ImgNo))); 
      set(h(1),'value',round(ImgNo)); 

      set(gca,'Visible','off');
      
   else
      fprintf('No original image file choosen (can not segment)\n');   
   end;   

elseif Inp == 1 		  
        set(h,'ButtonDownFcn','');  
        
	% disp('h(1) selected.') 
	ImgNo = round(get(h(1),'value'));
	set(txt1,'string',num2str(ImgNo)); 

        load ShowImageColMap.txt
        NoOfOrgColors=length(ShowImageColMap);
        Colormap=get(gcf,'Colormap');
        NoOfOverlayColors=length(Colormap)-NoOfOrgColors;
        ImgNo = round(get(h(1),'value'));
           
        Name=get(gcf,'Name');
        OverlayNames=get(h(6),'UserData');
     
        hhh=get(gca,'Children');
        hh_image=-1;
        for ii=1:length(hhh),
           if (strcmp(get(hhh(ii),'Type'),'image') == 1),
              hh_image=hhh(ii);
           end;   
        end;
	      
        if (hh_image ~= -1),
           ImgLimits=get(hh_image,'UserData');
        else
           fprintf('ShowImageFuseFcn, No image in current figure\n');
	   exit(1);
        end;
     
	[ImgFuse,ImgLim]=ShowImageFuseCalc(ImgNo,Name,OverlayNames,NoOfOrgColors,...
	         ImgLimits,NoOfOverlayColors);
      
        if (ImgFuse ~= [])
           set(hh_image,'CData',rot90(ImgFuse));
           %set(hh_image,'UserData',ImgLim);
	   colorbar
        else
           fprintf('ShowImageFuseFcn, No image from ShowImageFuseCalc\n');
	   exit(1)
        end;  
	
elseif Inp == 2 
        set(h,'ButtonDownFcn','');  
        
	% disp('h(2) selected.') 
	ImgNo = round(get(h(1),'value'));
	ImgNo = ImgNo + 1;
	if ImgNo > get(h(1),'Max')
	   ImgNo = get(h(1),'Max');
	end;   
	set(txt1,'string',num2str(ImgNo)); 
	set(h(1),'value',ImgNo); 

        load ShowImageColMap.txt
        NoOfOrgColors=length(ShowImageColMap);
        Colormap=get(gcf,'Colormap');
        NoOfOverlayColors=length(Colormap)-NoOfOrgColors;
        ImgNo = round(get(h(1),'value'));
           
        Name=get(gcf,'Name');
        OverlayNames=get(h(6),'UserData');
     
        hhh=get(gca,'Children');
        hh_image=-1;
        for ii=1:length(hhh),
           if (strcmp(get(hhh(ii),'Type'),'image') == 1),
              hh_image=hhh(ii);
           end;   
        end;
	      
        if (hh_image ~= -1),
           ImgLimits=get(hh_image,'UserData');
        else
           fprintf('ShowImageFuseFcn, No image in current figure\n');
	   exit(1);
        end;
     
        [ImgFuse,ImgLim]=ShowImageFuseCalc(ImgNo,Name,OverlayNames,NoOfOrgColors,...
	         ImgLimits,NoOfOverlayColors);
      
        if (ImgFuse ~= [])
           set(hh_image,'CData',rot90(ImgFuse));
           %set(hh_image,'UserData',ImgLim);
	   colorbar
        else
           fprintf('ShowImageFuseFcn, No image from ShowImageFuseCalc\n');
	   exit(1)
        end;  
		
	
elseif Inp == 3 
        set(h,'ButtonDownFcn','');  
        
	% disp('h(3) selected.') 
	ImgNo = round(get(h(1),'value'));
	ImgNo = ImgNo - 1;
	if ImgNo < get(h(1),'Min')
	   ImgNo = get(h(1),'Min');
	end;   
	set(txt1,'string',num2str(ImgNo)); 
	set(h(1),'value',ImgNo); 

        load ShowImageColMap.txt
        NoOfOrgColors=length(ShowImageColMap);
        Colormap=get(gcf,'Colormap');
        NoOfOverlayColors=length(Colormap)-NoOfOrgColors;
        ImgNo = round(get(h(1),'value'));
           
        Name=get(gcf,'Name');
        OverlayNames=get(h(6),'UserData');
     
        hhh=get(gca,'Children');
        hh_image=-1;
        for ii=1:length(hhh),
           if (strcmp(get(hhh(ii),'Type'),'image') == 1),
              hh_image=hhh(ii);
           end;   
        end;
	      
        if (hh_image ~= -1),
           ImgLimits=get(hh_image,'UserData');
        else
           fprintf('ShowImageFuseFcn, No image in current figure\n');
	   exit(1);
        end;
     
        [ImgFuse,ImgLim]=ShowImageFuseCalc(ImgNo,Name,OverlayNames,NoOfOrgColors,...
	         ImgLimits,NoOfOverlayColors);
      
        if (ImgFuse ~= [])
           set(hh_image,'CData',rot90(ImgFuse));
           %set(hh_image,'UserData',ImgLim);
	   colorbar
        else
           fprintf('ShowImageFuseFcn, No image from ShowImageFuseCalc\n');
	   exit(1)
        end;  
		
	
elseif Inp == 4 
        % exit
        close(gcf);
	% disp('h(4) selected.') 
elseif Inp == 5 
	% disp('h(5) selected.') 

      
elseif Inp == 6 
	% disp('h(6) selected.') 
elseif Inp == 61 
	% disp('h6(1) selected.') 
        [OverlayFileName, OverlayFilePath] = uigetfile('*.img',...
                    'Overlay file');
        
        if (OverlayFileName == 0) | (OverlayFileName == '')
	  fprintf('No overlay image selected\n');
	  return
        else
   	   PointPos=strfind(OverlayFileName,'.img');
           if (length(PointPos) ~= 0)
              OverlayFileName=OverlayFileName(1:PointPos(length(PointPos))-1); 
           end;          
	   
	   OrgFileName=get(gcf,'Name');
           [preO,dimO,sizO,limO,scaleO,offsetO]=ReadAnalyzeHdr(OrgFileName);
           [pre,dim,siz,lim,scale,offset]=ReadAnalyzeHdr(OverlayFileName);
	   if ((dimO(1) ~= dim(1)) | (dimO(2) ~= dim(2)) | ...
	       (abs(sizO(1)-siz(1)) > 1e-10) | (abs(sizO(2)-siz(2)) > 1e-10))
	      fprintf('Overlay file not compatible in (X,Y) dim or size)\n');
	   else   
	      PrevFiles=get(h(6),'UserData');	   
	      if (length(PrevFiles) == 0)
                 set(h(6),'UserData',[OverlayFilePath OverlayFileName ':']);
	      else
                 set(h(6),'UserData',[PrevFiles OverlayFilePath OverlayFileName ':']);
              end;
	   end;   
        end;
	
     [pre,dim,siz,lim,scale,offset]=ReadAnalyzeHdr([OverlayFilePath OverlayFileName]);
     img=ReadAnalyzeImg([OverlayFilePath OverlayFileName],dim,pre,lim,':');
     MaxImg=(max(img(:))-offset)*scale;
     MinImg=(min(img(:))-offset)*scale;

     load ShowImageColMap.txt
     Colormap=get(gcf,'Colormap');
     NoOfOrgColors=length(ShowImageColMap);
     NoOfOverlayColors=length(ShowImageColMap);
     colormap([ShowImageColMap; ...
	       Colormap(length(Colormap)-NoOfOrgColors+1:length(Colormap),:)]);
     colorbar
     ImgNo = round(get(h(1),'value'));
           
     Name=get(gcf,'Name');
     OverlayNames=get(h(6),'UserData');
     
     hhh=get(gca,'Children');
     hh_image=-1;
     for ii=1:length(hhh),
        if (strcmp(get(hhh(ii),'Type'),'image') == 1),
           hh_image=hhh(ii);
        end;   
     end;
	      
     if (hh_image ~= -1),
        ImgLimits=get(hh_image,'UserData');
     else
        fprintf('ShowImageFuseFcn, No image in current figure\n');
	exit(1);
     end;
     
     ImgLimits=[ImgLimits(1) ImgLimits(2) MaxImg MinImg];
     
     [ImgFuse,ImgLim]=ShowImageFuseCalc(ImgNo,Name,OverlayNames,NoOfOrgColors,...
	      ImgLimits,NoOfOverlayColors);
      
     if (ImgFuse ~= [])
        set(hh_image,'CData',rot90(ImgFuse));
        %set(hh_image,'UserData',ImgLim);
	colorbar
     else
        fprintf('ShowImageFuseFcn, No image from ShowImageFuseCalc\n');
	exit(1)
     end;  

     
elseif Inp == 62      
     % disp('h6(2) selected.') 
        [OverlayFileName, OverlayFilePath] = uigetfile('*.img',...
                    'Overlay file');
        
        if (OverlayFileName == 0) | (OverlayFileName == '')
	  fprintf('No overlay image selected\n');
	  return
	end;  
	
   	   PointPos=strfind(OverlayFileName,'.img');
           if (length(PointPos) ~= 0)
              OverlayFileName=OverlayFileName(1:PointPos(length(PointPos))-1); 
           end;          
	   
	   OrgFileName=get(gcf,'Name');
           [preO,dimO,sizO,limO,scaleO,offsetO]=ReadAnalyzeHdr(OrgFileName);
           [pre,dim,siz,lim,scale,offset]=ReadAnalyzeHdr([OverlayFilePath OverlayFileName]);
	   if ((dimO(1) ~= dim(1)) | (dimO(2) ~= dim(2)) | ...
	       (abs(sizO(1)-siz(1)) > 1e-10) | (abs(sizO(2)-siz(2)) > 1e-10))
	      fprintf('Overlay file not compatible in (X,Y) dim or size)\n');
	   else   
	      PrevFiles=get(h(6),'UserData');	   
	      if (length(PrevFiles) == 0)
                 set(h(6),'UserData',[OverlayFilePath OverlayFileName ':']);
	      else
                 set(h(6),'UserData',[PrevFiles OverlayFilePath OverlayFileName ':']);
              end;
	   end;   
        	
     [pre,dim,siz,lim,scale,offset]=ReadAnalyzeHdr([OverlayFilePath OverlayFileName]);
     img=ReadAnalyzeImg([OverlayFilePath OverlayFileName],dim,pre,lim,':');
     MaxImg=max(img(:));
    
     load ShowImageColCircle.txt
     load ShowImageColMap.txt
     NoOfOrgColors=length(ShowImageColMap);
     ColMap=get(gcf,'Colormap');
     NoOfOverlayColors=MaxImg;
     if (NoOfOverlayColors > length(ShowImageColCircle)-1)
        fprintf('ShowImageFuseFcn, Too many colors (%i) in image, try Select instead\n',...
                 NoOfOverlayColors);
	return
     end;	
     NewColMap=[ShowImageColCircle(2:NoOfOverlayColors+1,:);...
	        ColMap(length(ColMap)-NoOfOrgColors+1:length(ColMap),:)];
     colormap(NewColMap);
     colorbar
     ImgNo = round(get(h(1),'value'));
           
     Name=get(gcf,'Name');
     OverlayNames=get(h(6),'UserData');
     
     hhh=get(gca,'Children');
     hh_image=-1;
     for ii=1:length(hhh),
        if (strcmp(get(hhh(ii),'Type'),'image') == 1),
           hh_image=hhh(ii);
        end;   
     end;
	      
     if (hh_image ~= -1),
        ImgLimits=get(hh_image,'UserData');
     else
        fprintf('ShowImageFuseFcn, No image in current figure\n');
	exit(1);
     end;
     
     ImgLimits=[ImgLimits(1) ImgLimits(2) MaxImg 0];
     set(hh_image,'UserData',ImgLimits);
     
     [ImgFuse,ImgLim]=ShowImageFuseCalc(ImgNo,Name,OverlayNames,NoOfOrgColors,...
	      ImgLimits,NoOfOverlayColors);
      
     if (ImgFuse ~= [])
        set(hh_image,'CData',rot90(ImgFuse));
        %set(hh_image,'UserData',ImgLim);
	colorbar
     else
        fprintf('ShowImageFuseFcn, No image from ShowImageFuseCalc\n');
	exit(1)
     end;
     
elseif Inp == 7 
	disp('h(7) selected.') 
	disp('NOT implemented yet') 

elseif Inp == 8 
	% disp('h(8) selected.') 
elseif Inp == 81
        orient landscape
	ImgNo = round(get(h(1),'value'));
        h=text(mean(get(gca,'XLim')),...
               min(get(gca,'YLim'))-0.1*mean(get(gca,'YLim')),...
               ['Filename: ' get(gcf,'Name') ', Slice: ' num2str(ImgNo) ', with overlay']);
        set(h,'HorizontalAlignment','center');
        pos=get(gcf,'PaperPosition');
        marg=0.05*pos(3:4);
        siz=0.9*pos(3:4);
        set(gcf,'PaperPosition',[marg siz]); 
        print -dpsc
        set(gcf,'PaperPosition',pos); 
        delete(h);
elseif Inp == 82
        orient landscape
	ImgNo = round(get(h(1),'value'));
        h=text(mean(get(gca,'XLim')),...
               min(get(gca,'YLim'))-0.1*mean(get(gca,'YLim')),...
               ['Filename: ' get(gcf,'Name') ', Slice: ' num2str(ImgNo) ', with overlay']);
        set(h,'HorizontalAlignment','center');
        pos=get(gcf,'PaperPosition');
        marg=0.05*pos(3:4);
        siz=0.9*pos(3:4);
        set(gcf,'PaperPosition',[marg siz]); 
        print -dcdjcolor -Ppj1
        set(gcf,'PaperPosition',pos); 
        delete(h);
elseif Inp == 83
        % fprintf('\nSorry, Tiff image not implemented yet\n');
	hhh=get(gca,'Children');
	hh_image=-1;
	for ii=1:length(hhh),
	   if (strcmp(get(hhh(ii),'Type'),'image') == 1),
	      hh_image=hhh(ii);
	   end;   
	end;
	if (hh_image ~= -1)
	   img=get(hh_image,'CData');
	   col=colormap;
	   name_1=get(gcf,'Name');
	   Stop=0;
	   i=1;
	   while (Stop == 0)
	      name=sprintf('%s_ov_%i',name_1,i);
	      if (exist([name '.tif']) ~= 2)
	         Stop = 1;
	      end;
	      i=i+1;
	   end;
           ll=length(col);
           img=img.*(img<ll)+ll*(img>=ll);  
	   tiffwrite(img,col,name);
   	   fprintf('Tiff image %s written\n',name);
   	else
   	   fprintf('Did not find any image in current figure\n',name);
	end;
elseif Inp == 84
        % fprintf('\nSorry, PS image not implemented yet\n');
	hhh=get(gca,'Children');
	hh_image=-1;
	for ii=1:length(hhh),
	   if (strcmp(get(hhh(ii),'Type'),'image') == 1),
	      hh_image=hhh(ii);
	   end;   
	end;
	if (hh_image ~= -1)
	   img=get(hh_image,'CData');
	   col=colormap;
	   name_1=get(gcf,'Name');
	   Stop=0;
	   i=1;
	   while (Stop == 0)
	      name=sprintf('%s_ov_%i',name_1,i);
	      if (exist([name '.eps']) ~= 2)
	         Stop = 1;
	      end;
	      i=i+1;
	   end;
	   h=figure('Visible','off');
	   image(img);
	   colormap(col);
	   axis('square');
	   axis('off');
	   eval(['print -depsc ' name]);
	   delete(h);
   	   fprintf('ps image %s written\n',name);
   	else
   	   fprintf('Did not find any image in current figure\n',name);
	end;
elseif Inp == 85
        % fprintf('\nSorry, Tiff image not implemented yet\n');
        set(h,'ButtonDownFcn','');  
        
        load ShowImageColMap.txt
        NoOfOrgColors=length(ShowImageColMap);
        Colormap=get(gcf,'Colormap');
        NoOfOverlayColors=length(Colormap)-NoOfOrgColors;
        ImgNo = round(get(h(1),'value'));
           
        Name=get(gcf,'Name');
        OverlayNames=get(h(6),'UserData');
     
        hhh=get(gca,'Children');
        hh_image=-1;
        for ii=1:length(hhh),
           if (strcmp(get(hhh(ii),'Type'),'image') == 1),
              hh_image=hhh(ii);
           end;   
        end;
	      
        if (hh_image ~= -1),
           ImgLimits=get(hh_image,'UserData');
        else
           fprintf('ShowImageFuseFcn, No image in current figure\n');
	   exit(1);
        end;
     
	[pre,dim,siz,lim,scale,offset]=ReadAnalyzeHdr(Name);
	
	if (hh_image ~= -1)

	   for ImgNo=1:dim(3)
	     
	      [ImgFuse,ImgLim]=ShowImageFuseCalc(ImgNo,Name,OverlayNames,NoOfOrgColors,...
	         ImgLimits,NoOfOverlayColors);
      
              if (ImgFuse ~= [])
		 img=rot90(ImgFuse);
              else
                 fprintf('ShowImageFuseFcn, No image from ShowImageFuseCalc\n');
	         exit(1)
              end;  
	  
	      name=sprintf('%s_ov_sl%i',Name,ImgNo);
              ll=length(Colormap);
              img=img.*(img<ll)+ll*(img>=ll);  
	      tiffwrite(img,Colormap,name);
   	      fprintf('Tiff image %s written\n',name);
	   end;
	   
   	else
   	   fprintf('Did not find any image in current figure\n',name);
	end;
	
else
   fprintf('ShowImageFuseFcn no legal input to fcn\n');
end;     





