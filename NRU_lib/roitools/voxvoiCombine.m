function voxvoiCombine(VOIfiles,CombinedVOIfile)
%
% voxvoiCombine([VOIfiles,CombinedVOIfile])
%
% Function that combines a set of VOI files into one based on the maximum probability measure
%
%  VOIfiles - Cell array of names of analyze files that should be combined
%  CombinedVOIfiles - Name of VOI files that should be used for the
%                      combined VOIs
%
if (nargin~=0) && (nargin~=2)
    error('voxvoiCombine has to be called with zero or two input arguments');
elseif (nargin == 0)
    [filename, pathname, filterindex] = uigetfile( ...
        {'*.img','Analyze image files';}, ...
        'Pick files to include', ...
        'MultiSelect', 'on');
    if isequal(filename,0) || isequal(pathname,0)
        error('voxvoiCombine: Some voxel VOI files has to be selected');
    else
        for i=1:length(filename)
            VOIfiles{i}=fullfile(pathname,filename{i});
        end
    end
    %
    [filename, pathname, filterindex] = uiputfile( ...
        {'*.img','Analyze image files';}, ...
        'File name to use for saving VOIs');
    if isequal(filename,0) || isequal(pathname,0)
        error('voxvoiCombine: A file name has to be specified for output');
    else
        CombinedVOIfile=fullfile(pathname,filename);
        
    end
end
%
% The routine starts here
%
for i=1:length(VOIfiles)
    fprintf('Reading file: %s\n',VOIfiles{i});
    [img,hdr]=ReadAnalyzeImg(VOIfiles{i},'raw');  
    MaxImg=max(img);
    if (MaxImg>255)
        error('CombineVOIfiles: Less than 255 different regions in a file is supported');
    end
    if i==1  %Initialization of arrays
        ImgIn=zeros(prod(hdr.dim),length(VOIfiles),'int16');
        NoInClass=zeros(MaxImg,length(VOIfiles));
    end
    ImgIn(:,i)=int16(img);
    %
    % Finding out how many voxels in each class
    %
    for j=1:MaxImg
        NoInClass(j,i)=length(find(img==j));
    end
end
%
% Decide how many voxels should be in each class as the mean of the
% transferred VOIs
%
NoInEachClass=round(mean(NoInClass,2));
NoInVOIs=sum(mean(NoInClass,2));
%
% Creating probability map
%
for i=1:MaxImg
    if i==1
        ImgProb=zeros(prod(hdr.dim),MaxImg,'uint8');
    end
    ImgProb(:,i)=sum((ImgIn==i),2);
end
%
% Generating mask from all VOIs of highest prob voxels
%
ImgProbSum=double(reshape(sum(ImgProb,2),hdr.dim'));
ImgProbSumf=gauss_vol(ImgProbSum,hdr.siz',[1 1 1]*sqrt((max(hdr.siz)^2)*2),4);
%ImgProbSumf=ImgProbSum;
%    
Thres=0.5*max(ImgProbSumf(:));
DiffThres=Thres/2;
Iter=1;
Stop=0;
fprintf('No of voxels in VOI volume %i\n',NoInVOIs);
while Stop==0
    Ind=(ImgProbSumf(:)>=Thres);
    ActNo=sum(Ind);
    %
    % Less than 0.1 % error or more than 30 iterations
    %
    Err=(ActNo-NoInVOIs)/NoInVOIs;
    if (abs(Err)<0.0001) || (Iter>30)
        Stop=1;
    end
    fprintf('   %i: Actual no of voxels: %i (Thres: %6.3f, Err: %6.4f)\n',Iter,ActNo,Thres,Err);
    %
    if ActNo>NoInVOIs
        Thres=Thres+DiffThres;
    else
        Thres=Thres-DiffThres;
    end
    DiffThres=DiffThres/2;
    Iter=Iter+1;
end
ImgMask=zeros(prod(hdr.dim),1,'uint8');
ImgMask(Ind)=1;
%
% Threshold to correct number of voxels for each class
%
%
% First deciding which VOIs are bigest and assuming they have highest threshold
%
[VOIsize,VOIind]=sort(NoInEachClass,1,'ascend');
%[VOIsize,VOIind]=sort(NoInEachClass,1,'descend');
%
ImgOut=zeros(prod(hdr.dim),1,'uint8');
for i=1:MaxImg,
    Stop=0;
    img=double(reshape(ImgProb(:,VOIind(i)),hdr.dim'));
    imgf=gauss_vol(img,hdr.siz',[1 1 1]*sqrt((max(hdr.siz)^2)*2),4);
    %imgf=img;
    imgf((ImgMask==0)|(ImgOut~=0))=0;
    Thres=0.5*max(imgf(:));
    DiffThres=Thres/2;
    Iter=1;
    fprintf('VOI %i (Wanted no of voxels %i)\n',i,VOIsize(i));
    while Stop==0
        Ind=(imgf(:)>=Thres);
        ActNoInClass=sum(Ind);
        %
        % Less than 0.1 % error or more than 30 iterations
        %
        Err=(ActNoInClass-VOIsize(i))/VOIsize(i);
        if (abs(Err)<0.0001) || (Iter>30)
            Stop=1;
        end
        fprintf('   %i: Actual no of voxels: %i (Thres: %6.3f, Err: %6.4f)\n',Iter,ActNoInClass,Thres,Err);
        %
        if ActNoInClass>VOIsize(i)
            Thres=Thres+DiffThres;
        else
            Thres=Thres-DiffThres;
        end
        DiffThres=DiffThres/2;
        Iter=Iter+1;
    end
    ImgOut(Ind)=VOIind(i);
    fprintf('VOI %i: No of voxels: %i (Mean from VOI files: %i)\n',i,sum(ImgOut==VOIind(i)),VOIsize(i));
end
%
% Write results to file
%
[pn,fn,ext]=fileparts(CombinedVOIfile);
hdrOut=hdr;
hdrOut.name=fn;
hdrOut.path=pn;
hdrOut.pre=16;
hdrOut.lim=[32767 -32768];
hdrOut.scale=1;
hdrOut.offset=0;
WriteAnalyzeImg(hdrOut,ImgOut);
%
% Copy label file if exist
%
[pn,fn,ext]=fileparts(VOIfiles{1});
DescrIn=fullfile(pn,[fn '.descr']);
[pn,fn,ext]=fileparts(CombinedVOIfile);
DescrOut=fullfile(pn,[fn '.descr']);
if exist(DescrIn,'file')==2
    copyfile(DescrIn,DescrOut);
end
