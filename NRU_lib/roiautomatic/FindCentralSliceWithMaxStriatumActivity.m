function Center_for_5cons_StriatumROIslices = FindCentralSliceWithMaxStriatumActivity(filename)

% This function identifies that slice in the input SPECT image which makes
% up the central slice for five consequtive slices with highest mean
% activity in the two striatum ROI volumes

% Loading image and corresponding striatum ROI volumes
[img,hdr] = ReadAnalyzeImg(filename);
[VOI_stri_dex,VOI_stri_dex_hdr] = ReadAnalyzeImg('VOIStriatumdex');
[VOI_stri_sin,VOI_stri_sin_hdr] = ReadAnalyzeImg('VOIStriatumsin');

% Reshaping image and ROI volumes to 3D
img_3d = reshape(img,hdr.dim');
VOI_stri_dex_3d = reshape(VOI_stri_dex,VOI_stri_dex_hdr.dim');
VOI_stri_sin_3d = reshape(VOI_stri_sin,VOI_stri_sin_hdr.dim');

% Find the number of the slice where the mean activity in the left and
% right striatum ROI volumes is maximum
VOI_stri_3d = VOI_stri_dex_3d+VOI_stri_sin_3d;
img_only_stri_3d = img_3d.*VOI_stri_3d;
Nums_slices = size(VOI_stri_3d,3);

Slice_Region_Sum = squeeze(sum(sum(img_only_stri_3d,1),2));
Slice_Region_Vol = zeros(Nums_slices,1);
for i = 1:Nums_slices;
    Slice_Region_Vol(i) = length(find(VOI_stri_3d(:,:,i)>0));
end
warning('off','MATLAB:divideByZero');
Slice_Region_Mean = Slice_Region_Sum./Slice_Region_Vol;
warning('on','MATLAB:divideByZero');
Slice_Max = find(Slice_Region_Mean == max(Slice_Region_Mean));

% Based on the this slice number, identify which slice to use as the
% central slice for five consequtive slices with maximum mean striatum
% activity
Center_for_5cons_StriatumROIslices = Slice_Max;
if Slice_Region_Mean(Slice_Max-2)<Slice_Region_Mean(Slice_Max+3)
    Center_for_5cons_StriatumROIslices = Slice_Max+1;
end
if Slice_Region_Mean(Slice_Max-1)<Slice_Region_Mean(Slice_Max+4)
    Center_for_5cons_StriatumROIslices = Slice_Max+2;
end
if Slice_Region_Mean(Slice_Max+2)<Slice_Region_Mean(Slice_Max-3)
    Center_for_5cons_StriatumROIslices = Slice_Max-1;
end
if Slice_Region_Mean(Slice_Max+1)<Slice_Region_Mean(Slice_Max-4)
    Center_for_5cons_StriatumROIslices = Slice_Max-2;   
end

% Subtract 1 from slice number in order to compensate for the way editroi
% treats the slice number
Center_for_5cons_StriatumROIslices = Center_for_5cons_StriatumROIslices-1;