function applyrois(FunctionalScanFile,StructuralScanFile,...
    AlignmentFile,RoiSets,RoiVolumeFile,GM_WM_segmented,CreateMRvolumes,Defaults,DoWarp)
%
% Function that aplies a set of rois to a new dataset, requires that both
%  a functions (PET/SPECT) scan and a structural MR scan is
%  available. Further, the transformation between structural and functional
%  scan shall be available in a AIR file.
%
% The preferred resolution in the MR scan is no worse than (2x2x2 mm)
%
% The function are called like:
%
%  applyrois(FunctionalScanFile,StructuralScanFile,...
%    AlignmentFile,RoiSets[,RoiVolumeFile[,GM_WM_segmented[,CreateMRvolumes[,Defaults[,DoWarp]]]]])
%
%  Input:
%    FunctionalScanFile - File with functional scan, the file to which the ROIs is transferred to
%    StructuralScanFile - File used for identification of transformation
%       parameters between template space and new subject space
%    AlignmentFile - AIR file defining transformation between Functional
%       and Structural space for the subject
%    RoiSets - Either:
%       Cell array including the directories of the ROI sets to apply to
%         the subjects functional scan (ROI sets has to be defined in an
%         editroi region file and MR images as analyze files). In the
%         directories a file called T1.img/hdr (template MR image) and
%         roi.mat (applyrois roi set) should be present
%       Structure:
%         RoiSets.Sets - Cell arrary of paths to template ROI/structural
%         scan sets
%         RoiSets.SetName - Name of editroi ROI set file
%         RoiSets.TemplateType - Name of structural template file (analyze
%         image file with structural scan)
%    RoiVolumeFile - File name used for  the ROI volume created, if empty
%       this roi volume is not created
%    GM_WM_segmented - File name, this option is only used for extraction of data from
%       functional volume. If this is included data is extracted for
%       GM/WM/CSF and background classes for each ROI. If empty this is not
%       done. The volume should have the following values for each class, 0
%       - background, 1 - CSF, 2- GM, and 3- WM
%    CreateMRvolumes - (1 or 0 (default)), If set to 1 the coregistered and warped MR image for
%       each template space is saved for inspection.
%    Defaults - This is a structure with default values for the following
%     sections:
%       AIR12 - parameters for calling AIR: alignlinear (12 parameter transformation parameters
%         between structural image and MR template), e.g.
%         Defaults.AIR12.m=12; % 12 paramter transformation
%       AIRreslice - paramters for reslicing template MR to structural MR
%         before warping
%       WARP - parameters for calling warping algoritn: compute_warp
%       WARPreslice - parameters for calling warp_reslice for reslicing
%         template MR's to structural subject MRs
%       General - parameters for applyrois that are not connected to external programs
%    DoWarp - 1 (default) or 0. If set to zero no warp is calculated (only
%       12 par affine transformation is calculated)
%
% CS, 221101, First version
% CS, 070802, Revised for real userinterface
%
if (nargin==0)
    applyrois_ui;
elseif (nargin~=4) && (nargin~=5) && (nargin~=6) && (nargin~=7) && (nargin~=8) && (nargin~=9)
    error('Not correct number of right hand side arguments for applyrois')
else
    %
    % Set defaults for external method
    %
    if (nargin<9)
        DoWarp=1;
    end
    %
    if (nargin<8) || ~isstruct(Defaults)
        Defaults=[];
    end
    if ~isfield(Defaults,'AIR12')
        Defaults.AIR12=SetDefaultsAIR12;
    end
    if ~isfield(Defaults,'AIRreslice')
        Defaults.AIRreslice=SetDefaultsAIRreslice;
    end
    if ~isfield(Defaults,'WARP')
        hdr=ReadAnalyzeHdr(fullfile(RoiSets.Sets{1}, ...
            RoiSets.TemplateType));
        VoxelDim=hdr.dim;
        VoxelSize=hdr.siz;
        Defaults.WARP=SetDefaultsWARP(VoxelSize,VoxelDim);
    end
    if ~isfield(Defaults,'WARPreslice')
        Defaults.WARPreslice=SetDefaultsWARPreslice;
    end
    if ~isfield(Defaults,'General')
        hdr=ReadAnalyzeHdr(FunctionalScanFile);
        VoxelSize=hdr.siz;
        Defaults.General=SetDefaultsGeneral(VoxelSize);
    end
    %
    if (nargin<7)
        CreateMRvolumes=[];
    end
    %
    % Default behaviour for old way of defining ROI sets
    %
    if ~isstruct(RoiSets)
        RoiSets.Sets=RoiSets;
        RoiSets.SetName='roi';
        RoiSets.TemplateType='T1';
    end
    %
    if (~isempty(GM_WM_segmented))
        GM_WM_PETres=[pwd filesep 'GM_WM2PETres'];
        Hdr=ReadAnalyzeHdr(GM_WM_segmented);
        if (Hdr.pre==8)
            [pn,fn,ext]=fileparts(GM_WM_segmented);
            GM_WM_segmented_tmp1=[pn filesep fn];
            analyze8to16bit(GM_WM_segmented_tmp1);
            ResliceMRsegmented([GM_WM_segmented_tmp1 '_i16'],...
                TmpAlignmentFile,GM_WM_PETres);
            delete([GM_WM_segmented_tmp1 '_i16.*']);
        else
            ResliceMRsegmented(GM_WM_segmented,...
                TmpAlignmentFile,GM_WM_PETres);
        end
    else
        GM_WM_PETres='';
    end
        %
    %matlabpool(8);
    parfor i=1:length(RoiSets.Sets)   % Loop over all standard ROIs
    %for i=1:length(RoiSets.Sets)   % Loop over all standard ROIs
        fprintf('Started to transfer ROIs from: %s\n',RoiSets.Sets{i});
        %
        TmpDir=GetTmpDirName(i);
        %
        ReslROI=[RoiSets.Sets{i} filesep RoiSets.SetName];
        ReslStruct=[RoiSets.Sets{i} filesep RoiSets.TemplateType];
        %
        [d1,d2,d3]=fileparts(FunctionalScanFile);
        [r1,r2,r3]=fileparts(RoiSets.Sets{i});
        TmpName=[TmpDir filesep r2 '_trnsf2_' d2];
        [Tmp1,Tmp2]=fileparts(TmpName);
        %
        EqualizedStructScanFile=[Tmp1 filesep 'MR_eq_' Tmp2];
        HomogenTransf=[TmpName '.air'];
        CombinedAir=[TmpName 'combine.air'];
        InvHomogenTransf=[Tmp1 filesep 'Inv' Tmp2 '.air'];
        HomogenTransfImg=[Tmp1 filesep 'r' Tmp2];
        WarpField=[TmpName 'WarpField'];
        TmpAlignmentFile=[TmpName 'MR2PET.air'];
        %
        pos=strfind(RoiSets.Sets{i},filesep);
        [Tmp1,Tmp2]=fileparts(FunctionalScanFile);
        [Tmp3,Tmp4]=fileparts(StructuralScanFile);
        Resl2Std=['wr' RoiSets.Sets{i}(pos(length(pos))+1:length(RoiSets.Sets{i})) 'MR2' Tmp4];
        Roi2Std{i}=[RoiSets.Sets{i}(pos(length(pos))+1:length(RoiSets.Sets{i})) 'ROI2' Tmp2];
        %
        ImageHistogramEqualize(StructuralScanFile,EqualizedStructScanFile,ReslStruct);
        %
        AlignHomogen(ReslStruct,EqualizedStructScanFile,HomogenTransf,Defaults.AIR12);
        ResliceHomogen(HomogenTransf,HomogenTransfImg,Defaults.AIRreslice);
        %
        InvHomogen(HomogenTransf,InvHomogenTransf);
        %
        [A,Struct]=ReadAir(InvHomogenTransf);
        [pn,fn,ext]=fileparts(InvHomogenTransf);
        InvHomogenTransfTmp=[TmpDir filesep fn 'Tmp.air'];
        SaveAir(InvHomogenTransfTmp,Struct);
        %
        if DoWarp==1
            %
            % Warping field should be calculated
            %
            ComputeWarp(HomogenTransfImg,ReslStruct,...
                WarpField,Defaults.WARP);
            %ComputeWarp(ReslStruct,HomogenTransfImg,...
            %    [WarpField '_inv'],Defaults.WARP);
            %[img11,hdr11]=ReadAnalyzeImg(WarpField);
            %[img22,hdr22]=ReadAnalyzeImg([WarpField '_inv']);
            %img11=(img11-img22)/2;
            %WriteAnalyzeImg(hdr11,img11);
        else
            %
            % Warping field set to zero (this means no warping)
            %
            WarpField='';
        end
        %
        if (~isempty(CreateMRvolumes)) && (CreateMRvolumes==1)
            ResliceWarp(ReslStruct,WarpField,InvHomogenTransfTmp,Resl2Std,Defaults.WARPreslice);
        end
        %
        HdrStruc=ReadAnalyzeHdr(StructuralScanFile);
        HdrFunc=ReadAnalyzeHdr(FunctionalScanFile);
        [A,AirStruct]=ReadAir(AlignmentFile);
        if ((max(abs(AirStruct.hdrO.dim(1:3)-HdrFunc.dim(1:3)))>1e-5) || ...
                (max(abs(AirStruct.hdrO.siz(1:3)-HdrFunc.siz(1:3)))>1e-5) || ...
                (max(abs(AirStruct.hdrI.dim(1:3)-HdrStruc.dim(1:3)))>1e-5) || ...
                (max(abs(AirStruct.hdrI.siz(1:3)-HdrStruc.siz(1:3)))>1e-5))
            if ((max(abs(AirStruct.hdrI.dim(1:3)-HdrFunc.dim(1:3)))>1e-5) || ...
                    (max(abs(AirStruct.hdrI.siz(1:3)-HdrFunc.siz(1:3)))>1e-5) || ...
                    (max(abs(AirStruct.hdrO.dim(1:3)-HdrStruc.dim(1:3)))>1e-5) || ...
                    (max(abs(AirStruct.hdrO.siz(1:3)-HdrStruc.siz(1:3)))>1e-5))
                Txt1='The defined alignment file does not fit to selected';
                Txt2=' structural or functional scans';
                error([Txt1 Txt2]);
            else
                % PET to MR alignment in AIR file, invert AIR file before using it
                InvHomogen(AlignmentFile,TmpAlignmentFile);
            end
        else
            % MR to PET alignment in AIR file, use AIR file directly
            Success=copyfile(AlignmentFile,TmpAlignmentFile);
            if (Success~=1)
                error('Problem in copying Alignment file');
            end
        end
        %
        CombineAirs(CombinedAir,InvHomogenTransf,TmpAlignmentFile);
        %
        %
        applyrois_reslice(ReslROI,CombinedAir,Roi2Std{i}, ...
            WarpField,GM_WM_PETres,Defaults.General.FilterWidth);
        %
        delete(HomogenTransf);             % Temporaer transformations matrix (AIR file)
        delete(InvHomogenTransf);          % Temporaer transformations matrix (AIR file)
        delete([HomogenTransfImg '.*']);   % Temporaer transformations image (Analyze file)
        delete(CombinedAir);               % Temporaer transformations matrix (AIR file)
        if ~isempty(WarpField)
            delete([WarpField '.*']);      % Temporaer fil med warp field (AnalyzeFile)
        end
        delete(TmpAlignmentFile);          % Temporaer transformation matrix (AIR file)
        delete(InvHomogenTransfTmp);               % Temporaer reslicing file (AIR file)
        delete([EqualizedStructScanFile '.*']);    % Temporaer equalized file (Analyze file)
        %
        rmdir(TmpDir,'s');                 % Remove temporary directory with all files not already removed
        %
    end  % end loop with VOI sets
    %
    [pn,fn,ext]=fileparts(Roi2Std{1});
    if isempty(pn)
        pn='.';
    end
    %
    if (exist([pn filesep fn '.mat'],'file')==2)
        FileType=0;   % editroi file type
    else
        FileType=1;   % Volume file type
    end
    if (length(Roi2Std)>1)
        %
        %
        [r1,r2,r3]=fileparts(RoiSets.Sets{1});
        [d1,d2,d3]=fileparts(r1);
        [Tmp1,Tmp2]=fileparts(FunctionalScanFile);
        Roi2StdCommon=['CommonROI' d2 '2' Tmp2];
        %
        if (FileType==0)
            Hdr=ReadAnalyzeHdr(FunctionalScanFile);
            if exist('Defaults','var')&&isfield(Defaults,'General')&&isfield(Defaults.General,'FilterWidth')&&...
                    ~isempty(Defaults.General.FilterWidth)
                FilterSpec=[1 1 1]*Defaults.General.FilterWidth;
            else
                FilterSpec=[1 1 1]*max(Hdr.siz);
            end
            Precision=0.5;
            MaxIter=20;
            %
            editroiGenCommonRois(Roi2Std,FunctionalScanFile,Roi2StdCommon,...
                FilterSpec,Precision,MaxIter);
        elseif (FileType==1)
            voxvoiCombine(Roi2Std,Roi2StdCommon);
        else
            warn('Unknown file type for generating common roi set');
        end
        fprintf('Generated common ROI set with name:\n  %s\n\n',Roi2StdCommon);
    end
    %
    if (nargin >= 5) && ~isempty(RoiVolumeFile)
        %
        % There is a problem here because everything should be done in MR
        % resolution to be correct, but just now this ROI definitions is done
        % in PET resolution
        if FileType==0
            if (length(Roi2Std)>1)
                editroi2pve(Roi2StdCommon,FunctionalScanFile,GM_WM_PETres,RoiVolumeFile);
            else
                editroi2pve(Roi2Std{1},FunctionalScanFile,GM_WM_PETres,RoiVolumeFile);
            end
        elseif FileType==1
            if (length(Roi2Std)>1)
                voxvoi2pve(Roi2StdCommon,GM_WM_PETres,RoiVolumeFile);
            else
                voxvoi2pve(Roi2Std{1},GM_WM_PETres,RoiVolumeFile);
            end
        else
            warn('Unknown file type for generating common roi set');
        end
    end
    if ~isempty(GM_WM_PETres)
        delete([GM_WM_PETres '.*']);       % Temporary file with GM_WM segmented images
    end
end


function []=ImageHistogramEqualize(StructuralScanFile,EqualizedStructScanFile,ReslStruct)
%
% StructuralScanFile - original structural file for new subject
% EqualizedStructScanFile - equalized structural file for new subject
% ReslStruct - structural template file
%
% This step is needed due to problems with the AIR alignment routine
% at MR image with contrasts differently from the template MR images
%
[ReslImg,ReslHdr]=ReadAnalyzeImg(ReslStruct);
ReslInd=find(ReslImg>0.1*max(ReslImg));   % Ignore voxels less than 10
% perc. of max
%MaxReslImg=max(ReslImg);
%[n,bin]=histc(ReslImg(ReslInd),0:MaxReslImg/50:MaxReslImg);
MaxReslImg=max(ReslImg(ReslInd));
MinReslImg=min(ReslImg(ReslInd));
%[n,bin]=histc(ReslImg(ReslInd),MinReslImg:(MaxReslImg-MinReslImg)/200:MaxReslImg);
if (MaxReslImg<500)
    [n,bin]=histc(ReslImg(ReslInd),0:1:MaxReslImg);
else   % Probably too many bin's
    [n,bin]=histc(ReslImg(ReslInd),0:MaxReslImg/500:MaxReslImg);
end
%
[StructImg,StructHdr]=ReadAnalyzeImg(StructuralScanFile);
StructInd=find(StructImg>0.1*max(StructImg));   % Ignore voxels less than 10
% perc. of max
j=histeq(uint16(round(StructImg(StructInd)/max(StructImg(StructInd))*65535)),n);
%j=histeq(uint16(StructImg(StructInd)),n);
j=double(j)/65535*MaxReslImg;
%
EqImg=zeros(size(StructImg));
EqImg(StructInd)=j;
EqHdr=StructHdr;
EqHdr.name=EqualizedStructScanFile;
%
% It is a better idea to set header scale to the same as the template image
% scale. AIR programs doesn't use information but warping programs does
%
EqHdr.pre=ReslHdr.pre;
EqHdr.lim=ReslHdr.lim;
EqHdr.scale=ReslHdr.scale;
EqHdr.offset=ReslHdr.offset;
NRUvar=getenv('NRU');
if ~isempty(NRUvar) & (NRUvar=='1')
    EqHdr.endian='ieee-be';
end
[result]=WriteAnalyzeImg(EqHdr,EqImg);


function []=AlignHomogen(StdStruct,ReslStruct,HomogenTransf,DefaultsAIR12)
%
Cmd{1}='alignlinear';
Cmd{2}=StdStruct;
Cmd{3}=ReslStruct;
Cmd{4}=HomogenTransf;
CmdStr=[];
for i=1:length(Cmd)
    CmdStr=[CmdStr ' ' Cmd{i}];
end
ParameterStr=FormulateParameterStringAIR(DefaultsAIR12);
CmdStr=[CmdStr ' ' ParameterStr];
fprintf('Do calculation of 12 parameter affine transformation\n');
unix(CmdStr);


function []=InvHomogen(HomogenTransf,InvHomogenTransf)
%
Cmd{1}='invert_air';
Cmd{2}=HomogenTransf;
Cmd{3}=InvHomogenTransf;
Cmd{4}='y';
CmdStr=[];
for i=1:length(Cmd)
    CmdStr=[CmdStr ' ' Cmd{i}];
end
unix(CmdStr);


function []=ResliceHomogen(HomogenTransf,Img,DefaultsAIRreslice);
%
Cmd{1}='reslice';
Cmd{2}=HomogenTransf;
Cmd{3}=Img;
Cmd{4}='-k';
Cmd{5}='-o';
Cmd{6}='-n 1';  % Now trilinear (although I think it should be nearest neighbour)
CmdStr=[];
for i=1:length(Cmd)
    CmdStr=[CmdStr ' ' Cmd{i}];
end
ParameterStr=FormulateParameterStringAIR(DefaultsAIRreslice);
CmdStr=[CmdStr ' ' ParameterStr];
fprintf('Do reslice volume using estimated affine transformation\n');
unix(CmdStr);


function []=ComputeWarp(StdStruct,HomogenTransfImg,WarpField,DefaultsWARP)
%
Cmd{1}='compute_warp';
Cmd{2}=' - ';
Cmd{3}=['datafile=' HomogenTransfImg];
Cmd{4}=['outfile_field=' WarpField];
Cmd{5}=['templatefile=' StdStruct];
CmdStr=[];
for i=1:length(Cmd)
    CmdStr=[CmdStr ' ' Cmd{i}];
end
ParameterStr=FormulateParameterStringWARP(DefaultsWARP);
CmdStr=[CmdStr ' ' ParameterStr];
fprintf('Do calculation of warp field\n');
unix(CmdStr);
fprintf('%s\n',CmdStr);


function CombineAirs(CombinedAir,HomogenTransf,MR2PET)
%
Cmd{1}='combine_air';
Cmd{2}=CombinedAir;
Cmd{3}='y';
Cmd{4}=MR2PET;
Cmd{5}=HomogenTransf;
CmdStr=[];
for i=1:length(Cmd)
    CmdStr=[CmdStr ' ' Cmd{i}];
end
unix(CmdStr);


function []=ResliceMRsegmented(GM_WM_segmented,AlignmentFile,GM_WM_PETres)
%
TmpName=[tempname '.air'];
unix(['cp ' AlignmentFile ' ' TmpName]);
unix(['mv_air ' TmpName ' '  GM_WM_segmented ]);
%
Cmd{1}='reslice';
Cmd{2}=TmpName;
Cmd{3}=GM_WM_PETres;
Cmd{4}='-n 0';
Cmd{5}='-k';
Cmd{6}='-o';
CmdStr=[];
for i=1:length(Cmd)
    CmdStr=[CmdStr ' ' Cmd{i}];
end
unix(CmdStr);
%
delete(TmpName);



function []=ResliceWarp(ReslStruct,WarpField,InvHomogenTransf,Resl2Std,DefaultsWARPreslice)
%
[Atmp,AirStruct]=ReadAir(InvHomogenTransf);
if (all(AirStruct.hdrI.origin~=0))
    AirStruct.hdrI.origin=AirStruct.hdrI.origin-1;
end;
if (all(AirStruct.hdrO.origin~=0))
    AirStruct.hdrO.origin=AirStruct.hdrO.origin-1;
end;
A=inv(tala2voxa(AirStruct.A,AirStruct.hdrI,AirStruct.hdrO));
%
Cmd{1}='warp_reslice -l ';  % Trilinear interpolation
Cmd{2}=['-g "' sprintf('%e ',A') '"'];
Cmd{3}=['-j ' ReslStruct];
if ~isempty(WarpField)
    Cmd{4}=['-f ' WarpField];
else
    Cmd{4}='';
end
Cmd{5}=['-c ' sprintf('%f ',AirStruct.hdrO.siz/10')];
Cmd{6}=['-z ' sprintf('%f ',AirStruct.hdrO.dim')];
Cmd{7}=['-k ' sprintf('%f ',AirStruct.hdrI.dim')];
CmdStr=[];
for i=1:length(Cmd)
    CmdStr=[CmdStr ' ' Cmd{i}];
end
ParameterStr=FormulateParameterStringAIR(DefaultsWARPreslice);
CmdStr=[CmdStr ' ' ParameterStr ' ' Resl2Std];
fprintf('Do reslice volume using affine transformation and possbily warp field\n');
unix(CmdStr);


function ParameterStr=FormulateParameterStringAIR(ParameterStruct)
%
% Formulate parameter string from structure with defaults for method
%
QuestStr=fieldnames(ParameterStruct);
ParameterStr=[];
for i=1:length(QuestStr)
    if isnumeric(ParameterStruct.(QuestStr{i}))
        ParameterStr=[ParameterStr ' -' QuestStr{i} ' ' num2str(ParameterStruct.(QuestStr{i}))];
    else
        ParameterStr=[ParameterStr ' -' QuestStr{i} ' ' ParameterStruct.(QuestStr{i})];
    end
end


function ParameterStr=FormulateParameterStringWARP(ParameterStruct)
%
% Formulate parameter string from structure with defaults for method
%
QuestStr=fieldnames(ParameterStruct);
ParameterStr=[];
for i=1:length(QuestStr)
    if isnumeric(ParameterStruct.(QuestStr{i}))
        ParameterStr=[ParameterStr ' ' QuestStr{i} '="' num2str(ParameterStruct.(QuestStr{i})) '"'];
    else
        ParameterStr=[ParameterStr ' ' QuestStr{i} '=' ParameterStruct.(QuestStr{i})];
    end
end



function [AIR12]=SetDefaultsAIR12()
%
% Defaults for method AIR 12 paramter estimation
%
AIR12.m=12;
%
AIR12.t1=50;
AIR12.t2=50;
AIR12.b1=[6.0 6.0 6.0];
AIR12.b2=[6.0 6.0 6.0];
AIR12.p1=1;
AIR12.p2=1;
%AIR12.x=2; % In case problems are seen for some templates use other cost-function
AIR12.x=3;
AIR12.s=[81 1 3];
AIR12.r=25;
AIR12.h=5;
AIR12.c=0.00001;


function [AIRreslice]=SetDefaultsAIRreslice()
%
% Defaults for method AIR reslice
%
AIRreslice.n=1;


function [WARP]=SetDefaultsWARP(VoxelSize,VoxelDim)
%
% Defaults for method WARP field estimation
%
WARP.method=3;  % Mutual information
WARP.repeat=8;
WARP.outputfileformat=3;
WARP.logfile='warp.log';
%
OneIteration=0;
%
if ((round(VoxelDim(1)/4)-VoxelDim(1)/4)==0)
    WARP.resx=[VoxelDim(1)/4 VoxelDim(1)/2 VoxelDim(1)];
else
    OneIteration=1;
end
%
if ((round(VoxelDim(2)/4)-VoxelDim(2)/4)==0)
    WARP.resy=[VoxelDim(2)/4 VoxelDim(2)/2 VoxelDim(2)];
else
    OneIteration=1;
end
%
if ((round(VoxelDim(3)/4)-VoxelDim(3)/4)==0)
    WARP.resz=[VoxelDim(3)/4 VoxelDim(3)/2 VoxelDim(3)];
else
    OneIteration=1;
end
%
if OneIteration
    WARP.resx=VoxelDim(1);
    WARP.resy=VoxelDim(2);
    WARP.resz=VoxelDim(3);
    fprintf('Optimization of warp field done in one step, due to problems with dimensions of templates\n');
end
%WARP.resx=[32 64 128];
%WARP.resy=[32 64 128];
%WARP.resz=[20 40 80];
%
WARP.alpha=[0.11 0.08 0.06];
WARP.min_rel_change=0;
WARP.search=2;
WARP.segx=4;
WARP.segy=4;
WARP.segz=4;
WARP.auto=0;
WARP.sig_level='silent';
%
% At least 1 mm filter applied to warp field
% In case voxel size larger at least filtered by min voxel size
%
MinVoxelSize=min(VoxelSize);
if (MinVoxelSize>1)
    WARP.d_filter_fwhm=1;
else
    WARP.d_filter_fwhm=1/MinVoxelSize;
end
%WARP.d_filter_fwhm=0.2;
% Unfortunately this parameter destroys estimation, even if it set to 1
%WARP.no_reconcile=1


function [WARPreslice]=SetDefaultsWARPreslice()
%
% Defaults for method WARP reslicing
%
WARPreslice.T=[1 1 1];


function [General]=SetDefaultsGeneral(VoxelSize)
%
% Defaults for method WARP field estimation
%
General.FilterWidth=max(VoxelSize);  % Filtering of probability volumes before creating regions


function [tmpdir]=GetTmpDirName(loop)
%
% Searches for the first available tmp dir name and creates the directory
%
Stop=0;
while Stop~=-1
    tmpdir=sprintf('%s%stmp_dir%02i_%02i',pwd,filesep,loop,Stop);
    if (exist(tmpdir)==0)
        mkdir(tmpdir);
        Stop=-1;
    else
        Stop=Stop+1;
    end
end
