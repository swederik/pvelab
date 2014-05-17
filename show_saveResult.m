function project=show_saveResult(project,TaskIndex,MethodIndex,varargin)
% show_saveResult function is a simpel way to converte few slices of a brain image to 
%   a bitmap or like. Converted images can be shown in the DisplayWindow in the pipeline program.
%   Brain images must be in the Analyze format filenames found in 'project.taskDone.outputfiles'. 
%   Image info are saved in 'project.taskDone{TaskIndex}.show'
%
% Input:
%   project     : Structure containing all information of actual pipeline
%   TaskIndex   : Index to active task in the project structure
%   MethodIndex : Index to used method in a TaskIndex in the project structure
%   varargin{1} : Output format of image: 'bmp', 'fig', 'jpg' or 'png' (DEFAULT='png')
%
% Output:
%   project     : Return updated project       
%
% Uses special functions:
%   [img,hdr]=ReadAnalyzeImg(name) 
%   supercolorbar
%   logProject
%____________________________________________
% T. Rask og T. Dyrby, 010403, NRU
%
%SW version: 201103TR,TD

%_________ Which format to save the figures to shown in progress/result window
if(nargin==4)
    outputformat=varargin{1};        
    switch outputformat
    case {'bmp','fig','jpg'}
        
    otherwise
        outputformat='png';    
    end
else
    outputformat='png';    
end

ImageIndex=project.pipeline.imageIndex(1);

 
scrsz = get(0,'ScreenSize');
h_subfig=figure('resize','off','position',[50 50 scrsz(3)-100 scrsz(4)-100],'visible','off');
%set(h_subfig,);
%set(h_subfig,'visible','off'); %This line cannot run in windows

%_______Find out if there is anything to show already
showNumber=1;
howbig=size(project.taskDone{TaskIndex}.show);
for (i=1:howbig(2))
    if ~isempty(project.taskDone{TaskIndex}.show{ImageIndex,i}.name)
        showNumber=showNumber+1;
    end
end

%_______ Get loaded number of modalities (= number of outputfile fields)
noModalities=length(project.pipeline.imageModality);
%_______Run through outputfiles
for(ModalityIndex=1:noModalities)    
    filename=fullfile('',project.taskDone{TaskIndex}.outputfiles{ImageIndex,ModalityIndex}.path,project.taskDone{TaskIndex}.outputfiles{ImageIndex,ModalityIndex}.name);
    fid=fopen(filename,'r');
    if(fid>0)
        fclose(fid);
        %_________ Show results
        Title_msg=project.taskDone{TaskIndex}.outputfiles{ImageIndex,ModalityIndex}.name; 
         
        MakeShow(h_subfig,filename,Title_msg);
        
        %_________ Save results as Matlab fig
        [file_pathstr,file_name,file_ext]=fileparts(filename);
        info='';
        if (~isempty(project.taskDone{TaskIndex}.outputfiles{ImageIndex,ModalityIndex}.info) &...
                ~isstruct(project.taskDone{TaskIndex}.outputfiles{ImageIndex,ModalityIndex}.info))
            info=[project.taskDone{TaskIndex}.outputfiles{ImageIndex,ModalityIndex}.info,' - ']
        end
        
        project.taskDone{TaskIndex}.show{ImageIndex,showNumber}.name=fullfile('',['Show-',project.pipeline.taskSetup{TaskIndex,MethodIndex}.task,'_',file_name,'.',outputformat]);
        project.taskDone{TaskIndex}.show{ImageIndex,showNumber}.path=project.sysinfo.workspace;
        project.taskDone{TaskIndex}.show{ImageIndex,showNumber}.info=[info,'Image generated from ',Title_msg];
        filenameShow=fullfile('',project.taskDone{TaskIndex}.show{ImageIndex,showNumber}.path,project.taskDone{TaskIndex}.show{ImageIndex,showNumber}.name);
        showNumber=1+showNumber;
        
        %figure(h_subfig); %Bring figure to be current
	%set(h_subfig,'visible','off');
       
        %Only save if workspace is know. Not alwas the case of fileload
        if(~isempty(project.sysinfo.workspace))
            %print('-dpng','-r500',filenameShow)%save as tiff
            saveas(h_subfig, fullfile('',filenameShow),outputformat);    
        end     
    end
end%ModalityIndex

%Find Imagefiles in userdata field
ud=struct2entries(['project.taskDone{',num2str(TaskIndex),'}.userdata'],project.taskDone{TaskIndex}.userdata);
l=length(ud);
for i=1:l
    f1=strfind(lower(ud{i}.entry),'.name');
    if f1
        for j=-2:2 %look two forward and backwards after path
            if ((i+j)>0 & (i+j)<=l)
                f2=strfind(lower(ud{i+j}.entry),'.path');
                if f2
                    cmp=strcmp(ud{i}.entry(1:f1),ud{i+j}.entry(1:f2));
                    if (cmp & ~isempty(eval(ud{i}.entry)))
                        file=fullfile('',eval(ud{i+j}.entry),eval(ud{i}.entry));
                        [pa,name,ext]=fileparts(file);
                        if strcmp(lower(ext),'.img')
                            fid=fopen(file,'r');
                            if(fid>0)
                                fclose(fid);

                                %_____ Find info
                                info='';
                                for k=-2:2 %look two forward and backwards after info
                                    if ((i+k)>0 & (i+k)<=l)
                                        f3=strfind(lower(ud{i+k}.entry),'.info');
                                        if f3
                                            cmp=strcmp(ud{i}.entry(1:f1),ud{i+k}.entry(1:f3));
                                            if cmp & ~isempty(eval(ud{i+k}.entry))
                                                info=[eval(ud{i+k}.entry),' - '];
                                            end
                                        end
                                    end
                                end
                               
                                %_________ Show results
                                Title_msg=[name,ext];
                                
                                MakeShow(h_subfig,file,Title_msg);
                                
                                %_________ Save results as Matlab fig
                                project.taskDone{TaskIndex}.show{ImageIndex,showNumber}.name=fullfile('',['Show-',project.pipeline.taskSetup{TaskIndex,MethodIndex}.task,'_',name,'.',outputformat]);
                                project.taskDone{TaskIndex}.show{ImageIndex,showNumber}.path=project.sysinfo.workspace;
                                project.taskDone{TaskIndex}.show{ImageIndex,showNumber}.info=[info,'Image generated from ',Title_msg];
                                filenameShow=fullfile('',project.taskDone{TaskIndex}.show{ImageIndex,showNumber}.path,project.taskDone{TaskIndex}.show{ImageIndex,showNumber}.name);
                                showNumber=1+showNumber;
                                
                                %figure(h_subfig); %Bring figure to be current
			        %set(h_subfig,'visible','off');
                                
                                %Only save if workspace is know. Not alwas the case of fileload
                                if(~isempty(project.sysinfo.workspace))
                                    %print('-dpng','-r500',filenameShow)%save as tiff
                                    saveas(h_subfig, fullfile('',filenameShow),outputformat);    
                                end     
                            end
                        end
                    end
                end
            end
        end
    end
end
           
close(h_subfig);
return %show_saveResult

% _____ Add to pdf or postscript
% 
% %print('-dtiff','-r200',imagefile)%save as tiff
% %Cimage=imread(imagefile,'png');%load tiff for later use    
% %delete([imagefile,'.tif']);%Delete tmpfile    
% %figure(h_showImg),hold on;
% %subplot(length(filenames),1,i), image(Cimage), axis off, axis tight;
% close(h_fig);
% 
% %__________ print to pdf
% %set(h_showImg,'Papertype','A4')
% %print(gcf,'-dpdf',filenameShowRes);





function h_fig=MakeShow(h_fig,filenames,Title_msg)
% NOT FINISH BUT WORKs!!!! 230503TD
% Setup what to show slides and orientation
%
% Input:
% h_fig: Handles to figure where to draw
% filenames: cell array of filenames in analyseformat
%    filenames{1}=inputfilename
%    filenames{2}=outputfilename
% title_msg: cellarray w. title for each filename
%
% Output:
%   h_fig: handle to figure where result is shown
%________________________________________________________
% SW label: 070404TD, NRU

%__________ Slices to show
slcShowPerc=[0.5];
timeframePerc=0.5; %if 4D.
x=length(filenames);


%__________ Load image with given slides
[img,hdr]=ReadAnalyzeImg(filenames);

img=reshape(img,double(hdr.dim'));

if length(hdr.dim)>3 & hdr.dim>1
    timeframe=ceil(hdr.dim(4)*timeframePerc);
    Title_msg=[Title_msg,'-frame ',num2str(timeframe)];
else
    timeframe=1;
end
    
    
img1=squeeze(img(ceil(slcShowPerc.*hdr.dim(1)),:,:,timeframe));
img2=squeeze(img(:,ceil(slcShowPerc.*hdr.dim(2)),:,timeframe));
img3=img(:,:,ceil(slcShowPerc.*hdr.dim(3)),timeframe);

[scale_min,scale_max,imgType]=findLim(img(:,:,:,timeframe));%subfunction to scale intensities/counts
clear img;

if(strcmp(imgType,'MR')) %Select color for MR or PET
    colo='gray';
else 
    colo='hot';
end

x=hdr.dim(1)*hdr.siz(1); %Picture dimensions
y=hdr.dim(2)*hdr.siz(2);
z=hdr.dim(3)*hdr.siz(3);

%scale axes to fit images
if y>x, xa=y; else xa=x; end;
if z>y, ya=z; else ya=y; end;

%_____ First axes
h1=subplot('position',[0.01 0.51 0.48 0.48]);

imagesc([0,x],[0,z],img2',[scale_min, scale_max]);
set(gca,'xlim',[(x-xa)/2 x-(x-xa)/2],'ylim',[(z-ya)/2 z-(z-ya)/2],'xaxislocation','top','yaxislocation','left');
axis xy; 
axis off;
axis equal;
% xlabel('X');
% ylabel('Z');



%_____ Second axes
h2=subplot('position',[0.51 0.51 0.48 0.48]);
imagesc([0,y],[0,z],img1',[scale_min, scale_max]); 
set(gca,'xlim',[(y-xa)/2 y-(y-xa)/2],'ylim',[(z-ya)/2 z-(z-ya)/2],'xaxislocation','top','yaxislocation','right');
axis xy; 
axis off;
axis equal;
% xlabel('Y');
% ylabel('Z');


%_____ Third axes
h3=subplot('position',[0.01 0.01 0.48 0.48]);
imagesc([0,x],[0,y],img3',[scale_min, scale_max]); 
set(gca,'xlim',[(x-xa)/2 x-(x-xa)/2],'ylim',[(y-ya)/2 y-(y-ya)/2],'xaxislocation','bottom','yaxislocation','left');
axis xy; 
axis off;
axis equal;
% xlabel('X');
% ylabel('Y');


%_____ Fourth axes
h4=subplot('position',[0.51 0.01 0.48 0.48]);
img4(1,1)=scale_min;
img4(2,2)=scale_max;
h_joke=imagesc(img4,[scale_min, scale_max]); %There have to be an image, else the colorbar wont have the right limits
axis([0 1 0 1]);
axis xy; 
axis off;
set(h_joke,'visible','off');

%______ Set text
h_title=text(0,1,Title_msg,'fontsize',15,'fontweight','bold','interpreter','none');
text(0,0.9,['Description:'],'fontsize',15);
text(0,0.8,['"',hdr.descr,'"'],'fontsize',15,'interpreter','none');
if length(hdr.dim)>3
    text(0,0.7,['Dimensions: ',num2str(hdr.dim(1)),'x',num2str(hdr.dim(2)),'x',num2str(hdr.dim(3)),'x',num2str(hdr.dim(4))],'fontsize',15);
else    
    text(0,0.7,['Dimensions: ',num2str(hdr.dim(1)),'x',num2str(hdr.dim(2)),'x',num2str(hdr.dim(3))],'fontsize',15);
end
text(0,0.6,['Voxel size [mm]:'],'fontsize',15);
text(0,0.5,[num2str(hdr.siz(1)),'x',num2str(hdr.siz(2)),'x',num2str(hdr.siz(3))],'fontsize',15);
text(0,0.4,['Color depth: ',num2str(hdr.pre),'bit'],'fontsize',15);
text(0,0.3,['Color limits: ',num2str(hdr.lim(2)),' to ',num2str(hdr.lim(1))],'fontsize',15);
text(0,0.2,['Origin: ',num2str(hdr.origin(1)),'x',num2str(hdr.origin(2)),'x',num2str(hdr.origin(3))],'fontsize',15);
text(0,0.1,['Offset: ',num2str(hdr.offset),'    Scale: ',num2str(hdr.scale)],'fontsize',15);
text(0,0.01,['Endian: ',hdr.endian],'fontsize',15,'interpreter','none');

colormap(colo);
h_bar=colorbar('vert','peer',h4); % set colormap
posi=get(h_bar,'position');
posi(1)=posi(1)-0.05;
set(h_bar,'position',posi);

%get(h_bar);
return %MakeShow
