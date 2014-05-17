function [result]=editroiGenCommonRois(FilesToUse,HdrFile,CommonRoiName,...
    FilterSpec,Precision,MaxIter)
%
% [result]=editroiGenCommonRois([FilesToUse,HdrFile,CommonRoiName,...
%                               [FilterSpec,Precision,MaxIter]])
%
% Program that generates a set of common rois from a set of ROIs
%
%   FilesToUse - List of files to generate common ROI volume from 
%                (cell array with text strings of file names) 
%   HdrFile    - Name of header file describing the size of the volume
%                (e.g. the MR file)
%   CommonRoiName - Name of the ROI set generated
%   FilterSpec - Specification of used Gaussian filter in mm (e.g. [4 4 4] mm)
%   Precision  - % max error in ROI volume compared to mean ROI volume for all
%                 selected ROI sets (e.g. 0.5)
%   MaxIter    - Maximum number of iterations used to achieve precision
%                 (e.g. 20)
%   
%   The parameters Precision and MaxIter is set to default
%   values (mentioned above) if the algorithm is called without any
%   parameters. FilterSpec is set to [1 1 1]*max(hdr.siz) if unspecified
%
%   result - 1 if no problem, 0 if problem with one or more files
%
% CS, 20021204
%
result=1;
%
if (nargin ~=0) & (nargin ~= 3) & (nargin~= 6)
    error('editroiGenCommonRois has to be called with 0, 3 or 6 paramters');
end
%
if (nargin==0)
    Tmp=pwd;
    [FilesToUse,res,filter_out,hout] = ...
        ui_choosefiles(Tmp, '*.mat', ...
        'editroi ROIs to use?');
    delete(hout);
    cd(Tmp);
    if (res == -1)  
        warning('No editroi files selected');
        result=0;
        return
    end
    [FILENAME, PATHNAME] = uigetfile('*.hdr','Volume example header');
    if (FILENAME==0)
        warning('No header file selected')
    end  
    HdrFile=[PATHNAME FILENAME];
    [FILENAME, PATHNAME] = uiputfile('*.mat','Name of common ROI set');
    if (FILENAME==0)
        warning('No common ROI set name selected')
    end  
    CommonRoiName=[PATHNAME FILENAME];
end
%
if (nargin == 0) | (nargin == 3)
    Hdr=ReadAnalyzeHdr(HdrFile);
    FilterSpec=[1 1 1]*max(Hdr.siz);    % Gaussian filter of rois with 4x4x4 mm FWHM
    Precision=0.5;                      % max 0.5% error in mean ROI volume
    MaxIter=20;                         % Maximum number of iterations  
end  
%
if isstr(FilesToUse)
    FilesToUse={FilesToUse};
end  
%
RoiHdr=ReadAnalyzeHdr(HdrFile);
RoiVolume=zeros(length(FilesToUse),prod(RoiHdr.dim(1:3)),'uint64');
%
for i=1:length(FilesToUse);
    fprintf('Reading ROI file: %s\n',FilesToUse{i});
    %
    [Result,TmpRoiVolume,RoiDescription{i}]=...
        editroi2analyze(FilesToUse{i},RoiHdr,[],1);
    RoiVolume(i,:)=uint64(TmpRoiVolume(:)');	  
    if (Result~=1)
        warning(sprintf('Problem with ROI defined in %s',FilesToUse{i})); 
        result=0;
    end	      
end  
%
NoOfRois=length(RoiDescription{1});
%
for i=1:NoOfRois
    Threshold(i).Iter=MaxIter;
    Threshold(i).Prec=Precision;
    Threshold(i).Vol=mean(sum(double(bitget(RoiVolume,i)),2));
end
%
parfor i=1:NoOfRois
    RoiName=RoiDescription{1}{i};
    fprintf('\n\nCreates propability map for ROI(%i):, %s\n',i,RoiName);
    RoiVolSel=sum(double(bitget(RoiVolume,i)),1)/length(FilesToUse);
    %
    [Result,Roi]=analyze2editroi(RoiVolSel,RoiHdr,{RoiDescription{1}{i}},...
            FilterSpec,Threshold(i));
    %	
    RoiTotalTmp{i}.regionname=RoiName;
    for j=1:length(Roi.vertex);
        RoiTotalTmp{i}.vertex{j}=Roi.vertex{j};
        RoiTotalTmp{i}.mode{j}=Roi.mode{j};
        RoiTotalTmp{i}.region(j)=i;
        RoiTotalTmp{i}.relslice(j)=Roi.relslice(j);
    end  
end
%
RoiNumber=1;
for i=1:length(RoiTotalTmp)
    RoiTotal.regionname{i,1}=RoiTotalTmp{i}.regionname;
    for j=1:length(RoiTotalTmp{i}.vertex)
        RoiTotal.vertex{RoiNumber,1}=RoiTotalTmp{i}.vertex{j};
        RoiTotal.mode{RoiNumber,1}=RoiTotalTmp{i}.mode{j};
        RoiTotal.region(RoiNumber,1)=RoiTotalTmp{i}.region(j);
        RoiTotal.relslice(RoiNumber,1)=RoiTotalTmp{i}.relslice(j);
        RoiNumber=RoiNumber+1;
    end
end
RoiTotal.slicedist=RoiHdr.siz(3);
RoiTotal.filetype='EditRoiFile';
%
SaveRoi(CommonRoiName,RoiTotal);










