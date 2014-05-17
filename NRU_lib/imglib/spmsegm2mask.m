function [Result]=spmsegm2mask(PreMRName,GMprob,WMprob,CSFprob,FilesToGenerate)
%
%  Convert a set of segmented MR images (SPM segmentation) to a mask and one
%  file containing a segmentation 0 - BG, 1 - CSF, 2 - GM, 3 - WM, 4 - Fat.
%
%  [Result]=spmsegm2mask([PreMRName,[GMprob,WMprob,CSFprob,[FilesToGenerate]]])
%
%    PreMRName   - First part of the name of the segmented MR files (output
%                   from SPM). Segmented output from SPM append a '_seg1' to
%                   the file name, or in spm5 format like 'c1...'
%    GMprob      - Probability map for GM (e.g. PreMRName_seg1)
%    WMprob      - Probability map for WM (e.g. PreMRName_seg2)
%    CSFprob     - Probability map for CSF (e.g. PreMRName_seg3)
%                   BG probability map is generated as SegBG=1-(GMprob+WMprob+CSFprob);
%    FilesToGenerate - String with values '000' (no files generated) '111'
%                       (all files generated) and other values some files
%                       generated
%                       File 1 - _mask file which has a 0, 1 mask for the
%                                the brain mask (GM and WM voxels)
%                       File 2 - _masked including the original MR image masked with the brain
%                                mask
%                       File 3 - _GM_WM with CSF voxels set to 1,
%                                GM voxels set to 2, WM voxels set to 3 and the rest set to 0.
%    If Seg files not specified (or empty), they are generated from the PreMRName and
%    if FileToGenerate is unspecified it is assumed to be '111'
%
%    Result       - Error argument (1 for success, 0 for failure)
%
% CS, 030227, Vers. 1
%
Result=1;
if (nargin ~= 0) && (nargin ~=1) && (nargin ~=4) && (nargin ~=5)
    error('editroi2pve function has to be called with either 0, 1, 4 or 5 right handside arguments');
end
if (nargout > 1)
    error('editroi2analyze function has to be called with 0 to 1 left handside arguments');
end
%
if (nargin == 0)
    [PreMRNameFN, PreMRNamePN  ] = uigetfile('*.img', ...
        'Name of MR original file (eventually _seg? file from SPM)');
    if (PreMRNameFN==0)
        error('A MR file has to be selected');
    end
    PreMRName=[PreMRNamePN PreMRNameFN];
end
[pn,fn,ext]=fileparts(PreMRName);
if isempty(pn)
    PreMRName=fn;
else
    PreMRName=[pn filesep fn];
end
pos=strfind(PreMRName,'_seg');
if ~isempty(pos)
    PreMRName=PreMRName(1:pos(1)-1);
end
if (nargin < 4) || isempty(GMprob)
    GMprob=[PreMRName '_seg1' '.img'];
    WMprob=[PreMRName '_seg2' '.img'];
    CSFprob=[PreMRName '_seg3' '.img'];
    if exist(GMprob)~=2   % SPM5 format
        [pn,fn]=fileparts(PreMRName);
        GMprob=fullfile(pn,['c1' fn '.img']);
        WMprob=fullfile(pn,['c2' fn '.img']);
        CSFprob=fullfile(pn,['c3' fn '.img']);
   end
end
if exist(GMprob)~=2   % neither SPM2 nor SPM5 format
    Result=0;
    return;
end
%
if (nargin < 5)
    FilesToGenerate='111';
end
if ~isstr(FilesToGenerate) || (length(FilesToGenerate) ~= 3)
    fprintf('Fifth argument FilesToGenerate has to be a string of length 3, assumed to be "111"'\n);
    FilesToGenerate='111';
end
%
[imgOrg,hdrOrg]=ReadAnalyzeImg(PreMRName,'raw'); % Original brain
%
[img1,hdr1]=ReadAnalyzeImg(GMprob,'raw'); % Gray matter
%
[img2,hdr2]=ReadAnalyzeImg(WMprob,'raw'); % White matter
%
[img3,hdr3]=ReadAnalyzeImg(CSFprob,'raw'); % CSF
%
img4=int16(255)-(int16(img1)+int16(img2)+int16(img3));                 % Background
img4(img4<0)=0;
img4(img4>255)=1;
img4=uint8(img4);
%
[y,index]=max([img1(:) img2(:) img3(:) img4(:)],[],2);
%
[pn,PreName,ext]=fileparts(PreMRName);
%
Mask=uint8(ones(size(imgOrg)));
Mask((index==4)|(index==3))=0;
if (FilesToGenerate(1) == '1')
    MaskHdr=hdrOrg;
    MaskHdr.name=[PreName '_mask'];
    MaskHdr.path='';
    MaskHdr.pre=16;
    MaskHdr.lim=[32767 -32768];
    MaskHdr.scale=1;
    MaskHdr.offset=0;
    MaskHdr.origin=hdrOrg.origin;
    MaskHdr.endian='ieee-be';
    MaskHdr.descr='spmsegm2mask: Volume containing mask (1 - inside brain, 0 - outside)';
    WriteAnalyzeImg(MaskHdr,Mask);
end
%
if (FilesToGenerate(2) == '1')
    imgMasked=imgOrg;
    imgMasked(Mask==0)=0;
    hdrMasked=hdrOrg;
    hdrMasked.name=[PreName '_masked'];
    hdrMasked.path='';
    hdrMasked.descr='Original MR image masked by segmentation (GM&WM) created using SPM';
    WriteAnalyzeImg(hdrMasked,imgMasked);
end
%
if (FilesToGenerate(3)=='1')
    SegmHdr=hdrOrg;
    SegmHdr.name=[PreName '_GM_WM'];
    SegmHdr.path='';
    SegmHdr.pre=16;
    SegmHdr.lim=[32767 -32768];
    SegmHdr.scale=1;
    SegmHdr.offset=0;
    SegmHdr.origin=hdrOrg.origin;
    SegmHdr.endian='ieee-be';
    SegmHdr.descr='spmsegm2mask: Volume containing values 0 - BG, 1 - CSF, 2 - GM, 3 - WM';
    Segm=uint8(zeros(size(imgOrg)));  %Background
    Segm(index==2)=3;  %White
    Segm(index==1)=2;  %Gray
    Segm(index==3)=1;  %CSF
    WriteAnalyzeImg(SegmHdr,Segm);
end
