function imgO=Reslice(Struct,method,sincparms);
%
% function imgO=Reslice(Struct,[method]);
%   
%   Function to reslice an Analyze image using 
%   affine 12-parameter transformation matrix.
%  
% Inputs:
%  
%   Struct has the fields
%   hdrI - input file Analyze header
%   hdrO - output file Analyze header
%   A - 12 parm. affine transformation matrix 
%       for application xyzO=A*xyzI. A is in 
%       real world (mm) coordinates.
%   [imgI] - optional field. If Struct has this field,
%            the input data are taken from here. Otherwise,
%            the image given in hdrI.name is loaded.
%   [imgO] - optional field. If Struct has this field, the output
%            is non-empty, and no datafile is written to disk.
%
%   method - defines what interpolation method to use. If none
%            is given, 'linear' is assumed.
%
% Output:
%   imgO - Output Analyze Img data. only non-empty if the field 
%          'imgO' exists in Struct.
%
%   Warning: Output is written to hdr0.name without checking.
%   Checking should be done beforehand, e.g. using uiputfile.
%   hdr.origin information is assumed correct.
%   
%   
%   Note: A third input parameter - sincparms - is unused, but 
%   needed for concistency whith ResliceWarp and ResliceAir
%
%   PW, NRU, 2001
%
% RESLICEDESC interp3 (Matlab)
% 
% Updates:
% Temporary file writing changed (did not work properly under linux). 161203TR
% 4D routines made windows compatible by using matlab fileroutines instead of unix. 161203TR
%
  
  if nargin<1
    error('Incorrect number of input parameters');
  elseif nargin==1 % no interpolation method specified, using linear
    method='linear';
    % Is this actually a call to determine interpolation methods
    % available?
    if ischar(Struct)
      if strcmp(Struct,'init');
	message={'linear','nearest','spline','cubic'};
	return
      else
	error(['Input argument ' Struct ' not understood!']);
      end
    end
  end
  % Check if we need to load any data
  Dim=1;
  if isfield(Struct,'imgI')
    simg=size(Struct.imgI);
    if length(simg)==3
      simg_perm=permute(simg,[2 1 3]);
    end
    % Different possible schemes:
    if simg(1)==prod(Struct.hdrI.dim) & simg(2)==1
      Struct.imgI=reshape(Struct.imgI,Struct.hdrI.dim');
      Struct.imgI=permute(Struct.imgI,[2 1 3]);
    elseif simg==Struct.hdrI.dim';
      Struct.imgI=permute(Struct.imgI,[2 1 3]);
    elseif simg_perm==Struct.hdrI.dim';
      % Do nothing
    else
      error(['The Struct.imgI given does not seem to fit its hdr dim' ...
	     ' information']);
    end
  else
    if length(Struct.hdrI.dim)==3 | ...
	  (length(Struct.hdrI.dim)==4 & Struct.hdrI.dim<2)
      Struct.imgI=ReadAnalyzeImg(Struct.hdrI.name,'raw');
      Struct.imgI=reshape(Struct.imgI,Struct.hdrI.dim');
      Struct.imgI=permute(Struct.imgI,[2 1 3]);
      Dim=1;
    else
      Dim=Struct.hdrI.dim(4);
    end
  end
  if Dim==1 % Simple, only one frame
    % Ready to do some work!
    % Set up the spaces
%    if ~any(Struct.hdrI.origin)
%      Struct.hdrI.origin=[1;1;1];
%    end
    if all(Struct.hdrI.origin==0)
      Struct.hdrI.origin=Struct.hdrI.origin+1;
    end     
    xI=Struct.hdrI.siz(1)*([1:Struct.hdrI.dim(1)]-Struct.hdrI.origin(1));
    yI=Struct.hdrI.siz(2)*([1:Struct.hdrI.dim(2)]-Struct.hdrI.origin(2));
    zI=Struct.hdrI.siz(3)*([1:Struct.hdrI.dim(3)]-Struct.hdrI.origin(3));
%    if ~any(Struct.hdrO.origin)
%      Struct.hdrO.origin=[1;1;1];
%    end
    if all(Struct.hdrO.origin==0)
      Struct.hdrO.origin=Struct.hdrO.origin+1;
    end     
    xO=Struct.hdrO.siz(1)*([1:Struct.hdrO.dim(1)]-Struct.hdrO.origin(1));
    yO=Struct.hdrO.siz(2)*([1:Struct.hdrO.dim(2)]-Struct.hdrO.origin(2));
    zO=Struct.hdrO.siz(3)*([1:Struct.hdrO.dim(3)]-Struct.hdrO.origin(3));
    [xI,yI,zI]=meshgrid(xI,yI,zI);
    [xO,yO,zO]=meshgrid(xO,yO,zO);
    % Transform the input coordinates:
    sizMesh=size(xO);
    xO=reshape(xO,1,prod(sizMesh));
    yO=reshape(yO,1,prod(sizMesh));
    zO=reshape(zO,1,prod(sizMesh));
    xyz=[xO;yO;zO;1+0*zO];
    xyz=inv(Struct.A)*xyz;
    xO=reshape(xyz(1,:),sizMesh);  
    yO=reshape(xyz(2,:),sizMesh);  
    zO=reshape(xyz(3,:),sizMesh);
    clear xyz;
    sizMesh=size(xO);

    % Do the interpolation:
    imgO=interp3(xI,yI,zI,double(Struct.imgI),xO,yO,zO,method);

    % Replace Nans with zero
    imgO(isnan(imgO))=0;

    imgO=permute(imgO,[2 1 3]);
    imgO=reshape(imgO,prod(size(imgO),1));
    if all(Struct.hdrO.origin==1)
      Struct.hdrO.origin=Struct.hdrO.origin-1;
    end     
    if not(isfield(Struct,'imgO'));
      WriteAnalyzeImg(Struct.hdrO,imgO);
      imgO=['Output written to ' Struct.hdrO.name];
    end
  else
    % Multi-frame data. Using Dyn2Frames / Frames2Dyn and recursive
    % calling of Reslice
    TmpStruct=Struct;
    File=tempname;
    [TEMP_AREA,File]=fileparts(File);
    if isempty(TEMP_AREA)
        TEMP_AREA=Struct.hdrO.path;
    end
    File=fullfile(TEMP_AREA,File);
    [status,output]=copyfile(fullfile(Struct.hdrI.path,[Struct.hdrI.name,'.hdr']), [File '.hdr'], 'f');
    [status1,output1]=copyfile(fullfile(Struct.hdrI.path,[Struct.hdrI.name,'.img']), [File '.img'], 'f');
    if status==1 & status1==1
        PW=pwd;
        cd(TEMP_AREA);
        disp('Splitting the data into frames...');
        ConvertDyn2Frames(File)
        TmpStruct.hdrI.dim(4)=[];
        TmpStruct.hdrO.dim(4)=[];
        [tPath,tFile,Exten]=fileparts(File);
        for j=1:Dim
            if j<10
                jstr=['0' num2str(j)];
            else
                jstr=num2str(j);
            end
            TmpStruct.hdrI.name=[File '_f' jstr];
            TmpStruct.hdrO.name=fullfile(tPath,['r_' tFile '_f' jstr]);
            disp(['Reslicing frame ' num2str(j) ' of ' num2str(Dim)]);
            Reslice(TmpStruct);
        end
        [tPath,tFile]=fileparts(File);
        disp('Collecting the resliced frames...');
        ConvertFrames2Dyn(['r_' tFile '_f01']);
        % Move the resulting file to original, wanted place
        cd(PW);
        %[Path,Name]=fileparts(Struct.hdrO.name);
        Name=Struct.hdrO.name;
        Path=Struct.hdrO.path;
        [status,output]=movefile(fullfile(TEMP_AREA,['r_' tFile '.hdr']),...
                fullfile(Path,[Name,'.hdr']),'f');
        [status1,output1]=movefile(fullfile(TEMP_AREA,['r_' tFile '.img']),...
                fullfile(Path,[Name,'.img']),'f');
        if status==1 & status1==1
            %Also copy NRU timefile if exist
            if exist(fullfile(Struct.hdrI.path,[Struct.hdrI.name,'.tim']))
                [status2,output2]=copyfile(fullfile(Struct.hdrI.path,[Struct.hdrI.name,'.tim']), fullfile(Path,[Name,'.tim']),'f');
            end
 
            % Do cleanup
            delete([File '_f*']);
            delete(fullfile(TEMP_AREA,['r_' tFile '*']));
            delete([File '*']);
        else
            error(['Final mv failed: ' output ' ' output1]);
        end
    else
        error(['Link creation failed: ' output ' ' output1]);
    end
    imgO=[];
  end
  
  








