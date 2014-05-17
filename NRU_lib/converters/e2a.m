%
% e2a.m
%
% Converts ECAT 7 image to Analyze 7 image
% Uses: readECAT7.m (Raymond Muzic, 2002)
%       WriteAnalyzeImg.m (Claus Svarer, 2004, part of PVElab)
%
% Mark Lubberink, 050822
%
% Modifications
%
% 051007    ML      Now downsamples all files to 128x128x63 matrix
% 051103	ML     	If dimz>63 & dimx>128 assume MRI, do not downsample planes
%				    If dimz>63 downsample to 63 planes
%                   Asks for neurological or radiological orientation
%                   Changed limits in analyze header to comply with PVElab
% 051114	ML		Ask for new image dimensions
%                   Append dimensions and orientation to output filename
%

clear;
% Open input file
[pet_file,pet_path]=uigetfile('*.v','Load ECAT volume');

% Read ECAT file headers
[mh,sh]=readECAT7([pet_path pet_file]);

% Select dimensions of Analyze image
if sh{1}.z_dimension == 126 & sh{1}.x_dimension == 256
   choice=menu('Choose image dimensions, current is 256x256x126', ...
      '128x128x63','256x256x63','Keep as is');
   switch choice
   case 1
      x_scale=2;
      z_scale=2;
      output_tag='_128_63';
   case 2
      x_scale=1;
      z_scale=2;
      output_tag='_256_63';
   case 3
      x_scale=1;
      z_scale=1;
      output_tag='_256_126';
   end;
elseif sh{1}.z_dimension == 63 & sh{1}.x_dimension == 256
   choice=menu('Choose image dimensions, current is 256x256x63', ...
      '128x128x63','Keep as is');
   z_scale=1;
   switch choice
   case 1
      x_scale=2;
      output_tag='_128_63';
   case 2
      x_scale=1;
      output_tag='_256_63';
   end;
elseif sh{1}.z_dimension == 63 & sh{1}.x_dimension == 128
   z_scale=1;
   x_scale=1;
   output_tag='_128_63';
else
   disp('Dimensions of ECAT image not supported');
   break;
end;

% Select orientation
orient=menu('Choose orientation','Radiological','Neurological');
if orient==1
    output_tag=[output_tag '_R'];
else
    output_tag=[output_tag '_N'];
end;

% Select output file
dimarray={'_128_63_R','_256_63_R','256_126_R','128_126_R','_128_63_N','_256_63_N','256_126_N','128_126_N'};
while 1
    [ana_file,ana_path]=uiputfile([pet_path pet_file(1:length(pet_file)-2) '_e2a' output_tag '.img'],'Write analyze volume');
    ext=ana_file(length(ana_file)-12:length(ana_file)-4);
    if ~isempty(strmatch(ext,dimarray))
        break;
    else
        disp('Filename must end with ''xdim_zdim_N'' or ''xdim_zdim_R'' !');
    end;
end;
    
% Read all frames and resample
img_temp=zeros(sh{1}.x_dimension,sh{1}.y_dimension,sh{1}.z_dimension);
v=version;
if str2num(v(1))>=6
   h=waitbar(0,'Resampling frame 1');
else
   h=waitbar(0,'Resampling ...');
end;
for i=1:mh.num_frames
   [mh,sh,data]=readECAT7([pet_path pet_file],i);
   img_temp=flipdim(flipdim((double(cat(4,data{:}))*sh{1}.scale_factor*mh.ecat_calibration_factor),2),3);
   
   if x_scale==1 
      img_out=img_temp;
   else
      for z=1:sh{1}.z_dimension
         plane=img_temp(:,:,z);
         new_plane=interp2(1:256,1:256,plane,1.5:2:255.5,[1.5:2:255.5]');
         img_out(:,:,z)=new_plane;
      end;
   end;
   if z_scale==2
      for z=1:sh{1}.z_dimension/2;
         img_out_z(:,:,z)=0.5*img_out(:,:,z*2-1)+0.5*img_out(:,:,z*2);
      end;
      clear img_out;
      img_out=img_out_z;
      clear img_out_z;
  end;
  if i==1
      img=zeros(size(img_out,1),size(img_out,2),size(img_out,3),mh.num_frames);
  end;
  img(:,:,:,i)=img_out;
  if str2num(v(1))>=6
      waitbar(i/mh.num_frames,h,['Resampling frame ' num2str(i+1)]);
  else
      waitbar(i/mh.num_frames,h);
  end;
end;
close(h);
clear img_out;

% Flip if neurological (needed for PVElab) orientation
if orient==2
    img=flipdim(img,1);
end;

% Calculate scale factor for 16 bits integer data set
img_max=max(img(:));
img_min=min(img(:));
img_scale_factor=max(img_max,abs(img_min))/32767;
img=round(img/img_scale_factor);

% Define Analyze header
name=[ana_path ana_file]
dim(1)=sh{1}.x_dimension/x_scale;
dim(2)=sh{1}.y_dimension/x_scale;
dim(3)=sh{1}.z_dimension/z_scale;
dim(4)=mh.num_frames;
siz(1)=sh{1}.x_pixel_size*10*x_scale; % ECAT [cm], Analyze [mm]!
siz(2)=sh{1}.y_pixel_size*10*x_scale;
siz(3)=sh{1}.z_pixel_size*10*z_scale;
pre=16;
lim=[32767 -32768];
scale=img_scale_factor;
offset=0;
origin=[0 0 0];
descr=[pet_file pet_path];

% Because of error in CAPP software ask for z voxel size
if sh{1}.z_dimension==63 & sh{1}.z_pixel_size<0.2;
    choice=menu('Z and X voxel sizes are different; choose Z voxel size:',[num2str(siz(1)) ' (same as X)'],[num2str(siz(3)) ' (keep as is)']);
    if choice==1
	    siz(3)=siz(1);
    end;
end;

% Write analyze file
WriteAnalyzeImg(name,img,dim,siz,pre,lim,scale,offset,origin,descr);

% Create SIF file
while 1
    sifyn=menu('Create IDWC or SIF file?','IDWC','SIF','Both','No');
    if sifyn==4
        break;
    else
        answer=questdlg('The SIF and/or IDWC file will be based on image totals, not sinogram totals, and the resulting weighing factors will not be exactly correct!','','OK','Cancel','OK');
        if strcmp(answer,'Cancel')
           break;
        end;
        
        questdlg('Option not implemented yet','','OK','OK');
        break;
    end;
end;

    