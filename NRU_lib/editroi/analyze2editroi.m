function [Result,Roi]=analyze2editroi(VolumeInFN,EditroiOutFN,arg3,arg4,arg5)
%
%  Convert a set of ROIs defined in an anlyze volume file with 1, 2, 3 etc. to a
%   set of ROIs defined as in editroi. If a file <VolumeInFN>.descr exist
%   this is used for naming the ROIs
%
%  [Result,Roi]=analyze2editroi(VolumeInFN,EditroiOutFN[,FilterSpec,FilterThres])
%
%  [Result,Roi]=analyze2editroi(RoiVolume,RoiHdr,RoiDescription[,FilterSpec,FilterThres])
%
%    VolumeInFN   - Name of header file defining the size of the volume that
%                    should be used for creating the ROIs. If a
%                    file with the name "<VolumeInFN>.descr" exist the names
%                    in this are used for naming of the ROIs (file format,
%                    text file with two columns (RoiNo, RoiName))
%    EditroiOutFN - name of editroi file where ROI definition should be
%                    written into
%    FilterSpec   - Specification of pre-filter in voxel's e.g. [3 3 5],
%                    specifies a Gaussian filter with the size of 3,3,5 mm
%                    (FWHM) [default: max(voxel_size)*[1 1 1]]
%    FilterThres - Specifies at what level to do the Thresholding of the
%                    filtered image (old behavious) (no iteration).
%
%                    A structure with the following information can be given
%                    as input instead:
%
%                        FilterThres.Iter=20;
%                        FilterThres.Prec=0.025;
%                        FilterThres.Vol=1000; (no default, has to be specified for
%                                                           propability maps, for none propability maps
%                                                           this parameter is not used if specified)
%
%                    the threshold is optimized to keep the volume
%                    unchanged. For none propability maps the volume to achieve is
%                    automatically calculated. The iteration is started from a threshold value of 0.5.
%
%                    The default behaviour (empty input) is to
%                    set the values as specified above and then iterate.
%                    For propability maps no iteration is made, instead a
%                    threshold of 0.5 is used.
%
%    RoiVolume    - A volume of ROIs (values 1, 2, 3, 4, ....)
%                    If this volume contains none integer values between 0
%                    and 1 the volume is used as an propability map instead)
%    RoiHdr       - A header describing ROI volume
%    RoiDescription - Description fields for the ROIs
%
%
%    Result       - Error argument (1 for success, 0 for failure)
%    Roi          - Structure with ROIs (same format as from LoadRoi
%
% CS, 021018, Vers. 1
%
Result=1;
if (nargin ~= 0) && (nargin ~=2) && (nargin ~=3) && (nargin ~=4) && (nargin ~=5)
    error('analyze2editroi function has to be called with either 0, or 2 to 5 right handside arguments');
end
if (nargout > 2)
    error('analyze2editroi function has to be called with 0 to 2 left handside arguments');
end
%
if (nargin == 0)
    [VolumeInFN, VolumeInPN] = ...
        uigetfile('*.hdr', 'Analyze file with ROI volume definitions');
    if (VolumeInFN==0)
        error('ROI input volume has to be defined');
    end
    VolumeInFN=[VolumeInPN VolumeInFN];
    [EditroiOutFN, EditroiOutPN] = ...
        uiputfile('*.mat', 'Name of editroi file to write ROIs into');
    if (EditroiOutFN==0)
        error('Editroi file has to be defined');
    end
    EditroiOutFN=[EditroiOutPN EditroiOutFN];
end
%
if (nargin == 3) || (nargin == 5)
    RoiVolume=VolumeInFN;
    VolumeInFN=[];
    RoiHdr=EditroiOutFN;
    EditroiOutFN=[];
    RoiDescription=arg3;
    if (nargin == 5)
        FilterSpec=arg4;
        FilterThres=arg5;
    else
        FilterSpec=[];
        FilterThres=[];
    end
else
    %
    [RoiVolume,RoiHdr]=ReadAnalyzeImg(VolumeInFN,':','raw');
    RoiDescription=ReadRoiDescription(VolumeInFN);
    if (nargin == 4)
        FilterSpec=arg3;
        FilterThres=arg4;
        
    else
        FilterSpec=[];
        FilterThres=[];
    end
end
%
if all(RoiHdr.origin==0)
    RoiHdr.origin=RoiHdr.origin+1;
end
%
% Set default in no filter or precision argument is given
%
if isempty(FilterSpec)
    FilterSpec=max(RoiHdr.siz)*[1 1 1];
end
if isempty(FilterThres)
    FilterThres.Iter=20;
    FilterThres.Prec=0.025;
    FilterThres.Vol=[];
end
%
Roi=Volume2Editroi(RoiVolume,RoiHdr,RoiDescription,FilterSpec,FilterThres);
%
if ~isempty(EditroiOutFN)
    SaveRoi(EditroiOutFN,Roi);
end



function [Roi]=Volume2Editroi(RoiVolume,Hdr,RoiDescr,FilterSpec,FilterThres)
%
% Function that converts a volume to ROI
%
%
% Decide if Propability map or discrete ROI volume
%
RoiVolume=double(RoiVolume);
%
Bits=0;     % Is the volume coded as bits
if all(fix(RoiVolume(:)) == RoiVolume(:))==1
    RoiVolume=uint64(RoiVolume);
    Uniques=unique(RoiVolume);
    if ~isempty(find(Uniques<0, 1))
        warning('Handles only volumes with voxels > 0, other voxels set to xero');
    end
    Uniques=Uniques(Uniques>=1);
    PropVol=0;
    if (max(diff(double(Uniques)))>1)
        Bits=1;
        MaxVol=max(RoiVolume(:));
        BitsSet=bitget(MaxVol,1:63);
        NoOfRegions=find(BitsSet==1, 1, 'last' );
    else
        NoOfRegions=length(Uniques);
    end
else
    if (min(RoiVolume(:))>=0) && (max(RoiVolume(:))<=1)
        Uniques=1;
        PropVol=1;
        NoOfRegions=1;
    else
        error('Neither integer volume or propability volume specified');
    end
end
%
RoiNumber=1;
%
for j=1:NoOfRegions;     % Run's over number of different ROI's
    if (PropVol==0)
        fprintf('VOI (%i) name: %s\n',j,RoiDescr{j});
        BitVol=zeros(size(RoiVolume));
        if (Bits==1)
            BitVol(bitget(RoiVolume,j)==1)=1;
        else
            BitVol(RoiVolume==j)=1;
        end
        VolumeOfRoi=length(find(BitVol==1));
    else
        BitVol=RoiVolume;
        if isfield(FilterThres,'Vol')
            VolumeOfRoi=FilterThres.Vol;
        else
            VolumeOfRoi=[];
        end
    end
    %
    BitVol=reshape(BitVol,Hdr.dim(1:3)');
    %
    % Filters image with specified FWHM
    %
    [BitVol]=gauss_vol(double(BitVol),Hdr.siz',FilterSpec,4);
    %
    if ~isstruct(FilterThres)
        Thres.Value=FilterThres;
        Thres.Step=[];
        Thres.Iter=[];
        Thres.Prec=[];
        Thres.Vol=[];
    else  % Automatc determination
        Thres.Value=0.5;
        Thres.Step=0.25;
        Thres.Iter=FilterThres.Iter;
        Thres.Prec=FilterThres.Prec;
        Thres.Vol=VolumeOfRoi;
    end
    %
    % Threshold Roi
    RoiLatest=IdentifyRoi(BitVol,Hdr,Thres);
    %
    if (j==1)
        Roi.slicedist=Hdr.siz(3);
        Roi.filetype='EditRoiFile';
    end
    
    if isempty(RoiDescr)
        Roi.regionname{j,1}=sprintf('ROI %i',j);
    else
        Roi.regionname{j,1}=RoiDescr{j};
    end
    for i=1:length(RoiLatest.vertex);
        Roi.vertex{RoiNumber,1}=RoiLatest.vertex{i};
        Roi.mode{RoiNumber,1}=RoiLatest.mode{i};
        Roi.region(RoiNumber,1)=j;
        Roi.relslice(RoiNumber,1)=RoiLatest.relslice(i);
        RoiNumber=RoiNumber+1;
    end
end


function  Roi=IdentifyRoi(BitVol,Hdr,Thres)
%
% Function that threshold a volume at a given level
%
Stop=0;
Counter=1;
%
while (Stop==0)
    RoiTmp=ContourSlice(BitVol,Hdr,Thres.Value);
    %
    clear('Roi');
    %
    for i=1:length(RoiTmp)
        Roi.vertex{i,1}=RoiTmp{i}.Contour;
        Roi.region(i,1)=1;
        Roi.relslice(i,1)=RoiTmp{i}.Plane/Hdr.siz(3)-Hdr.origin(3)+1;
        Roi.mode{i,1}='InsideAdd';
    end
    Roi.regionname{1,1}='';
    %
    if isfield(Roi,'vertex')
        [Result,RoiNew,RoiDescrNew]=editroi2analyze(Roi,Hdr);
        RoiNewVol=length(find(RoiNew==1));
    else
        % No voxels selected
        RoiNewVol=0;
    end
    if ~isempty(Thres.Vol)
        Diff=(RoiNewVol-Thres.Vol)/Thres.Vol*100;
        fprintf(' Iter: %i, Error: %f, Threshold: %f\n',Counter,Diff,Thres.Value);
        if (abs(Diff) > Thres.Prec)
            if (Diff>0)
                Thres.Value=Thres.Value+Thres.Step;
            else
                Thres.Value=Thres.Value-Thres.Step;
            end;
            Thres.Step=Thres.Step/2;
        else
            Stop=1;
        end
    else
        Stop=1;
    end
    %
    Counter=Counter+1;
    if (Counter > Thres.Iter)
        Stop=1;
    end
end


function ROI=ContourSlice(BitVol,Hdr,Threshold)
%
ROI=[];
%
if all(Hdr.origin==0)
    Hdr.origin=Hdr.origin+1;
end
Counter=1;
XData=((1-Hdr.origin(1)):(Hdr.dim(1)-Hdr.origin(1)))*Hdr.siz(1);
YData=((1-Hdr.origin(2)):(Hdr.dim(2)-Hdr.origin(2)))*Hdr.siz(2);
ZData=((1-Hdr.origin(3)):(Hdr.dim(3)-Hdr.origin(3)))*Hdr.siz(3);
%
for i=1:size(BitVol,3)
    BitSlice=BitVol(:,:,i);
    if max(BitSlice(:))>Threshold
        C = contourc(YData,XData,BitSlice,[Threshold Threshold]);
        if ~isempty(C)
            StartPoint=1;
            while (StartPoint < size(C,2))
                ROI{Counter}.Contour=[C(2,StartPoint+1:StartPoint+(C(2,StartPoint)));...
                    C(1,StartPoint+1:StartPoint+(C(2,StartPoint)))]';
                ROI{Counter}.Plane=ZData(i);
                Counter=Counter+1;
                StartPoint=StartPoint+C(2,StartPoint)+1;
            end
        end
    end
end



function RoiDescription=ReadRoiDescription(FileName)
%
% Function that reads a simple text file with ROI names, if available
%  shouldhave extension ".descr"
%
[pn,fn,ex]=fileparts(FileName);
if isempty(pn)
    pn='.';
end
pid=fopen([pn filesep fn '.descr'],'r');
if (pid == -1)
    RoiDescription=[];
else
    Counter=1;
    while ~feof(pid)
        Line=fgetl(pid);
        [i,no,err,next]=sscanf(Line,'%i,');
        Line=Line(next:length(Line));
        pings=strfind(Line,'"');
        if isempty(pings)
            descr=deblank(deblank(Line')');
        else  % Remove quatations from names
            descr=Line(pings(1)+1:pings(2)-1);
        end
        RoiDescription{Counter}=descr;
        Counter=Counter+1;
    end
    fclose(pid);
end
