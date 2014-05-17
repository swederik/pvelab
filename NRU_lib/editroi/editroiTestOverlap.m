function [RoiOverlap]=editroiTestOverlap(EditroiInFN,HdrFile)
%
%  Test for overlap between ROI's defined in a editroi file
%
%  [RoiOverlap]=
%             editroiTestOverlap(EditroiInFN,HdrFile)
%
%    EditroiInFN  - name of editroi file to test for overlap in ROI's
%    HdrFile      - Header file describing volume that EditroiInFN is
%                    applied to
%
%    RoiOverlap   - Overlap in percentage for each ROI
%
% CS, 20120330, Vers. 1
%
if (nargin ~= 2)
    error('editroiTestOverlap function has to be called with 1 right handside arguments');
end
%
[Result,RoiVolume,RoiDescription]=editroi2analyze(EditroiInFN,HdrFile,'',1);
%
bits=uint64(zeros(numel(RoiVolume),64));
Voxels=zeros(64,1);
MaxRoi=0;
parfor i=1:64
    fprintf('Deciding if ROI no. %i is used\n',i);
    bits(:,i)=bitget(RoiVolume(:),i);
    Voxels(i)=sum(double(bits(:,i)));
    if Voxels(i)>0
        RoiUsed(i)=i;
    end
end
%
MaxRoi(1)=max(RoiUsed);
if MaxRoi>0
    RoiOverlapTmp=zeros(64,1);
    for i=1:64
        if Voxels(i)>0
            fprintf('Calculating overlap for ROI no. %i\n',i);
            %OtherRoi{i}=any(bits(:,[1:i-1 i+1:64]),2);
            %OverlapVoxels(i)=sum(OtherRoi{i}(bits(:,i)==1));
            OverlapVoxels=sum(any(double(bits((bits(:,i)==1),[1:i-1 i+1:64])),2));
            RoiOverlapTmp(i)=OverlapVoxels/Voxels(i);
        end
     end
    RoiOverlap=RoiOverlapTmp(1:MaxRoi);
else
    RoiOverlap=[];
end
